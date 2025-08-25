
local libName = "shaderlib"

/*---------------------------------------------------------------------------
GShaderlib authors: Meetric, Akabenko
---------------------------------------------------------------------------*/

local function InitShaderLib()
	//RunConsoleCommand("mat_antialias", "0") // MRT can not works with MSAA (confirm)

	VENDORID_NVIDIA = 0x10DE
	VENDORID_ATI 	= 0x1002
	VENDORID_INTEL 	= 0x8086

	// prolly works (confirm); prolly breaks on linux (confirm)
	TEXFILTER.PYRAMIDALQUAD 	= 6
	TEXFILTER.GAUSSIANQUAD 		= 7
	TEXFILTER.CONVOLUTIONMONO 	= 8 			/* D3D9Ex only -- */
	TEXFILTER.FORCE_DWORD 		= 0x7fffffff 	// force 32-bit size enum
	
	D3D9EX = !GetConVar("mat_disable_d3d9ex"):GetBool() // thanks puwada

	cvars.AddChangeCallback("mat_disable_d3d9ex", function(convar_name, value_old, value_new)
	    D3D9EX = !tobool(value_new)
	end)

	hook.Add( "InitPostEntity", "Ready", function()
		if !D3D9EX and render.GetDXLevel() != 92 then
			LocalPlayer():ChatPrint( "[shaderlib]: d3d9ex is disabled on your settings. Run «mat_disable_d3d9ex 0» to get support for better image formats. Artefacts are possible!" )
		end
	end )

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

	IMAGE_FORMAT_I8 					=	5 	// + ; One of the cheapest texture formats.
	IMAGE_FORMAT_IA88 					=	6 	// +

	IMAGE_FORMAT_P8 					=	7
	/*---------------------------------------------------------------------------
	Paletted (GL_COLOR_INDEX on OpenGL) format (written to CPU). Perhaps the
	texture can be manually assembled bytes, but it is not a fact that it wil
	work in the resource. Vtf Editor does not support saving in P8 format.
	---------------------------------------------------------------------------*/

	IMAGE_FORMAT_A8 					=	8 	// + 
	IMAGE_FORMAT_BGRX8888 				=	16 	// + 
	IMAGE_FORMAT_BGR565 				=	17 	// + 
	IMAGE_FORMAT_BGRX5551 				=	18 	// +; «X» may indicate that the layer contains stencil information (confirm).
	IMAGE_FORMAT_BGRA4444 				=	19 	// + 

	IMAGE_FORMAT_R32F 					=	27	// + Single-channel 32-bit floating point. Not works on dx92 (Linux)
	IMAGE_FORMAT_RGBA32323232F 			=	29 	// + 
	// IMAGE_FORMAT_R32F and IMAGE_FORMAT_RGBA32323232F Works only with D3D9EX enabled

	IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	9 	// (t)
	IMAGE_FORMAT_BGR888_BLUESCREEEN 	=	10 	// (t)

	IMAGE_FORMAT_DXT1 					=	13 	// (t)
	IMAGE_FORMAT_DXT3 					=	14 	// (t)
	IMAGE_FORMAT_DXT5 					=	15 	// (t)
	IMAGE_FORMAT_BGRX8 					=	16 	// + 
	IMAGE_FORMAT_RGB323232F 			=	28
	
	IMAGE_FORMAT_DXT1_ONEBITALPHA 		=	20 	// (t)
	IMAGE_FORMAT_BGRA5551 				=	21 	// +
	IMAGE_FORMAT_UV88 					=	22 	// (t) DuDv map
	IMAGE_FORMAT_UVWQ8888 				=	23 	// (t)
	IMAGE_FORMAT_UVLX8888 				=	26 	// (t)

	IMAGE_FORMAT_RG1616F 				= 	30
	IMAGE_FORMAT_RG3232F 				= 	31 
	/*---------------------------------------------------------------------------
	This would be a great format for VSM shadow filtering, as well as for Dual
	paraboloid point lights. But it doesn't work.
	.R - Depth
	.G - Depth^2
	---------------------------------------------------------------------------*/
	
	/*---------------------------------------------------------------------------
	gpus from 2000-2008ish supported these formats. but modern gpus no longer do
	---------------------------------------------------------------------------*/

	IMAGE_FORMAT_RGBX8888 				= 	32 	// (t)
	IMAGE_FORMAT_NV_NULL 				= 	33
	/*---------------------------------------------------------------------------
	Dummy format which takes no video memory.
	It seems to work. But when rendering a scene to NV_NULL, Multy Render Target
	stops working inside this render. So use IMAGE_FORMAT_I8 for dummy rt.
	---------------------------------------------------------------------------*/

	// Compressed normal map formats (Most likely it is a format for textures)
	IMAGE_FORMAT_ATI1N 					= 	34 	// Two-surface ATI1N format
	IMAGE_FORMAT_ATI2N 					= 	35 	// One-surface ATI2N / DXN format

	IMAGE_FORMAT_RGBA1010102 			= 	36 	// This could be a useful format for saving WorldNormals economically. But it doesn't work.
	IMAGE_FORMAT_BGRA1010102 			= 	37
	IMAGE_FORMAT_R16F 					= 	38

	/*---------------------------------------------------------------------------
	Depth-stencil texture formats for shadow depth mapping These formats write
	SV_Depth output from pixel shader.

	STUDIO_SHADOWDEPTHTEXTURE
	ShadowDepthTextureFormat = render.GetDXLevel() == 92 and IMAGE_FORMAT_D16_SHADOW or IMAGE_FORMAT_D24X8_SHADOW
	This formats needed for Hardware PCF: tex2Dproj
	---------------------------------------------------------------------------*/
	IMAGE_FORMAT_D16 					= 	39 	// (?)
	IMAGE_FORMAT_D15S1 					= 	40
	IMAGE_FORMAT_D32 					= 	41
	IMAGE_FORMAT_D24S8 					= 	42 	// X-RAY S.T.A.L.K.E.R Depth image format
	IMAGE_FORMAT_LINEAR_D24S8 			= 	43
	IMAGE_FORMAT_D24X8 					= 	44
	IMAGE_FORMAT_D24X4S4 				= 	45
	IMAGE_FORMAT_D24FS8 				= 	46
	IMAGE_FORMAT_D16_SHADOW 			= 	47 	// (?)
	IMAGE_FORMAT_D24X8_SHADOW 			= 	48 	// (?) 24 bit depth + 8 bit stencil. In theory, a great choice for shadow maps.

	// supporting these specific formats as non-tiled for procedural cpu access
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
	
	IMAGE_FORMAT_INTZ 					= 	67 	// (?) 24-bit depth, 8-bit stencil; Most likely, also write SV_Depth 
	//   NVFMT_INTZ is supported on newer chips as of G8x (just read like ATI non-fetch4 mode) (NVIDIA GeForce 8800 Ultra,,0x10DE,0x0194)

	/*---------------------------------------------------------------------------
	math
	---------------------------------------------------------------------------*/

	function math.cot(x) // cotangent
	    return 1 / math.tan(x)
	end

	/*---------------------------------------------------------------------------
	shaderlib
	---------------------------------------------------------------------------*/

	shaderlib = shaderlib or {}
	RegisterMetaTable( "shaderlib", shaderlib )

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

	hook.Add( "OnScreenSizeChanged", libName, function()
		w = ScrW(); h = ScrH();
		aspect = w/h
		InitQuadTbl()
	end )
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

	function shaderlib.DrawScreenMesh() // Essentially the same as shaderlib.DrawScreenQuad, but with greater potential for writing data to the mesh
	    cam.Start2D(EyePos(), EyeAngles(),1)
	        render.SetWriteDepthToDestAlpha( false )
	        cam.IgnoreZ( true )
	        shaderlib.mesh:Draw()
	        cam.IgnoreZ( false )
	        render.SetWriteDepthToDestAlpha( true )
	    cam.End2D()
	end

	local quadVerts = {}

	local bias = 0.01 // z-fighting fix
	local vector_right = Vector(0, -1, 0)
	local vector_forward = Vector(1, 0, 0)

	local old_fov, halfH = 0, 0

	hook.Add("RenderScene",libName,function(origin, angles, fov)
		local viewSetup = render.GetViewSetup(true)
	    local znear = viewSetup.znear + bias

	    local f ,r, u = angles:Forward(), angles:Right(), angles:Up()
	    local center = origin + f * znear

	    if old_fov != fov then
	    	old_fov = fov
	    	halfH = math.tan(math.rad(fov * 0.5)) * znear
	    end
	    local halfW = halfH * aspect

	    quadVerts[1] = center - r * halfW + u * halfH
	    quadVerts[2] = center + r * halfW + u * halfH
	    quadVerts[3] = center + r * halfW - u * halfH
	    quadVerts[4] = center - r * halfW - u * halfH
	end)

	function shaderlib.DrawVertexScreenQuad(col, normal) // Drawing PP shaders with MRT and vertex shader inputs
		cam.Start3D()
		    render.SetWriteDepthToDestAlpha( false )
		    render.OverrideDepthEnable(true,false)
			cam.IgnoreZ( true )

			mesh.Begin(MATERIAL_QUADS, 1)
				for i = 1,4 do
					mesh.Position(quadVerts[i])
					mesh.Color( col.r or 0, col.g or 0, col.b or 0,col.a or 0 )
					mesh.Normal( normal or vector_origin )
					mesh.AdvanceVertex()
				end
			mesh.End()

			cam.IgnoreZ( false )
			render.OverrideDepthEnable(false,false)
			render.SetWriteDepthToDestAlpha( true )
		cam.End3D()
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

	function shaderlib.GetProjMatrix(viewSetup) //Perspective projection matrix
		local mProj = Matrix()
		local fov = viewSetup.fov
		local f = math.cot( math.rad(fov * 0.5)  )
		local z = viewSetup.zfar
		local n = viewSetup.znear
		local aspect = viewSetup.aspect or 1

		mProj:SetUnpacked(
            f,  0,          0,      0,
            0,  f*aspect,   0,      0,
            --0, 0, (z+n)/(z-n), (2*z*n)/(z-n),	//	This may make sense, but the depth calculations for the perspective matrix happen inside the shader.hlsl.
            0,  0,          1,      1, 			// 	That's why I wrote 1, 1. 
            0,  0,          -1,     0
        )

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
InitShaderLib()
hook.Add("Initialize", libName, InitShaderLib)
