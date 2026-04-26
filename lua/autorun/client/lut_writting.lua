
local mat = Material("pp/lut_writting")

function shaderlib.WritePixel(rt, x, y, r, g, b, a)
	local w = rt:Width()
	if x > (w - 1)  or x < 0 then return end
	local h = rt:Height()
	if y > (h -1) or y < 0 then return end

	if IsColor(r) then r, g, b, a = r.r, r.g, r.b, r.a end

	mat:SetFloat( "$c0_x", r or 255 )
	mat:SetFloat( "$c0_y", g or 255 )
	mat:SetFloat( "$c0_z", b or 255 )
	mat:SetFloat( "$c0_w", a or 255 )

	render.PushRenderTarget( rt, x, y, 1, 1 )
		render.Clear( 0, 0, 0, 0 )
		cam.Start2D()
			render.SetMaterial( mat )
			shaderlib.DrawScreenQuad()
		cam.End2D()
	render.PopRenderTarget()
end

shaderlib.lut_textures = shaderlib.lut_textures or {}

function shaderlib.CreateLUT(name, w, h, format)
	if shaderlib.lut_textures[name] then return shaderlib.lut_textures[name] end

	local rt = GetRenderTargetEx(name, w, h,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_NONE,
		bit.bor( 1, 4, 8, 256, 512 ),
		0,
		format or IMAGE_FORMAT_RGBA32323232F -- or IMAGE_FORMAT_RGBA16161616F
	)

	shaderlib.lut_textures[name] = rt

	render.PushRenderTarget( rt )
		render.Clear( 0, 0, 0, 0 )
	render.PopRenderTarget()

	return rt
end

/*---------------------------------------------------------------------------
Sample of creating LUT texture
---------------------------------------------------------------------------*/

--[[local lut = shaderlib.CreateLUT("_rt_LUT_custom", 8, 16)

for x = 0,lut:Width() do
	for y = 0,lut:Height() do
		shaderlib.WritePixel(lut, x,y, math.Rand(0, 0.3123123), math.Rand(0, 0.3123123), math.Rand(0, 0.123123), math.Rand(0, 0.23123))
	end
end]]



