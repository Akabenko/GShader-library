if !CLIENT then return end
/*---------------------------------------------------------------------------
GShaderlib authors: Meetric, Akabenko
---------------------------------------------------------------------------*/

MATERIAL_FOG_MODE = 0 -- https://github.com/Facepunch/garrysmod-issues/issues/6791

GSHADER = true
DGVOODOO 	= file.Exists("dgVoodoo.conf", "EXECUTABLE_PATH")
local vulkan_pattern = "10DxvkDeviceEEEEUlPNS"
local reshade_pattern = "reshade"
local f = file.Read("d3d9.dll", "EXECUTABLE_PATH") or ""
DXVK = !!string.find(f, vulkan_pattern, 1, true)
RESHADE = !!string.find(f, reshade_pattern, 1, true)

if DXVK then
	local function GetDXVKVersion()
	    local marker = "\0DXVK: \0"
	    local pos = string.find(f, marker, 1, true)
	    if not pos then return nil end
	    
	    local startPos = pos + #marker
	    local endPos = string.find(f, "\0", startPos, true)
	    if not endPos then return nil end
	    
	    local raw = string.sub(f, startPos, endPos - 1)
	    raw = string.Trim(raw)
	    
	    if string.StartWith(raw, "v") then
	        raw = string.sub(raw, 2)
	    end
	    
	    local clean = string.match(raw, "^(%d+%.%d+%.?%d*)")
	    
	    return clean or raw
	end
	
	DXVK_VERSION = GetDXVKVersion()
end

TEXFILTER.PYRAMIDALQUAD 	= 6
TEXFILTER.GAUSSIANQUAD 		= 7
-- TEXFILTER.CONVOLUTIONMONO 	= 8 			-- D3D9Ex only -- for D3DFMT_A1 (invalid D3D9 legacy format)

CREATERENDERTARGETFLAGS_NOEDRAM = 8

IMAGE_FORMAT_I8 					=	5
IMAGE_FORMAT_IA88 					=	6
IMAGE_FORMAT_P8 					=	7
IMAGE_FORMAT_A8 					=	8
IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	9
IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	10
IMAGE_FORMAT_DXT1 					=	13
IMAGE_FORMAT_DXT3 					=	14
IMAGE_FORMAT_DXT5 					=	15
IMAGE_FORMAT_BGRX8888 				=	16
IMAGE_FORMAT_BGR565 				=	17
IMAGE_FORMAT_BGRX5551 				=	18
IMAGE_FORMAT_BGRA4444 				=	19
IMAGE_FORMAT_DXT1_ONEBITALPHA 		=	20
IMAGE_FORMAT_BGRA5551 				=	21
IMAGE_FORMAT_UV88 					=	22
IMAGE_FORMAT_UVWQ8888 				=	23
IMAGE_FORMAT_UVLX8888 				=	26
IMAGE_FORMAT_R32F 					=	27	-- Single-channel 32-bit floating point. Good choise for colored depth buffer.
IMAGE_FORMAT_RGB323232F 			=	28  -- NOTE: D3D9 does not have this format
IMAGE_FORMAT_RGBA32323232F 			=	29

