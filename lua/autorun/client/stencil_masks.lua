
local stencilHook = "StencilMasks"

STENCIL_WEAPON = 0x01

hook.Add("PreDrawViewModels", stencilHook, function(hands, ply, weapon)
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

hook.Add("PostDrawPlayerHands", stencilHook, function()
 	render.SetStencilEnable( false )
end)




