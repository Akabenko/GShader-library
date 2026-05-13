/*---------------------------------------------------------------------------
Fixing some workshop addons for NeedDepthPass.
---------------------------------------------------------------------------*/

local libname = "shaderlib_fixes"

hook.Add("Initialize", libname,function()
    --RunConsoleCommand("mat_viewportscale", 1) -- some users have 0.8 value. so it broke depth buffer
    hook.Remove("NeedsDepthPass", "FAS2_NeedsDepthPass") // FAS2 fix: Fas2 broke ResolvedDepthBuffer
    --RunConsoleCommand("fas2_blureffects", 0)
    --RunConsoleCommand("fas2_blureffects_depth", 0)
end)

/*---------------------------------------------------------------------------
UNFIXED:
Enhanced Camera             https://steamcommunity.com/sharedfiles/filedetails/?id=678037029&searchtext=Enhanced+Camera
---------------------------------------------------------------------------*/