if BRANCH == "x86-64" then -- CS:GO ids
	IMAGE_FORMAT_RG1616F 				= 	30
	IMAGE_FORMAT_RG3232F 				= 	31 

	IMAGE_FORMAT_RGBX8888 				= 	32

	IMAGE_FORMAT_NV_NULL 				= 	33 -- Dummy format which takes no video memory.

	IMAGE_FORMAT_ATI1N 					= 	34 	-- Two-surface ATI1N format
	IMAGE_FORMAT_ATI2N 					= 	35 	-- One-surface ATI2N / DXN format

	IMAGE_FORMAT_RGBA1010102 			= 	36 	-- 10 bit-per component render targets
	IMAGE_FORMAT_BGRA1010102 			= 	37
	IMAGE_FORMAT_R16F 					= 	38 	-- 16 bit FP format

	IMAGE_FORMAT_D16 					= 	39
	IMAGE_FORMAT_D15S1 					= 	40
	IMAGE_FORMAT_D32 					= 	41
	IMAGE_FORMAT_D24S8 					= 	42
	IMAGE_FORMAT_LINEAR_D24S8 			= 	43
	IMAGE_FORMAT_D24X8 					= 	44
	IMAGE_FORMAT_D24X4S4 				= 	45
	IMAGE_FORMAT_D24FS8 				= 	46
	IMAGE_FORMAT_D16_SHADOW 			= 	47
	IMAGE_FORMAT_D24X8_SHADOW 			= 	48

	-- supporting these specific formats as non-tiled for procedural cpu access
	IMAGE_FORMAT_LINEAR_BGRX888 		= 	49
	IMAGE_FORMAT_LINEAR_RGBA8888 		= 	50
	IMAGE_FORMAT_LINEAR_ABGR8888 		= 	51
	IMAGE_FORMAT_LINEAR_ARGB8888 		= 	52
	IMAGE_FORMAT_LINEAR_BGRA8888 		= 	53
	IMAGE_FORMAT_LINEAR_RGB888 			= 	54
	IMAGE_FORMAT_LINEAR_BGR888 			= 	55
	IMAGE_FORMAT_LINEAR_BGRX5551 		= 	56
	IMAGE_FORMAT_LINEAR_I8 				= 	57
	IMAGE_FORMAT_LINEAR_RGBA16161616 	= 	58
	IMAGE_FORMAT_LINEAR_A8 				= 	59
	IMAGE_FORMAT_LINEAR_DXT1 			= 	60
	IMAGE_FORMAT_LINEAR_DXT3 			= 	61
	IMAGE_FORMAT_LINEAR_DXT5 			= 	62

	IMAGE_FORMAT_LE_BGRX8888 			= 	63
	IMAGE_FORMAT_LE_BGRA8888 			= 	64

	IMAGE_FORMAT_DXT1_RUNTIME 			= 	65
	IMAGE_FORMAT_DXT5_RUNTIME 			= 	66
	
	IMAGE_FORMAT_INTZ 					= 	67
else -- TF2 values
	IMAGE_FORMAT_NV_DST16 				= 	30
	IMAGE_FORMAT_NV_DST24 				= 	31

	IMAGE_FORMAT_NV_INTZ 				= 	32
	IMAGE_FORMAT_NV_RAWZ 				= 	33

	IMAGE_FORMAT_ATI_DST16 				= 	34
	IMAGE_FORMAT_ATI_DST24 				= 	35

	IMAGE_FORMAT_NV_NULL 				= 	36

	IMAGE_FORMAT_ATI1N 					= 	37
	IMAGE_FORMAT_ATI2N 					= 	38
end

VENDORID_NVIDIA = 0x10DE
VENDORID_ATI 	= 0x1002
VENDORID_INTEL 	= 0x8086

local libName = "shaderlib"

shaderlib = shaderlib or {}

shaderlib.rt_Bump = GetRenderTargetEx("_rt_Bump", ScrW(), ScrH(),
    RT_SIZE_FULL_FRAME_BUFFER,
    MATERIAL_RT_DEPTH_SHARED,
   	bit.bor(4,8,256,512),
    --bit.bor(1,4,8,256,512),
    0, 
    IMAGE_FORMAT_RGBA8888
)

--[[shaderlib.rt_Blending = GetRenderTargetEx("_rt_Blending", ScrW(), ScrH(),
    RT_SIZE_FULL_FRAME_BUFFER,
    MATERIAL_RT_DEPTH_SHARED,
    bit.bor(4,8,256,512),
    0, 
    IMAGE_FORMAT_I8
)]]

local vendorID = 0

-- https:github.com/Facepunch/garrysmod-requests/issues/2768
local vendors_id = {
	[VENDORID_NVIDIA] 	= "NVIDIA";
	[VENDORID_ATI] 		= "AMD";
	[VENDORID_INTEL] 	= "INTEL";
}

local driverName = "UNKNOWN"

local function ReadReshadeGPU()
	local i = 0

	while true do
		local file_name = "ReShade.log"
		if i > 0 then file_name = file_name .. i end
		local log_reshade = file.Exists(file_name, "EXECUTABLE_PATH")

		if log_reshade then
			local log_text = file.Read( file_name, "EXECUTABLE_PATH" )
			local log_text_lower = string.lower(log_text)

			for id, vendor_name in pairs(vendors_id) do
				local finded, diver_start = string.find( log_text_lower, string.lower(vendor_name) )

				if finded then
					vendorID = id
					local end_test = string.find(log_text_lower, "driver", diver_start)
					driverName = string.sub( log_text, finded, end_test-2 )
					print("[GShader library] Found " .. driverName .. " driver")
					break
				end
			end

			if vendorID != 0 then break end
		else
			if i != 0 then
				break
			end
		end

		i = i + 1
	end
