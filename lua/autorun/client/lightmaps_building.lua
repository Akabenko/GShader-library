
-- https://github.com/Facepunch/garrysmod-requests/issues/3251

local shaderName = "LightmapBuilding"
local hdr = render.GetHDREnabled()

local MODE_SESSION = 0
local MODE_TEXINFO = 1
local MODE_TEXDATA = 2

local MATORDER = MODE_SESSION

local MODE_LUMP_AUTO 	= 0
local MODE_LUMP_LDR 	= 1
local MODE_LUMP_HDR 	= 2

local FACELUMP = MODE_LUMP_AUTO

shaderlib = shaderlib or {}
shaderlib.rt_Lightmaps = GetRenderTargetEx("_rt_Lightmaps", 1, 1,
	RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_SHARED,
	bit.bor(4, 8, 16, 256, 512),
	hdr and CREATERENDERTARGETFLAGS_HDR or 0,
	hdr and IMAGE_FORMAT_RGBA16161616 or IMAGE_FORMAT_RGB888
	--IMAGE_FORMAT_RGB888
)

-- bsp parser
local BSP = {}

local s_byte, s_sub = string.byte, string.sub
local RD = {}
RD.__index = RD
local function NewReader(d) return setmetatable({ d = d or "", p = 1 }, RD) end
function RD:Byte() local v = s_byte(self.d, self.p) or 0; self.p = self.p + 1; return v end
function RD:U16() local a, b = s_byte(self.d, self.p, self.p + 1); self.p = self.p + 2; return (a or 0) + (b or 0) * 256 end
function RD:U32() local a, b, c, d = s_byte(self.d, self.p, self.p + 3); self.p = self.p + 4; return (a or 0) + (b or 0) * 256 + (c or 0) * 65536 + (d or 0) * 16777216 end
function RD:S16() local v = self:U16(); return v >= 32768 and v - 65536 or v end
function RD:S32() local v = self:U32(); return v >= 2147483648 and v - 4294967296 or v end
function RD:Float()
	local b1, b2, b3, b4 = s_byte(self.d, self.p, self.p + 3); self.p = self.p + 4
	b1, b2, b3, b4 = b1 or 0, b2 or 0, b3 or 0, b4 or 0
	local sign = b4 >= 128 and -1 or 1
	local exp = (b4 % 128) * 2 + math.floor(b3 / 128)
	local mant = (b3 % 128) * 65536 + b2 * 256 + b1
	if exp == 255 then return mant == 0 and sign * math.huge or 0 / 0 end
	if exp == 0 then return sign * mant * 2 ^ -149 end
	return sign * (1 + mant / 8388608) * 2 ^ (exp - 127)
end
function RD:Vec() return Vector(self:Float(), self:Float(), self:Float()) end
function RD:Skip(n) self.p = self.p + n end
function RD:Seek(o) self.p = o + 1 end        -- offset
function RD:Len() return #self.d end

local function LZMADecompress(raw)
	local actual = (s_byte(raw, 5) or 0) + (s_byte(raw, 6) or 0) * 256 + (s_byte(raw, 7) or 0) * 65536 + (s_byte(raw, 8) or 0) * 16777216
	if actual <= 0 then return nil, 0 end
	local dec = util.Decompress(raw)
	if dec and #dec == actual then return dec, actual end
	local props  = s_sub(raw, 13, 17)
	local stream = s_sub(raw, 18)
	local size8  = string.char(
		actual % 256, math.floor(actual / 256) % 256,
		math.floor(actual / 65536) % 256, math.floor(actual / 16777216) % 256,
		0, 0, 0, 0)
	dec = util.Decompress(props .. size8 .. stream)
	if dec and #dec == actual then return dec, actual end
	return dec, actual -- can be nil
end

