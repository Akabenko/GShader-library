
local shaderName = "GshaderBumps"

--[[
TODO:

WorldVertexTransition 		https://developer.valvesoftware.com/wiki/WorldVertexTransition
bumpmap 
bumpmap2

Lightmapped_4WayBlend 		https://developer.valvesoftware.com/wiki/Lightmapped_4WayBlend
bumpmap
bumpmap2
]]

local bump_ref = Material("bumps/bump")

local shader_mat = bump_ref:GetShader()
local shader_keyvalues = bump_ref:GetKeyValues()
shader_keyvalues["$flags_defined"] = nil
shader_keyvalues["$flags_defined2"] = nil
shader_keyvalues["$flags"] = nil
shader_keyvalues["$flags2"] = nil

local bump_ref_alphatest = Material("bumps/bump_alphatest")
local shader_alphatest_keyvalues = bump_ref_alphatest:GetKeyValues()
shader_alphatest_keyvalues["$flags_defined"] = nil
shader_alphatest_keyvalues["$flags_defined2"] = nil
shader_alphatest_keyvalues["$flags"] = nil
shader_alphatest_keyvalues["$flags2"] = nil

local bump_ref_ssbump = Material("bumps/bump_ssbump")
local shader_ssbump_keyvalues = bump_ref_ssbump:GetKeyValues()
shader_ssbump_keyvalues["$flags_defined"] = nil
shader_ssbump_keyvalues["$flags_defined2"] = nil
shader_ssbump_keyvalues["$flags"] = nil
shader_ssbump_keyvalues["$flags2"] = nil

local cachedMaterials = {}

local function getMaterial(name)
	cachedMaterials[name] = cachedMaterials[name] or Material(name)
	return cachedMaterials[name]
end

local function createMaterial(materialPath,shader,keyvalues)
	cachedMaterials[materialPath] = cachedMaterials[materialPath] or CreateMaterial(materialPath,shader,keyvalues)
	return cachedMaterials[materialPath]
end

local function getenvmaptint(mat)
	local envmaptint = mat:GetVector("$envmaptint") or vector_origin
	envmaptint = (envmaptint.x+envmaptint.y+envmaptint.z)/3
	return envmaptint
end

local function CheckPhong(tex)
	local patch = "materials/"..tex..".vmt"
	local mat_file = file.Read( patch, "GAME" )

	local phong = false

	local orig_mat = getMaterial( tex )

	if mat_file then
		local key_values = util.KeyValuesToTable( mat_file )
		if key_values then
			phong = (key_values["$phong"] or 0) >= 1 or (!orig_mat:IsError() and getenvmaptint(orig_mat) > 0) --or getenvmaptint(orig_mat) > 0 or !orig_mat:GetTexture("$envmap"):IsError()
		end
	end

	if phong then
		local bump = orig_mat:GetTexture("$bumpmap")
		if !bump or bump:IsError() then
			phong = false
		end
	end

	return phong, orig_mat
end

local vertex_limit = math.floor(65535/3)

local function getSum(mat)
	local summ = 0

	local bump = mat:GetTexture("$bumpmap")
	if !bump or bump:IsError() then
		return summ
	end

	local envmaptint = getenvmaptint(mat)
	summ = (envmaptint ^ 2.2) * (mat:GetFloat("$phongboost") or 1)
	summ = math.Clamp(summ, 0, 1)

	return summ
end