end

if file.Exists("ReShade.ini", "EXECUTABLE_PATH") then
	ReadReshadeGPU()
end

local function InitShaderLib()
	--RunConsoleCommand("mat_antialias", "0") -- MRT can not works with MSAA

	/*---------------------------------------------------------------------------
	system
	---------------------------------------------------------------------------*/

	function system.GetVendorID()
		return vendorID
	end

	function system.GetVendor()
		return vendors_id[system.GetVendorID()] or "UNKNOWN"
	end

	function system.GetDriverName()
		return driverName
	end

	function system.IsProton()
		return CEFCodecFixAvailable and !system.IsLinux() and !system.IsOSX()
	end

	/*---------------------------------------------------------------------------
	math
	---------------------------------------------------------------------------*/

	function math.cot(x) -- cotangent
	    return 1 / math.tan(x)
	end

	/*---------------------------------------------------------------------------
	vectors
	---------------------------------------------------------------------------*/

	function Vector4(x, y ,z, w)
		if isvector(x) then
			return {x = x.x or 0, y = x.y or 0, z = x.z or 0, w = y or 0}
		end

		if istable(x) and x[1] then
			return {x = x[1] or 0, y = x[2] or 0, z = x[3] or 0, w = x[4] or 0}
		end

	    return {x = x or 0, y = y or 0, z = z or 0, w = w or 0}
	end

	/*---------------------------------------------------------------------------
	shaderlib
	---------------------------------------------------------------------------*/

	local w,h = ScrW(),ScrH()
	local aspect = w/h
	local quad
	local verts

	local function InitMesh()
		if IsValid(shaderlib.mesh) then
		    shaderlib.mesh:Destroy()
		end

		shaderlib.mesh = Mesh()
		shaderlib.mesh:BuildFromTriangles( verts )
	end

	local function InitQuadTbl()
		w = ScrW(); h = ScrH();
		aspect = w/h

		quad = {
		    vector_origin,
		    Vector(w, 0),
		    Vector(w, h),
		    Vector(0, h),
		}

		verts = {
		    {pos = vector_origin, 	u = 0, v = 0},
		    {pos = Vector(w, 0), 	u = 1, v = 0},
		    {pos = Vector(w, h), 	u = 1, v = 1},

		    {pos = vector_origin, 	u = 0, v = 0},
		    {pos = Vector(w, h), 	u = 1, v = 1},
		    {pos = Vector(0, h), 	u = 0, v = 1}
		}

		 InitMesh()
	end

	hook.Add( "OnScreenSizeChanged", libName, InitQuadTbl)
	hook.Add( "InitPostEntity", libName, InitQuadTbl)
	InitQuadTbl()
	
	function shaderlib.DrawScreenQuad() 
	    cam.Start2D()
	        render.SetWriteDepthToDestAlpha( false )
	        cam.IgnoreZ( true )
	        render.DrawQuad(
	            quad[1],
	            quad[2],
	            quad[3],
	            quad[4]
	        )
	        cam.IgnoreZ( false )
	        render.SetWriteDepthToDestAlpha( true )
	    cam.End2D()
	end
	/*---------------------------------------------------------------------------
	This function allows you to use Multy Render Target on Screen draws.
	MRT does not work with 2D functions in GMOD. So we call 3D function
	render.DrawQuad in cam.Start2D.

	At the same time, data still cannot be written to the vertex shader.
	The whole problem is cam.Start2D.
	---------------------------------------------------------------------------*/

	function shaderlib.DrawScreenMesh() -- Essentially the same as shaderlib.DrawScreenQuad, but with greater potential for writing data to the mesh
	    cam.Start2D(EyePos(), EyeAngles(),1)
	        render.SetWriteDepthToDestAlpha( false )
	        cam.IgnoreZ( true )
	        shaderlib.mesh:Draw()
	        cam.IgnoreZ( false )
	        render.SetWriteDepthToDestAlpha( true )
	    cam.End2D()
	end

	shaderlib.quadVerts = {}

	local bias = 0.01 -- z-fighting fix
	local vector_right = Vector(0, -1, 0)
	local vector_forward = Vector(1, 0, 0)

	local old_fov = 0
	shaderlib.halfH = 0

	hook.Add("RenderScene",libName,function(origin, angles, fov)
		local viewSetup = render.GetViewSetup(true)
	    local znear = viewSetup.znear + bias

	    local f ,r, u = angles:Forward(), angles:Right(), angles:Up()
	    local center = origin + f * znear

	    if old_fov != fov then
	    	old_fov = fov
	    	shaderlib.halfH = math.tan(math.rad(fov * 0.5)) * znear
	    end
	    shaderlib.halfW = shaderlib.halfH * aspect

	    shaderlib.quadVerts[1] = center - r * shaderlib.halfW + u * shaderlib.halfH
	    shaderlib.quadVerts[2] = center + r * shaderlib.halfW + u * shaderlib.halfH
	    shaderlib.quadVerts[3] = center + r * shaderlib.halfW - u * shaderlib.halfH
	    shaderlib.quadVerts[4] = center - r * shaderlib.halfW - u * shaderlib.halfH
	end)

	local coords = {
		vector_origin;
		Vector(1,0);
		Vector(1,1);
		Vector(0,1);
	}

	function shaderlib.Draw3DScreenQuad( color )
		cam.Start3D()
		    render.SetWriteDepthToDestAlpha( false )
	        cam.IgnoreZ( true )
	        render.DrawQuad(
	            shaderlib.quadVerts[1],
	            shaderlib.quadVerts[2],
	            shaderlib.quadVerts[3],
	            shaderlib.quadVerts[4], color or color_white
	        )
	        cam.IgnoreZ( false )
	        render.SetWriteDepthToDestAlpha( true )
		cam.End3D()
	end

	function shaderlib.DrawVertexScreenQuad(mat, col, normal, tc1, tc2, tc3, tc4, tc5, tc6, tc7) -- Drawing PP shaders with MRT and vertex shader inputs
		cam.Start3D()
		    render.SetWriteDepthToDestAlpha( false )
		    render.OverrideDepthEnable(true,false)
			cam.IgnoreZ( true )

			local _mesh

			if mat then
				_mesh = Mesh(mat) -- tangents support
				mesh.Begin(_mesh, MATERIAL_QUADS, 1)
			else
				mesh.Begin(MATERIAL_QUADS, 1)
			end
				for i = 1,4 do
					mesh.Position(shaderlib.quadVerts[i])
					mesh.TexCoord( 0, coords[i].x, coords[i].y )
					if col then mesh.Color( col.r or 0, col.g or 0, col.b or 0,col.a or 255 ) end

					if normal then mesh.Normal( normal ) end

					if tc1 then mesh.TexCoord( 1, tc1.x or 0,tc1.y or 0,tc1.z or 0,tc1.w or 0 ) end
					if tc2 then mesh.TexCoord( 2, tc2.x or 0,tc2.y or 0,tc2.z or 0,tc2.w or 0 ) end
					if tc3 then mesh.TexCoord( 3, tc3.x or 0,tc3.y or 0,tc3.z or 0,tc3.w or 0 ) end
					if tc4 then mesh.TexCoord( 4, tc4.x or 0,tc4.y or 0,tc4.z or 0,tc4.w or 0 ) end
					if tc5 then mesh.TexCoord( 5, tc5.x or 0,tc5.y or 0,tc5.z or 0,tc5.w or 0 ) end
					if tc6 then mesh.TexCoord( 6, tc6.x or 0,tc6.y or 0,tc6.z or 0,tc6.w or 0 ) end
					if tc7 then mesh.TexCoord( 7, tc7.x or 0,tc7.y or 0,tc7.z or 0,tc7.w or 0 ) end

					mesh.AdvanceVertex()
				end
			mesh.End()

			if mat then
				_mesh:Draw()
			end

			cam.IgnoreZ( false )
			render.OverrideDepthEnable(false,false)
			render.SetWriteDepthToDestAlpha( true )
		cam.End3D()
	end

	function shaderlib.BuildWorldToShadowMatrix(translation, ang) -- View Flashlight
		local vForward = ang:Forward()
	    local vLeft = ang:Right()
	    local vUp = ang:Up()
	    
	    local matBasis = Matrix()
	    matBasis:SetForward(vLeft)
	    matBasis:SetRight(vUp)
	    matBasis:SetUp(vForward)
	    local matWorldToShadow = matBasis:GetTransposed()

	    translation = matWorldToShadow * translation
	    translation = -translation

	    matWorldToShadow:SetTranslation(translation)

	    --[[matWorldToShadow:SetField(4,1,0)
	    matWorldToShadow:SetField(4,2,0)
	    matWorldToShadow:SetField(4,3,0)
	    matWorldToShadow:SetField(4,4,1)]]

	    return matWorldToShadow
	end

	local t00_10 = {	0,  			0,			-1,				0			}

	function shaderlib.BuildPerspectiveWorldToFlashlightMatrix(viewSetup) -- ViewProj for Flashlight g_FlashlightWorldToTexture
		local pos, ang = viewSetup.origin, viewSetup.angles
		local mFlashlightView = shaderlib.BuildWorldToShadowMatrix(pos, ang)
		--mFlashlightView = shaderlib.GetViewMatrix(pos,ang)
		
		local fov = viewSetup.fov
		fov = math.cot( math.rad(fov * 0.5)  )
		local f = viewSetup.zfar
		local n = viewSetup.znear
		local aspect = viewSetup.aspect or 1
		local range = ( n - f )

		local mProj = Matrix({
            {	fov*aspect,  	0,			-0.5,      		0,			},
            {	0,  			fov,		-0.5,      		0,			},
            {	0, 				0,			f / range,	n * f / range,			},
            t00_10
        })

    	mProj:Mul(mFlashlightView)

    	return mProj
	end

	local t0001 = {0,		0,		0, 		1}

	-- View Matrix to get View Space Normals
	-- float3 N_view = normalize(mul(worldNormals, ViewMatrix));
	function shaderlib.GetViewSpaceMatrix(pos, ang)
		local D = ang:Forward()
	    local R = ang:Right()
	    local U = -ang:Up()
	    local P = -pos

	    local mFirst = Matrix({
	        {R.x, 	R.y, 	R.z,	0},
	        {U.x, 	U.y, 	U.z,	0},
	        {D.x, 	D.y, 	D.z,	0},
	        t0001,
	    })

	    local mSecond = Matrix({
	        {1, 	0, 		0, 		P.x},
	        {0, 	1, 		0, 		P.y},
	        {0, 	0, 		1, 		P.z},
	        t0001,
	    })

	    mFirst:Mul(mSecond)

	    return mFirst
	end

	-- Default View Matrix for using on ViewProj
	function shaderlib.GetViewMatrix(pos, ang)
		local D = -ang:Forward()
	    local R = ang:Right()
	    local U = -ang:Up() -- In Gmod func cam.GetViewMatrix() local U = ang:Up()
	    local P = -pos

	    local mFirst = Matrix({
	        {R.x, 	R.y, 	R.z,	0},
	        {U.x, 	U.y, 	U.z,	0},
	        {D.x, 	D.y, 	D.z,	0},
	        t0001,
	    })

	    local mSecond = Matrix({
	        {1, 	0, 		0, 		P.x},
	        {0, 	1, 		0, 		P.y},
	        {0, 	0, 		1, 		P.z},
	        t0001,
	    })

	    mFirst:Mul(mSecond)

	    return mFirst
	end

	local t0011 = {	0, 	0,				1, 				1			}

	function shaderlib.GetProjMatrix(viewSetup) --Perspective projection matrix
		local fov = viewSetup.fov
		fov = math.cot( math.rad(fov * 0.5)  )
		local aspect = viewSetup.aspect or 1

		local mProj = Matrix({
            {	fov,  0,			0,      		0,			},
            {	0,  fov*aspect,		0,      		0,			},
            t0011,
            t00_10
        })

    	return mProj
	end

	function shaderlib.GetViewProjMatrix(viewSetup)
		local pos, ang = viewSetup.origin, viewSetup.angles
		local mView = shaderlib.GetViewMatrix(pos, ang)

		local mProj = shaderlib.GetProjMatrix(viewSetup)
    	mProj:Mul(mView)

    	return mProj
	end

	function shaderlib.GetProjOrthoMartix(left, right, bottom, top, znear, zfar)
		local mProj = Matrix()
		
		mProj:SetUnpacked(
            2 / (right - left), 0, 					0, 					 (right + left) / (right - left),
            0, 					2 / (top - bottom), 0, 					 (top + bottom) / (top - bottom),
            0, 					0, 					-1 / (zfar - znear), -(zfar + znear) / (zfar - znear),
            0,		0,		0, 		1
        )

        mProj:InvertTR()
        return mProj
	end
	
	function shaderlib.GetViewProjZ(viewData)
		if !ismatrix(viewData) then viewData = shaderlib.GetViewProjMatrix(viewData) end
		return Vector4(
			viewData:GetField( 3,1 ),
			viewData:GetField( 3,2 ),
			viewData:GetField( 3,3 ),
			viewData:GetField( 3,4 )
		)
	end

	function shaderlib.GetViewProjOrthoMatrix(viewSetup)
		local pos, ang = viewSetup.origin, viewSetup.angles
		local mView = shaderlib.GetViewMatrix(pos, ang)

		local left = viewSetup.ortho.left
        local right = viewSetup.ortho.right
        local bottom = viewSetup.ortho.bottom
        local top = viewSetup.ortho.top
        local znear = viewSetup.znear
        local zfar = viewSetup.zfar

        local mProj = shaderlib.GetProjOrthoMartix(left, right, bottom, top, znear, zfar)
        
    	mProj:Mul(mView)

    	return mProj
	end
	
	//-----------------------------------------------------------------------------
	// Purpose: Do the headlight
	//-----------------------------------------------------------------------------
	local mins, maxs = Vector(-4, -4, -4), Vector(4, 4, 4)
	local state = false

	local flash_mat = CreateMaterial("_flash", "UnlitGeneric", {})
	flash_mat:SetTexture("$basetexture", "effects/flashlight001")

	local m_FlashlightTexture = flash_mat:GetTexture("$basetexture")
	local m_flDistMod = 0 -- CONFIRM: Maybe need to transfer it to separate Think function

	function shaderlib.GetHeadlightEffect()
		local vecPos = MainEyePos()
		local eyeangles = MainEyeAngles()
		local vecForward = eyeangles:Forward()
		local vecRight = eyeangles:Right()
		local vecUp = eyeangles:Up()

		local client = LocalPlayer()

		local m_bIsOn = client:FlashlightIsOn()

		local function TurnOn()
			m_flDistMod = 1.0
		end

		if !state and m_bIsOn then
			TurnOn()
			state = true
		end

		if !m_bIsOn then
			state = false
		end

		local bPlayerOnLadder = ( client:GetMoveType() == MOVETYPE_LADDER )

		local flEpsilon = 0.1			// Offset flashlight position along vecUp
		local flDistCutoff = 128.0
		local flDistDrag = 0.2

		local traceFilter = {client, client:GetActiveWeapon()}

		local flOffsetY = GetConVar("r_flashlightoffsety"):GetFloat()

		if GetConVar("r_swingflashlight"):GetBool() then

			// This projects the view direction backwards, attempting to raise the vertical
			// offset of the flashlight, but only when the player is looking down.
			local vecSwingLight = vecPos + vecForward * -12.0;
			if( vecSwingLight.z > vecPos.z ) then
				flOffsetY = flOffsetY + (vecSwingLight.z - vecPos.z);
			end
		end

		local vOrigin = vecPos + flOffsetY * vecUp;

		// Not on ladder...trace a hull
		if ( !bPlayerOnLadder ) then

			local pmOriginTrace = util.TraceHull( {
				start = vecPos,
				endpos = vOrigin,
				mins = mins,
				maxs = maxs,
				mask = bit.band( MASK_SOLID, bit.bnot(CONTENTS_HITBOX) ),
				filter = traceFilter
			} )

			if ( pmOriginTrace.Hit ) then
				vOrigin = vecPos;
			end
		else // on ladder...skip the above hull trace
			vOrigin = vecPos;
		end

		// Now do a trace along the flashlight direction to ensure there is nothing within range to pull back from
		local iMask = MASK_OPAQUE_AND_NPCS

		iMask = bit.band( iMask, bit.bnot(CONTENTS_HITBOX) )
		iMask = bit.bor( iMask, CONTENTS_WINDOW )

		local vTarget = vecPos + vecForward * GetConVar("r_flashlightfar"):GetFloat()

		// Work with these local copies of the basis for the rest of the function
		local vDir   = vTarget - vOrigin
		local vRight = Vector(0,0,0)
		vRight:Set(vecRight)
		local vUp    = Vector(0,0,0)
		vUp:Set(vecUp)

		vDir:Normalize()
		vRight:Normalize()
		vUp:Normalize()

		// Orthonormalize the basis, since the flashlight texture projection will require this later...
		vUp = vUp - vDir:Dot( vUp ) * vDir;
		vUp:Normalize()
		vRight = vRight - vDir:Dot( vRight ) * vDir;
		vRight:Normalize()
		vRight = vRight - vUp:Dot( vRight ) * vUp;
		vRight:Normalize()

		local pmDirectionTrace = util.TraceHull( {
			start = vOrigin,
			endpos = vTarget,
			mins = mins,
			maxs = maxs,
			mask = iMask,
			filter = traceFilter
		} )

		if ( GetConVar("r_flashlightvisualizetrace"):GetBool() == true ) then
			cam.Start3D()
				render.SetColorMaterial()
				cam.IgnoreZ(true)
				render.DrawWireframeBox( pmDirectionTrace.HitPos, angle_zero, mins, maxs, Color( 0, 255, 0, 160 ) )
				 render.DrawLine( vOrigin, pmDirectionTrace.HitPos, Color( 0, 255, 0 ) )
				cam.IgnoreZ(false)
			cam.End3D()
		end


		local flDist = (pmDirectionTrace.HitPos - vOrigin):Length()
		if ( flDist < flDistCutoff ) then
			// We have an intersection with our cutoff range
			// Determine how far to pull back, then trace to see if we are clear
			local flPullBackDist = bPlayerOnLadder and r_flashlightladderdist.GetFloat() or flDistCutoff - flDist;	// Fixed pull-back distance if on ladder
			m_flDistMod = Lerp( flDistDrag, m_flDistMod, flPullBackDist );
			
			if ( !bPlayerOnLadder ) then
				local pmBackTrace = util.TraceHull( {
					start = vOrigin,
					endpos = vOrigin - vDir*(flPullBackDist-flEpsilon),
					mins = mins,
					maxs = maxs,
					mask = iMask,
					filter = traceFilter
				} )

				if( pmBackTrace.HitPos ) then
					// We have an intersection behind us as well, so limit our m_flDistMod
					local flMaxDist = (pmBackTrace.endpos - vOrigin):Length() - flEpsilon
					if( m_flDistMod > flMaxDist ) then m_flDistMod = flMaxDist end
				end
			end
		else
			m_flDistMod = Lerp( flDistDrag, m_flDistMod, 0.0 );
		end

		vOrigin = vOrigin - vDir * m_flDistMod;

		local state = {}
		state.m_vecLightOrigin = vOrigin;

		local matrix = Matrix()
		matrix:SetForward(vDir)
		matrix:SetRight(vecRight)
		matrix:SetUp(vUp)

		state.m_quatOrientation = matrix:GetAngles()

		state.m_fQuadraticAtten = GetConVar("r_flashlightquadratic"):GetFloat()

		local bFlicker = false

		if ( bFlicker == false ) then
			state.m_fLinearAtten = GetConVar("r_flashlightlinear"):GetFloat()
			state.m_fHorizontalFOVDegrees = GetConVar("r_flashlightfov"):GetFloat()
			state.m_fVerticalFOVDegrees = GetConVar("r_flashlightfov"):GetFloat()
		end

		state.m_fConstantAtten = GetConVar("r_flashlightconstant"):GetFloat()
		local flashlightColor = client:GetFlashlightColor()
		state.m_Color = Color( flashlightColor.r, flashlightColor.g, flashlightColor.b, GetConVar("r_flashlightambient"):GetFloat())
		state.m_NearZ = GetConVar("r_flashlightnear"):GetFloat() + m_flDistMod;	// Push near plane out so that we don't clip the world when the flashlight pulls back 
		state.m_FarZ = GetConVar("r_flashlightfar"):GetFloat()
		state.m_bEnableShadows = GetConVar("r_flashlightdepthtexture"):GetBool()
		state.m_flShadowMapResolution = GetConVar("r_flashlightdepthres"):GetInt()

		state.m_pSpotlightTexture = m_FlashlightTexture

		state.m_flShadowAtten = GetConVar("r_flashlightshadowatten"):GetFloat()
		state.m_flShadowSlopeScaleDepthBias = GetConVar("mat_slopescaledepthbias_shadowmap"):GetFloat()
		state.m_flShadowDepthBias = GetConVar("mat_depthbias_shadowmap"):GetFloat()

		state.m_fHorizontalFOVDegrees = 45.0
		state.m_fVerticalFOVDegrees = 30.0

		state.m_nSpotlightTextureFrame = 0

		return state
	end

	hook.Run("InitReconstruction")
	hook.Run("InitPostReconstruction")
	hook.Run("InitPostShaderlib")
end

hook.Add("Initialize", libName, InitShaderLib)

