
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
FIXED:
First Person Legs:          https://steamcommunity.com/sharedfiles/filedetails/?id=3348203779&searchtext=legs
GMOD Legs 3                 https://steamcommunity.com/sharedfiles/filedetails/?id=112806637&searchtext=gmod+legs (Mirror bug)
clegs                       https://steamcommunity.com/sharedfiles/filedetails/?id=3386878739&searchtext=clegs+
Enhanced Camera 2           https://steamcommunity.com/sharedfiles/filedetails/?id=2203217139

UNFIXED:
Enhanced Camera             https://steamcommunity.com/sharedfiles/filedetails/?id=678037029&searchtext=Enhanced+Camera

CFShadow: broke depth buffer
https://steamcommunity.com/sharedfiles/filedetails/?id=3386876474

Тело от Первого лица: https://steamcommunity.com/sharedfiles/filedetails/?id=3104967124

CONFIRM:
VManip (Base)               https://steamcommunity.com/sharedfiles/filedetails/?id=2155366756

Исправлено:
1. В TFA (3D SCOPES) не появляются фонтанчики от выстрелом при включенном MRT
2. Фонарики ТФА запаздыают из-за буфера глубины (фикс - выбран рекомендованный хук для обновления projtexture)
4. Антискример не давал вызвать локализированные функции DrawScreenQuad https://steamcommunity.com/sharedfiles/filedetails/?id=3404179264
---------------------------------------------------------------------------*/