local function ParseBSP()
	local f = file.Open("maps/" .. game.GetMap() .. ".bsp", "rb", "GAME")
	if not f then return false end
	if f:Read(4) ~= "VBSP" then f:Close() return false end
	BSP.version = f:ReadLong()

	-- MINBSPVERSION(19)..BSPVERSION(20 Gmod / 21 CS:GO).
	if BSP.version < 19 or BSP.version > 21 then
		f:Close() return false
	end
	local lumps = {}
	for i = 0, 63 do lumps[i] = { ofs = f:ReadLong(), len = f:ReadLong(), ver = f:ReadLong(), usz = f:ReadLong() } end

	-- CMapLoadHelper
	local function open(id)
		local L = lumps[id]
		if not L or L.len <= 0 then return NewReader("") end
		f:Seek(L.ofs)
		local raw = f:Read(L.len) or ""

		-- CS:GO LZMA
		if s_byte(raw, 1) == 76 and s_byte(raw, 2) == 90 and s_byte(raw, 3) == 77 and s_byte(raw, 4) == 65 then
			local dec, actual = LZMADecompress(raw)
			if dec and #dec == actual then
				raw = dec
			else

				if dec then raw = dec end
			end
		end
		return NewReader(raw)
	end

	local r = open(3)
	local n = r:Len() / 12
	BSP.verts = {}
	for i = 0, n - 1 do BSP.verts[i] = r:Vec() end

	r = open(1)
	n = r:Len() / 20
	BSP.planes = {}
	for i = 0, n - 1 do BSP.planes[i] = { normal = r:Vec(), dist = r:Float(), type = r:S32() } end

	r = open(12)
	n = r:Len() / 4
	BSP.edges = {}
	for i = 0, n - 1 do BSP.edges[i] = { BSP.verts[r:U16()], BSP.verts[r:U16()] } end

	r = open(13)
	n = r:Len() / 4
	BSP.surfedges = {}
	for i = 0, n - 1 do BSP.surfedges[i] = r:S32() end

	r = open(6)
	n = r:Len() / 72
	BSP.texinfos = {}
	for i = 0, n - 1 do
		local ti = { lv = {} }
		r:Skip(32) -- textureVecs пропускаем
		ti.lv[0] = { [0] = r:Float(), r:Float(), r:Float(), r:Float() }
		ti.lv[1] = { [0] = r:Float(), r:Float(), r:Float(), r:Float() }
		ti.flags = r:S32(); ti.texdata = r:S32()
		BSP.texinfos[i] = ti
	end

	-- string data/table → имена texdata (для порядка интернирования)
	local sd = open(43).d
	local rst = open(44)
	local st = {}
	for i = 0, rst:Len() / 4 - 1 do st[i] = rst:S32() end
	local function nameByID(id)
		local off = st[id]; if not off then return "" end
		local e = string.find(sd, "\0", off + 1, true)
		return e and s_sub(sd, off + 1, e - 1) or s_sub(sd, off + 1)
	end

	r = open(2)
	n = r:Len() / 32
	BSP.texdatas = {}
	for i = 0, n - 1 do
		r:Skip(12) -- reflectivity
		local nid = r:S32()
		r:Skip(16) -- width/height/view_w/view_h
		BSP.texdatas[i] = { name = string.lower(nameByID(nid)) }
	end

	if FACELUMP == MODE_LUMP_LDR then BSP.faceLump = 7
	elseif FACELUMP == MODE_LUMP_HDR then BSP.faceLump = (lumps[58].len > 0) and 58 or 7
	else BSP.faceLump = (hdr and lumps[58].len > 0) and 58 or 7 end
	r = open(BSP.faceLump)
	n = r:Len() / 56
	BSP.faces = {}
	for i = 0, n - 1 do
		local fc = {}
		fc.planenum = r:U16(); fc.side = r:Byte(); fc.onNode = r:Byte()
		fc.firstedge = r:S32(); fc.numedges = r:S16()
		fc.texinfo = r:S16(); fc.dispinfo = r:S16(); fc.surfaceFogVolumeID = r:S16()
		fc.styles = { r:Byte(), r:Byte(), r:Byte(), r:Byte() }
		fc.lightofs = r:S32(); fc.area = r:Float()
		fc.lmMins = { r:S32(), r:S32() }
		fc.lmSize = { r:S32(), r:S32() }
		fc.origFace = r:S32()
		fc.numPrims = r:U16(); fc.firstPrimID = r:U16(); fc.smoothingGroups = r:U32()
		fc.__id = i
		BSP.faces[i] = fc
	end

	r = open(33)
	BSP.dispverts = {}
	for i = 0, r:Len() / 20 - 1 do BSP.dispverts[i] = { vec = r:Vec(), dist = r:Float(), alpha = r:Float() } end

	r = open(26)
	BSP.dispByFace = {}
	for i = 0, math.floor(r:Len() / 176) - 1 do
		r:Seek(i * 176)
		local d = {}
		d.startPosition = r:Vec()
		d.DispVertStart = r:S32(); r:S32(); d.power = r:S32()
		r:Seek(i * 176 + 36); d.MapFace = r:U16()
		BSP.dispByFace[d.MapFace] = d
	end
	f:Close()

	return true
