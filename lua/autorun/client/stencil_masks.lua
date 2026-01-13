
local stencilHook = "StencilMasks"

STENCIL_WEAPON = 0x01

hook.Add("PreDrawViewModel", stencilHook, function(vm, ply, weapon, flags)
	flags = flags or STUDIO_RENDER
	local isDepthPass = ( bit.band( flags, STUDIO_SSAODEPTHTEXTURE ) != 0 || bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) != 0 )
	if ( isDepthPass ) then return end
	
	if IsValid(weapon) and weapon:GetClass() == "gmod_camera" then return end
	
	render.SetStencilEnable( true )

	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(STENCIL_WEAPON)
	
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
end)

hook.Add("PostDrawPlayerHands", stencilHook, function(hands, vm, ply, weapon, flags)
	flags = flags or STUDIO_RENDER
	local isDepthPass = ( bit.band( flags, STUDIO_SSAODEPTHTEXTURE ) != 0 || bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) != 0 )
	if ( isDepthPass ) then return end
 	render.SetStencilEnable( false )
end)
