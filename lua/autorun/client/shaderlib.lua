
/*---------------------------------------------------------------------------
GShaderlib authors: Meetric, Akabenko
---------------------------------------------------------------------------*/

local libName = "shaderlib"

GSHADER = true
RESHADE 	= file.Exists("ReShade.ini", "EXECUTABLE_PATH")
DGVOODOO 	= file.Exists("dgVoodoo.conf", "EXECUTABLE_PATH")
DXVK 		= ( !DGVOODOO and !RESHADE and file.Exists("d3d9.dll", "EXECUTABLE_PATH") )

local function InitShaderLib()
	--RunConsoleCommand("mat_antialias", "0") -- MRT can not works with MSAA (confirm)

	/*---------------------------------------------------------------------------
	system
	---------------------------------------------------------------------------*/
	local vendorID = 0

	VENDORID_NVIDIA = 0x10DE
	VENDORID_ATI 	= 0x1002
	VENDORID_INTEL 	= 0x8086
	--https:--github.com/Facepunch/garrysmod-requests/issues/2768
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

	if RESHADE then
		ReadReshadeGPU()
	end

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

	-- prolly works (confirm); prolly breaks on linux (confirm)
	TEXFILTER.PYRAMIDALQUAD 	= 6
	TEXFILTER.GAUSSIANQUAD 		= 7
	TEXFILTER.CONVOLUTIONMONO 	= 8 			/* D3D9Ex only -- */
	TEXFILTER.FORCE_DWORD 		= 0x7fffffff 	-- force 32-bit size enum

	local linux = system.IsLinux()
	local mac = system.IsOSX()

	if !linux and !mac then
		D3D9EX = !GetConVar("mat_disable_d3d9ex"):GetBool() -- thanks puwada

		cvars.AddChangeCallback("mat_disable_d3d9ex", function(convar_name, value_old, value_new)
		    D3D9EX = !tobool(value_new)
		end)

		hook.Add( "InitPostEntity", "Ready", function()
			if !D3D9EX and render.GetDXLevel() != 92 then
				LocalPlayer():ChatPrint( "[shaderlib]: d3d9ex is disabled on your settings. Run «mat_disable_d3d9ex 0» to get support for better image formats. Artefacts are possible!" )
			end
		end )
	end

	/*---------------------------------------------------------------------------
	IMAGE FORMATS

	NOTE:
	 + 	IMAGE_FORMAT works
	(?) IMAGE_FORMAT potentially works - successfully created, but it is not yet known how it works in gmod
	Rest cause an error: ShaderAPIDX8::CreateD3DTexture: Invalid color format!
	(t) works only for .vtf textures

	Perhaps some formats will work when forcing the parameters of other video cards and manufacturers:
	-force_vendor_id 0x10DE -force_device_id 0x0200 -tools
	Or on other DirectX or operating systems - Windows/Linux:
	+mat_dxlevel (?70)/80/81/90/95(92)
	---------------------------------------------------------------------------*/

	IMAGE_FORMAT_I8 					=	5 	-- + ; One of the cheapest texture formats.
	IMAGE_FORMAT_IA88 					=	6 	-- +
	IMAGE_FORMAT_P8 					=	7
	/*---------------------------------------------------------------------------
	Paletted (GL_COLOR_INDEX on OpenGL) format (written to CPU). Perhaps the
	texture can be manually assembled bytes, but it is not a fact that it wil
	work in the resource. Vtf Editor does not support saving in P8 format.
	---------------------------------------------------------------------------*/

	IMAGE_FORMAT_A8 					=	8 	-- + 
	IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	9 	-- (t)
	IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	10 	-- (t)
	IMAGE_FORMAT_DXT1 					=	13 	-- (t)
	IMAGE_FORMAT_DXT3 					=	14 	-- (t)
	IMAGE_FORMAT_DXT5 					=	15 	-- (t)
	IMAGE_FORMAT_BGRX8888 				=	16 	-- + 
	IMAGE_FORMAT_BGR565 				=	17 	-- + 
	IMAGE_FORMAT_BGRX5551 				=	18 	-- +; «X» may indicate that the layer contains stencil information (confirm).
	IMAGE_FORMAT_BGRA4444 				=	19 	-- + 
	IMAGE_FORMAT_DXT1_ONEBITALPHA 		=	20 	-- (t)
	IMAGE_FORMAT_BGRA5551 				=	21 	-- +
	IMAGE_FORMAT_UV88 					=	22 	-- (t) DuDv map
	IMAGE_FORMAT_UVWQ8888 				=	23 	-- (t)
	IMAGE_FORMAT_UVLX8888 				=	26 	-- (t)
	IMAGE_FORMAT_R32F 					=	27	-- + Single-channel 32-bit floating point. Not works on dx92 (Linux)
	IMAGE_FORMAT_RGB323232F 			=	28  -- NOTE: D3D9 does not have this format
	IMAGE_FORMAT_RGBA32323232F 			=	29 	-- + 

	if BRANCH == "x86-64" then -- CS:GO ids
		/*---------------------------------------------------------------------------
		This would be a great format for VSM shadow filtering, as well as for Dual
		paraboloid point lights. But it doesn't work.
		.R - Depth
		.G - Depth^2
		---------------------------------------------------------------------------*/
		
		IMAGE_FORMAT_RG1616F 				= 	30
		IMAGE_FORMAT_RG3232F 				= 	31 

		IMAGE_FORMAT_RGBX8888 				= 	32 	-- (t)

		IMAGE_FORMAT_NV_NULL 				= 	33

		-- Compressed normal map formats (.vtf textures)
		IMAGE_FORMAT_ATI1N 					= 	34 	-- (t) Two-surface ATI1N format
		IMAGE_FORMAT_ATI2N 					= 	35 	-- (t) One-surface ATI2N / DXN format

		IMAGE_FORMAT_RGBA1010102 			= 	36 	-- 10 bit-per component render targets
		IMAGE_FORMAT_BGRA1010102 			= 	37
		IMAGE_FORMAT_R16F 					= 	38 	-- 16 bit FP format

		/*---------------------------------------------------------------------------
		Depth-stencil texture formats for shadow depth mapping These formats write
		SV_Depth output from pixel shader.

		STUDIO_SHADOWDEPTHTEXTURE
		ShadowDepthTextureFormat = render.GetDXLevel() == 92 and IMAGE_FORMAT_D16_SHADOW or IMAGE_FORMAT_D24X8_SHADOW
		This formats needed for Hardware PCF: tex2Dproj
		---------------------------------------------------------------------------*/
		IMAGE_FORMAT_D16 					= 	39 	-- (?)
		IMAGE_FORMAT_D15S1 					= 	40
		IMAGE_FORMAT_D32 					= 	41
		IMAGE_FORMAT_D24S8 					= 	42 	-- X-RAY S.T.A.L.K.E.R Depth image format
		IMAGE_FORMAT_LINEAR_D24S8 			= 	43
		IMAGE_FORMAT_D24X8 					= 	44
		IMAGE_FORMAT_D24X4S4 				= 	45
		IMAGE_FORMAT_D24FS8 				= 	46
		IMAGE_FORMAT_D16_SHADOW 			= 	47 	-- (?)
		IMAGE_FORMAT_D24X8_SHADOW 			= 	48 	-- (?) 24 bit depth + 8 bit stencil. In theory, a great choice for shadow maps.

		-- supporting these specific formats as non-tiled for procedural cpu access
		IMAGE_FORMAT_LINEAR_BGRX888 		= 	49
		IMAGE_FORMAT_LINEAR_RGBA8888 		= 	50
		IMAGE_FORMAT_LINEAR_ABGR8888 		= 	51
		IMAGE_FORMAT_LINEAR_ARGB8888 		= 	52
		IMAGE_FORMAT_LINEAR_BGRA8888 		= 	53
		IMAGE_FORMAT_LINEAR_BGR888 			= 	54
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
		
		IMAGE_FORMAT_INTZ 					= 	67 	-- (?) 24-bit depth, 8-bit stencil; Most likely, also write SV_Depth 
		--   NVFMT_INTZ is supported on newer chips as of G8x (just read like ATI non-fetch4 mode) (NVIDIA GeForce 8800 Ultra,,0x10DE,0x0194)
	else -- TF2 values
		IMAGE_FORMAT_NV_DST16 				= 	30  -- (?)
		IMAGE_FORMAT_NV_DST24 				= 	31  -- (?)

		IMAGE_FORMAT_NV_INTZ 				= 	32  -- (?)
		IMAGE_FORMAT_NV_RAWZ 				= 	33

		IMAGE_FORMAT_ATI_DST16 				= 	34
		IMAGE_FORMAT_ATI_DST24 				= 	35

		/*---------------------------------------------------------------------------
		Dummy format which takes no video memory.
		It seems to work. But when rendering a scene to NV_NULL, Multy Render Target
		stops working inside this render. So use IMAGE_FORMAT_I8 for dummy rt.
		---------------------------------------------------------------------------*/
		IMAGE_FORMAT_NV_NULL 				= 	36  -- (?)

		IMAGE_FORMAT_ATI1N 					= 	37  -- (t)
		IMAGE_FORMAT_ATI2N 					= 	38  -- (t)
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

	shaderlib = shaderlib or {}

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

	function shaderlib.Draw3DScreenQuad()
		cam.Start3D()
		    render.SetWriteDepthToDestAlpha( false )
	        cam.IgnoreZ( true )
	        render.DrawQuad(
	            shaderlib.quadVerts[1],
	            shaderlib.quadVerts[2],
	            shaderlib.quadVerts[3],
	            shaderlib.quadVerts[4]
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

	function shaderlib.BuildPerspectiveWorldToFlashlightMatrix(viewSetup) -- ViewProj for Flashlight g_FlashlightWorldToTexture
		local pos, ang = viewSetup.origin, viewSetup.angles
		local mFlashlightView = shaderlib.BuildWorldToShadowMatrix(pos, ang)
		--mFlashlightView = shaderlib.GetViewMatrix(pos,ang)

		local fov = viewSetup.fov
		fov = math.cot( math.rad(fov * 0.5)  )
		local f = viewSetup.zfar
		local n = viewSetup.znear
		local aspect = viewSetup.aspect or 1

		local mProj = Matrix({
            {	fov*aspect,  	0,			-0.5,      		0,			},
            {	0,  			fov,		-0.5,      		0,			},
            {	0, 				0,			f / ( n - f ),	n * f / ( n - f ),			},
            {	0,  			0,			-1,				0			}
        })

    	mProj:Mul(mFlashlightView)

    	return mProj
	end

	function shaderlib.GetViewMatrix(pos, ang)
		local D = -ang:Forward()
	    local R = ang:Right()
	    local U = -ang:Up()
	    local P = -pos

	    local mFirst = Matrix({
	        {R.x, 	R.y, 	R.z,	0},
	        {U.x, 	U.y, 	U.z,	0},
	        {D.x, 	D.y, 	D.z,	0},
	        {0,		0,		0, 		1},
	    })

	    local mSecond = Matrix({
	        {1, 	0, 		0, 		P.x},
	        {0, 	1, 		0, 		P.y},
	        {0, 	0, 		1, 		P.z},
	        {0, 	0, 		0, 		1},
	    })

	    mFirst:Mul(mSecond)

	    return mFirst
	end

	function shaderlib.GetProjMatrix(viewSetup) --Perspective projection matrix
		local fov = viewSetup.fov
		fov = math.cot( math.rad(fov * 0.5)  )
		local aspect = viewSetup.aspect or 1

		local mProj = Matrix({
            {	fov,  0,			0,      		0,			},
            {	0,  fov*aspect,		0,      		0,			},
            {	0, 	0,				1, 				1			},
            {	0,  0,				-1,     		0			}
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
            0, 					0, 					0, 					 1
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

	hook.Run("InitReconstruction")
	hook.Run("InitPostReconstruction")
	hook.Run("InitPostShaderlib")
end

hook.Add("Initialize", libName, InitShaderLib)
