/*---------------------------------------------------------------------------
Fixing some workshop addons for NeedDepthPass.
---------------------------------------------------------------------------*/

local libname = "shaderlib_fixes"

hook.Add("Initialize", libname,function()
    hook.Remove("NeedsDepthPass", "FAS2_NeedsDepthPass") // FAS2 fix: Fas2 broke ResolvedDepthBuffer
end)

/*---------------------------------------------------------------------------
UNFIXED:
Enhanced Camera             https://steamcommunity.com/sharedfiles/filedetails/?id=678037029&searchtext=Enhanced+Camera
---------------------------------------------------------------------------*/