local phys_rougness_values = {
	-- special
	["default"] = 0.85,
	["default_silent"] = 0.85,
	["floatingstandable"] = 0.3,
	["item"] = 0.4,
	["ladder"] = 0.6,
	["woodladder"] = 0.7,
	["no_decal"] = 0.5,
	["player"] = 0.3,
	["player_control_clip"] = 0.3,
	
	-- concrete/rock
	["boulder"] = 0.9,
	["brick"] = 0.8,
	["concrete"] = 0.9,
	["concrete_block"] = 0.9,
	["gravel"] = 0.95,
	["rock"] = 0.85,
	
	-- metal
	["canister"] = 0.4,
	["chain"] = 0.5,
	["chainlink"] = 0.4,
	["grenade"] = 0.3,
	["metal"] = 0.2,
	["metal_barrel"] = 0.3,
	["floating_metal_barrel"] = 0.3,
	["metal_bouncy"] = 0.2,
	["metal_box"] = 0.25,
	["metalgrate"] = 0.4,
	["metalpanel"] = 0.3,
	["metalvent"] = 0.35,
	["paintcan"] = 0.3,
	["popcan"] = 0.25,
	["roller"] = 0.4,
	["slipperymetal"] = 0.1,
	["solidmetal"] = 0.2,
	["weapon"] = 0.25,
	
	-- wood
	["wood"] = 0.6,
	["wood_box"] = 0.65,
	["wood_crate"] = 0.7,
	["wood_furniture"] = 0.5,
	["wood_lowdensity"] = 0.6,
	["wood_plank"] = 0.55,
	["wood_panel"] = 0.5,
	["wood_solid"] = 0.7,
	
	-- terrain
	["dirt"] = 0.9,
	["grass"] = 0.95,
	["mud"] = 0.98,
	["quicksand"] = 1.0,
	["sand"] = 1.0,
	["slipperyslime"] = 0.1,
	
	-- liquid
	["slime"] = 0.05,
	["water"] = 0.0,
	["wade"] = 0.0,
	
	-- frozen
	["ice"] = 0.05,
	["snow"] = 0.8,
	
	-- organic
	["alienflesh"] = 0.7,
	["armorflesh"] = 0.4,
	["bloodyflesh"] = 0.8,
	["flesh"] = 0.6,
	["foliage"] = 0.9,
	["watermelon"] = 0.7,
	
	-- manufactured
	["glass"] = 0.02,
	["glassbottle"] = 0.03,
	["tile"] = 0.1,
	["paper"] = 0.8,
	["papercup"] = 0.7,
	["cardboard"] = 0.75,
	["plaster"] = 0.6,
	["plastic_barrel"] = 0.3,
	["plastic_barrel_buoyant"] = 0.3,
	["plastic_box"] = 0.25,
	["plastic"] = 0.2,
	["rubber"] = 0.6,
	["rubbertire"] = 0.7,
	["slidingrubbertire"] = 0.65,
	["slidingrubbertire_front"] = 0.65,
	["slidingrubbertire_rear"] = 0.65,
	["jeeptire"] = 0.7,
	["brakingrubbertire"] = 0.7,
	["porcelain"] = 0.1,
	
	-- miscellaneous
	["carpet"] = 0.9,
	["ceiling_tile"] = 0.2,
	["computer"] = 0.3,
	["pottery"] = 0.4
}

local matrix_dummy = Matrix()
matrix_dummy:Identity()

local uncompleted_shaders = {
	["WorldVertexTransition"] = true;
	["Lightmapped_4WayBlend"] = true;
	["Lightmapped_4WayBlend_DX9"] = true;
	["WorldVertexTransition_DX9"] = true;
}

local function createSpecMat(tex)
	local orig_mat = getMaterial( tex )

	local orig_shader = orig_mat:GetShader()

	if uncompleted_shaders[orig_shader] then
		return false
	end

	local bump = orig_mat:GetTexture("$bumpmap")

	if !bump or bump:IsErrorTexture() then return false end

	local envmapmask = orig_mat:GetTexture("$envmapmask")
	local basecolor = orig_mat:GetTexture("$basecolor")

	local basealphaenvmapmask = (orig_mat:GetInt("$basealphaenvmapmask")) or 0 > 1
	local ssrtint = getSum(orig_mat)

	local patch = "materials/"..tex..".vmt"
	local mat_file = file.Read( patch, "GAME" )
	if !mat_file then return false end
	local key_values = util.KeyValuesToTable( mat_file )

	local name_vmt_included = key_values["include"]

	if name_vmt_included then
		local mat_file_included = file.Read( name_vmt_included, "GAME" )
		if mat_file_included then
			local key_values_included = util.KeyValuesToTable( mat_file_included )
			--table.Add( key_values, key_values_included ) -- idk but it not works
			key_values = key_values_included
		end
	end

	local mTransform

	local bumptransform = key_values["$bumptransform"]
	if bumptransform then
		mTransform = orig_mat:GetMatrix("$bumptransform")
	else
		mTransform = matrix_dummy
	end

	local surfaceprop = key_values["$surfaceprop"] or "default"
	surfaceprop = string.lower(surfaceprop)

	if ssrtint == 1 then -- default
		ssrtint = 1 - (phys_rougness_values[surfaceprop] or phys_rougness_values["default"])
	end

	local alphatest = (key_values["$alphatest"] or 0) >= 1
	local ssbump = (key_values["$ssbump"] or 0) >= 1 -- or (key_values["$ssbumpmathfix"] or 0) >= 1

	local cur_keyvalues = {}

	if ssbump then
		cur_keyvalues = shader_ssbump_keyvalues
	elseif alphatest then
		cur_keyvalues = shader_alphatest_keyvalues
	else
		cur_keyvalues = shader_keyvalues
	end
	
	local mat = createMaterial(orig_mat:GetName().."_ssr", shader_mat, cur_keyvalues )

	mat:SetMatrix("$VIEWPROJMAT", mTransform)
	
	if envmapmask and !envmapmask:IsError() then
		mat:SetTexture("$texture2", envmapmask)
		mat:SetFloat("$c1_z", 2 )
	elseif basealphaenvmapmask and basecolor and !basecolor:IsError() then
		mat:SetTexture("$basetexture", basecolor)
		mat:SetFloat("$c1_z", 1 )
	end

	-- нужно добавить поддержку basetexture transform

	mat:SetTexture("$texture1", bump)
	--mat:SetFloat("$flags2", 130)
	--mat:SetFloat("$flags", 65536) -- decal

	mat:SetFloat("$c1_x", ssrtint)

	mat:SetFloat("$c0_z", key_values["$alphatestreference"] or 0.5)

	return mat