end

local function SurfEdgeVert(idx)
	local s = BSP.surfedges[idx]
	local e = BSP.edges[math.abs(s)]
	if s >= 0 then return e[1] else return e[2] end
end
local function FaceNormal(fc)
	local p = BSP.planes[fc.planenum]
	if not p then return Vector(0, 0, 1) end
	return fc.side ~= 0 and -p.normal or p.normal
end
local function FaceMat(fc)
	local ti = BSP.texinfos[fc.texinfo]
	if not ti then return "" end
	local td = BSP.texdatas[ti.texdata]
	return td and td.name or ""
end

local function ClearLightmaps()
	if shaderlib.LM_meshes then
		for i = 1, #shaderlib.LM_meshes do
			local mesh = shaderlib.LM_meshes[i]
			if mesh and mesh.Destroy then mesh:Destroy() end
		end
	end
	shaderlib.LM_meshes = nil
	shaderlib.L_MATS = nil
	shaderlib.LM_map = nil
end

local function Build()
	local map = game.GetMap()
	if shaderlib.LM_meshes and shaderlib.LM_map == map then return end
	ClearLightmaps()

	shaderlib.LM_meshes = {}
	shaderlib.LM_map = map

	if not ParseBSP() then return end

	shaderlib.LM_symOrder = nil
	shaderlib.LM_symSeq = nil

	-- get [lightmap N] (one probe mat — avoid appending lm_probe_* into m_MaterialDict)
	local plm = {}
	do
		local probe = CreateMaterial("lm_probe_shared", "UnlitGeneric", {})
		local i = 0
		while true do
			local nm = "[lightmap " .. i .. "]"
			probe:SetTexture("$basetexture", nm)
			local t = probe:GetTexture("$basetexture")
			if not t or t:IsErrorTexture() then break end
			plm[i] = t; i = i + 1
		end
	end

	local CImagePacker = {}
	CImagePacker.__index = CImagePacker
	function CImagePacker.New(maxW, maxH)
		local o = setmetatable({}, CImagePacker)
		o.maxW = maxW; o.maxH = maxH; o.blockW = maxW + 1; o.blockH = maxH + 1; o.minH = -1; o.wave = {}
		for i = 0, maxW - 1 do o.wave[i] = -1 end
		return o
	end
	function CImagePacker:MaxYIndex(fx, w)
		local maxY, idx = -1, 0
		for x = fx, fx + w - 1 do if self.wave[x] >= maxY then maxY = self.wave[x]; idx = x end end
		return idx
	end
	function CImagePacker:AddBlock(w, h)
		if w >= self.blockW and h >= self.blockH then return false end
		local bestX, outerX, outerMinY, lastX, lastMax = -1, 0, self.maxH, self.maxW - w, -2
		while outerX <= lastX do
			if self.wave[outerX] == lastMax then outerX = outerX + 1; continue end
			local idx = self:MaxYIndex(outerX, w)
			lastMax = self.wave[idx]
			if outerMinY > lastMax then outerMinY = lastMax; bestX = outerX end
			outerX = idx + 1
		end
		if bestX == -1 then if w <= self.blockW and h <= self.blockH then self.blockW = w; self.blockH = h end return false end
		local rY = outerMinY + 1
		if rY + h >= self.maxH - 1 then if w <= self.blockW and h <= self.blockH then self.blockW = w; self.blockH = h end return false end
		if rY + h > self.minH then self.minH = rY + h end
		for x = bestX, bestX + w - 1 do self.wave[x] = outerMinY + h end
		return true, bestX, rY
	end
	local function nextPow2(x) local p = 1 while p < x do p = p * 2 end return p end

	-- pack UV faceOffset / facePage / pageH
	local PAGE_W, PAGE_H = 512, 256
	local SURF_NOLIGHT, SURF_BUMPLIGHT = 0x400, 0x800
	local SURF_SKIP_MASK = 0x40 + 0x10 --bit.bor(0x40, 0x10)
	local faceOffset, facePage, pageH = {}, {}, {}
	local g_numPages = 0

	local matOrder = {}
	do
		local function orderFromTexLump()
			local k = 0
			if MATORDER == MODE_TEXINFO then
				for i = 0, #BSP.texinfos do
					local ti = BSP.texinfos[i]
					local td = ti and BSP.texdatas[ti.texdata]
					local nm = td and td.name
					if nm and nm ~= "" and matOrder[nm] == nil then matOrder[nm] = k; k = k + 1 end
				end
			else -- either MODE_SESSION or MODE_TEXDATA
				for i = 0, #BSP.texdatas do
					local td = BSP.texdatas[i]
					if td and td.name ~= "" and matOrder[td.name] == nil then matOrder[td.name] = k; k = k + 1 end
				end
			end
		end

		local enumFn
		for i = 0, #BSP.texdatas do
			local nm = BSP.texdatas[i] and BSP.texdatas[i].name
			if not nm or nm == "" then continue end
			local m = Material(nm)
			if m and not m:IsError() then
				enumFn = (m.GetEnumerationID and "GetEnumerationID") or (m.GetID and "GetID") or nil
				print(enumFn)
				break
			end
		end

		if enumFn then
			for i = 0, #BSP.texdatas do
				local nm = BSP.texdatas[i] and BSP.texdatas[i].name
				if not nm or nm == "" or matOrder[nm] ~= nil then continue end
				local m = Material(nm)
				matOrder[nm] = (m and not m:IsError() and m[enumFn](m)) or math.huge
				print(matOrder[nm])
			end
		else
			orderFromTexLump()
		end
	end

	local function hasLS(fc)
		if fc.lightofs == -1 then return false end
		return (fc.styles[1] ~= 0 and fc.styles[1] ~= 255) or (fc.styles[2] ~= 255)
	end

	-- different offset by bumpmap
	local bumpCache = {}
	local function MatNeedsBump(name)
		local c = bumpCache[name]; if c ~= nil then return c end
		local res = false
		local m = name ~= "" and Material(name)
		if m and not m:IsError() then
			local sh = (m:GetShader() or ""):lower()
			local isLM = sh:find("lightmapped", 1, true) or sh:find("worldvertextransition", 1, true)
				or sh:find("worldtwotextureblend", 1, true) or sh:find("water", 1, true)
			if isLM then
				local bump = m:GetString("$bumpmap") or m:GetString("$normalmap")
				local noDiff = m:GetInt("$nodiffusebumplighting")
				if bump and bump ~= "" and (noDiff == nil or noDiff == 0) then res = true end
			end

			res = bit.band(m:GetInt("$flags2"), 8) != 0
		end
		bumpCache[name] = res
		return res
	end

	local function PackAll()
		local list = {}
		for i = 0, #BSP.faces do
			local fc = BSP.faces[i]
			if not fc then continue end
			local ti = BSP.texinfos[fc.texinfo]
			if not ti then continue end
			if bit.band(ti.flags, SURF_NOLIGHT) ~= 0 then continue end
			if (fc.lmSize[1] == 0 or fc.lmSize[2] == 0) and fc.lightofs == -1 then continue end
			list[#list + 1] = fc
		end

		table.sort(list, function(a, b)
			local ae = matOrder[FaceMat(a)] or math.huge
			local be = matOrder[FaceMat(b)] or math.huge
			if ae ~= be then return ae < be end
			local al, bl = hasLS(a), hasLS(b)
			if al ~= bl then return not al end
			local aa = a.lmSize[1] * a.lmSize[2]
			local bb = b.lmSize[1] * b.lmSize[2]
			if aa ~= bb then return aa > bb end
			return a.__id < b.__id
		end)

		local packers = { [0] = CImagePacker.New(PAGE_W, PAGE_H) }
		local cur, activeMin, curMat, bumpN = 0, 0, nil, 0
		for _, fc in ipairs(list) do
			local w, h = fc.lmSize[1] + 1, fc.lmSize[2] + 1
			local mat = FaceMat(fc)
			local ti = BSP.texinfos[fc.texinfo]
			-- x4 for bumped
			local nb = MatNeedsBump(mat); if nb then bumpN = bumpN + 1 end
			local packW = nb and (w * 4) or w
			if mat ~= curMat then
				if curMat ~= nil then activeMin = cur end
				curMat = mat
			end
			local ok, x, y, found
			for pi = activeMin, cur do ok, x, y = packers[pi]:AddBlock(packW, h) if ok then found = pi; break end end
			if not ok then
				pageH[cur] = PAGE_H
				cur = cur + 1; packers[cur] = CImagePacker.New(PAGE_W, PAGE_H)
				ok, x, y = packers[cur]:AddBlock(packW, h); found = cur
			end
			if ok then faceOffset[fc] = { x, y }; facePage[fc] = found end
		end
		local _, mh = packers[cur].maxW, packers[cur].minH
		pageH[cur] = nextPow2(math.max(packers[cur].minH, 1))
		g_numPages = cur + 1
	end

	PackAll()

	-- atlas lightmap uv: (luxel + 0.5 + offset) / pageSize
	local function FaceUV(fc, v)
		local ti = BSP.texinfos[fc.texinfo]
		local lv = ti.lv
		local m = fc.lmMins
		local off = faceOffset[fc]
		local ox, oy = off[1], off[2]
		local PH = pageH[facePage[fc]] or PAGE_H
		local s = lv[0][0] * v.x + lv[0][1] * v.y + lv[0][2] * v.z + lv[0][3] - m[1] + 0.5
		local t = lv[1][0] * v.x + lv[1][1] * v.y + lv[1][2] * v.z + lv[1][3] - m[2] + 0.5
		return (s + ox) / PAGE_W, (t + oy) / PH
	end

	-- meshes and sampling of lightmap page
	local function PolyChop(o) local v, n = {}, 1 for i = 1, #o - 2 do v[n] = o[1]; v[n + 1] = o[i + 1]; v[n + 2] = o[i + 2]; n = n + 3 end return v end
	local function GridChop(grid)
		local W = math.sqrt(#grid); local H = #grid / W
		local tri, n = {}, 0
		for i = 1, H - 1 do for j = 1, W - 1 do
			local i1 = (i - 1) * W + j local i2 = i * W + j local i3 = i * W + j + 1 local i4 = (i - 1) * W + j + 1
			if (i + j) % 2 == 0 then
				n=n+1;tri[n]=grid[i1] n=n+1;tri[n]=grid[i2] n=n+1;tri[n]=grid[i3]
				n=n+1;tri[n]=grid[i1] n=n+1;tri[n]=grid[i3] n=n+1;tri[n]=grid[i4]
			else
				n=n+1;tri[n]=grid[i1] n=n+1;tri[n]=grid[i2] n=n+1;tri[n]=grid[i4]
				n=n+1;tri[n]=grid[i2] n=n+1;tri[n]=grid[i3] n=n+1;tri[n]=grid[i4]
			end
		end end
		return tri
	end
	local up = Vector(0, 0, 1)

	local function FaceVerts(fc)
		local n = FaceNormal(fc)
		local tan = n:Cross(up):Cross(n):GetNormalized()
		local ud = { tan.x, tan.y, tan.z, 0 }
		local t = {}
		for i = 0, fc.numedges - 1 do
			local a = SurfEdgeVert(fc.firstedge + i)
			local u, v = FaceUV(fc, a)
			t[i + 1] = { pos = a, normal = n, u = u, v = v, u1 = u, v1 = v, userdata = ud }
		end
		return t
	end

	local function DispTris(fc, base)
		local di = BSP.dispByFace[fc.__id]
		if not di or #base ~= 4 then return PolyChop(base) end
		local start = di.startPosition
		local startIdx, minD, quad = 1, math.huge, {}
		for i = 1, 4 do quad[i] = base[i].pos local d = quad[i]:Distance(start) if d < minD then minD = d; startIdx = i end end
		local function rot(q) local p = {} for i = startIdx, #q do p[#p + 1] = q[i] end for i = 1, startIdx - 1 do p[#p + 1] = q[i] end return p end
		local A, B, C, D = unpack(rot(quad))
		local AD, BC = D - A, C - B
		local off = faceOffset[fc]; local ox, oy = off[1], off[2]
		local PH = pageH[facePage[fc]] or PAGE_H
		local W, H = fc.lmSize[1], fc.lmSize[2]
		local function cLM(s, t) return Vector((s + 0.5 + ox) / PAGE_W, (t + 0.5 + oy) / PH, 0) end
		local lmA, lmB, lmC, lmD = cLM(0, 0), cLM(0, H), cLM(W, H), cLM(W, 0)
		local lmAD, lmBC = lmD - lmA, lmC - lmB
		local power2 = 2 ^ di.power
		local vs = di.DispVertStart
		local n = base[1].normal local ud = base[1].userdata local LerpV = LerpVector
		local grid, idx = {}, 0
		for vi = vs, vs + (power2 + 1) ^ 2 - 1 do
			local dv = BSP.dispverts[vi]; if not dv then break end
			local t1 = (idx % (power2 + 1)) / power2
			local t2 = math.floor(idx / (power2 + 1)) / power2
			local pos = LerpV(t2, A + AD * t1, B + BC * t1) + dv.vec * dv.dist
			local luv = LerpV(t2, lmA + lmAD * t1, lmB + lmBC * t1)
			grid[idx + 1] = { pos = pos, normal = n, u = luv.x, v = luv.y, u1 = luv.x, v1 = luv.y, userdata = ud }
			idx = idx + 1
		end
		return GridChop(grid)
	end

	local VLIMIT = math.floor(65535 / 3)

	shaderlib.L_MATS = {}
	shaderlib.LM_meshes = {}

	local g_dbg = 0
	local function BuildMeshes()
		local byPage = {}
		for fc, p in pairs(facePage) do
			local ti = BSP.texinfos[fc.texinfo]
			if ti and bit.band(ti.flags, SURF_SKIP_MASK) ~= 0 then continue end
			local base = FaceVerts(fc)
			local tris = fc.dispinfo > -1 and DispTris(fc, base) or PolyChop(base)
			if g_dbg < 8 and tris and #tris >= 3 then
				g_dbg = g_dbg + 1
				local o = faceOffset[fc]
				local v1 = tris[1]
			end
			if tris and #tris >= 3 then
				byPage[p] = byPage[p] or { {} }
				local b = byPage[p]; local last = b[#b]
				if #last + #tris > VLIMIT then b[#b + 1] = {}; last = b[#b] end
				for k = 1, #tris do last[#last + 1] = tris[k] end
			end
		end
		for p, buckets in pairs(byPage) do
			local m = CreateMaterial("lm_page_" .. p, "UnlitGeneric", {
				["$basetexture"] = "color/white",
				["$nolod"]       = "1",
				["$vertexcolor"] = "0",
				["$vertexalpha"] = "0",
				["$nocull"]      = "1",
				["$znearer"] 	= "1",
				["$decal"] 		= "1",
			})
			if plm[p] then m:SetTexture("$basetexture", plm[p]) end
			for _, verts in ipairs(buckets) do
				local mesh = Mesh(m); mesh:BuildFromTriangles(verts)
				shaderlib.L_MATS[#shaderlib.L_MATS + 1] = m
				shaderlib.LM_meshes[#shaderlib.LM_meshes + 1] = mesh
			end
		end
	end

	BuildMeshes()
end

local function EnableLightmaps()
	hook.Add("PreDrawEffects", shaderName, function()
		local viewSetup = render.GetViewSetup()
		if shaderlib.CanDrawEffects and not shaderlib.CanDrawEffects(viewSetup) then return end
		viewSetup.znear = viewSetup.znear + 0.01
		viewSetup.zfar = viewSetup.zfar + 10

		cam.Start(viewSetup)
		render.PushRenderTarget(shaderlib.rt_Lightmaps)
		render.Clear(0,0,0,0)
		render.OverrideDepthEnable(true, true)

		for i = 1, #shaderlib.LM_meshes do
			render.SetMaterial(shaderlib.L_MATS[i])
			shaderlib.LM_meshes[i]:Draw()
		end

		render.OverrideDepthEnable(false, false)
		render.PopRenderTarget()
		cam.End()

		hook.Run("PostDrawLightmaps")
	end)
end

local function InitLightmaps()
	if not shaderlib.LM_cvarHooked then
		shaderlib.LM_cvarHooked = true
		cvars.AddChangeCallback("r_shaderlib_lightmaps", function(_, _, value_new)
			local state = value_new == "1"
			if not state then
				hook.Remove("PreDrawEffects", shaderName)
			else
				Build()
				EnableLightmaps()
			end
		end, shaderName)
	end

	if not GetConVar("r_shaderlib_lightmaps"):GetBool() then return end

	timer.Create(shaderName .. "_build", 1, 1, function()
		Build()
		EnableLightmaps()
	end)
end

hook.Add("ShutDown", shaderName, ClearLightmaps)
hook.Add("InitPostEntity", shaderName, function()
	shaderlib.LM_initialized = true
	if shaderlib.LM_map and shaderlib.LM_map ~= game.GetMap() then
		ClearLightmaps()
	end
	InitLightmaps()
end)

if shaderlib.LM_initialized or IsValid(LocalPlayer()) then InitLightmaps() end