end

local function tableAdd(dest, source)
	for i = 1, #source do
		dest[#dest + 1] = source[i]
	end
	return dest
end

--MESHES = MESHES or {}
--MATS = MATS or {}
local MESHES = {}
local MATS = {}

local blacklist_mat = {
	["tools/toolsskybox"] = true,
}

local function BuildMeshes(includeDisplacment)
	local faces = NikNaks.CurrentMap:GetFaces(includeDisplacment)
	local mats_vertexes = {}

	for i = 1, #faces do
		local face = faces[i]

		if face:HasTexInfoFlag(0x08) then continue end
		if face:GetEntity().classname != "worldspawn" then continue end
		if face:IsSkyBox() then continue end
		if face:IsSkyBox3D() then continue end
		--if face:IsDisplacement() then continue end
		/* убираем нахуй диспы из SSR, тк их математика
		не идентична парсингу ( тем более бленд не работает ) */
		
		local disp = face:IsDisplacement()

		local tex = string.lower( face:GetTexData().nameStringTableID )

		if blacklist_mat[tex] then continue end

		local phong, orig_mat = CheckPhong(tex)
		local ssrtint = getSum(orig_mat)

		--if phong or ssrtint > 0 then
			local triangles = face:GenerateVertexTriangleData()

			if !mats_vertexes[tex] then mats_vertexes[tex] = {} end

			local index = #mats_vertexes[tex]

			if !mats_vertexes[tex][index] then mats_vertexes[tex][index] = {} end

			if #triangles + #mats_vertexes[tex][index] > vertex_limit then
				index = index + 1
			end

			if !mats_vertexes[tex][index] then mats_vertexes[tex][index] = {} end

			tableAdd(mats_vertexes[tex][index], triangles)
		--end
	end

	local meshes = {}
	local mats = {}

	-- диспы нужно в отдельную таблицу. чтобы им выставить другой bias
	for tex,v in pairs(mats_vertexes) do
		for index, vertexes in pairs(v) do
			local mat = createSpecMat(tex)
			if !mat then continue end
			local _mesh = Mesh()
			_mesh:BuildFromTriangles(vertexes)
			local i = #meshes + 1
			mats[i] = mat
			meshes[i] = _mesh
		end
	end

	BUILDED_MESHES = true

	return meshes, mats
end

local includeDisplacment = false

hook.Add("InitPostEntity", shaderName, function()
	timer.Simple(1, function()
		MESHES, MATS = BuildMeshes(includeDisplacment)
	end)
end)

hook.Add("ActivateGShaderBumps", shaderName, function()
	hook.Add("PostDrawTranslucentRenderables", shaderName, function(viewSetup) 
		local viewSetup = render.GetViewSetup()
		if !shaderlib.CanDrawEffects(viewSetup) then return end
		local old_viewSetup = table.Copy(viewSetup) -- wtf
		viewSetup.znear = viewSetup.znear + 0.005 -- bias 0.005
		
		cam.Start(viewSetup)
		render.PushRenderTarget(shaderlib.rt_Bump)
			render.Clear(0,0,0,0)

			render.OverrideDepthEnable(true,true)

			for i = 1, #MESHES do
				
				render.SetMaterial(MATS[i])
				local _mesh = MESHES[i]
				_mesh:Draw(STUDIO_RENDER + STUDIO_NOSHADOWS)
			end

			render.OverrideDepthEnable(false,false)
		render.PopRenderTarget()
		cam.End()
	end)
end)
