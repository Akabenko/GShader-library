

/*---------------------------------------------------------------------------
Octahedron normal vector encoding:  https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
Diamond Encoding:                   https://www.jeremyong.com/graphics/2023/01/09/tangent-spaces-and-diamond-encoding/

Reconstruction of normals:
https://wickedengine.net/2019/09/improved-normal-reconstruction-from-depth/
https://gist.github.com/bgolus/a07ed65602c009d5e2f753826e8078a0
https://atyuwen.github.io/posts/normal-reconstruction/

Shaderlib authors: Meetric, Akabenko
---------------------------------------------------------------------------*/
local shaderName = "Reconstruction"
local mat_smooth = Material("pp/normal_smooth")

local function InitReconstruction()
    local wn_formats = {
        [0] = IMAGE_FORMAT_RGBA16161616F;
        [1] = IMAGE_FORMAT_RGBA32323232F;
        [2] = IMAGE_FORMAT_RGB888;
    }

    function shaderlib.GetWorldNormalsImageFormat()
        return wn_formats[GetConVar("r_shaderlib_wn_format"):GetInt()]
    end

    shaderlib.rt_WPDepth = GetRenderTargetEx("_rt_WPDepth", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 8388608),
        0,
        IMAGE_FORMAT_RGBA32323232F
    )

    shaderlib.rt_NormalsTangents = GetRenderTargetEx("_rt_NormalsTangents", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 8388608),
        0,
        shaderlib.GetWorldNormalsImageFormat()
    )

    shaderlib.rt_Bump = GetRenderTargetEx("_rt_BumpFog", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4,8,16,256,512,8388608),
        0, 
        IMAGE_FORMAT_RGBA8888
    )

    local wp_reconst_mat = Material("pp/wp_reconstruction")
    shaderlib.mat_wpndepth      = shaderlib.mat_wpndepth or Material("pp/wpn_reconstruction_improved")

    local rt_blacklist = {
        ["_rt_waterreflection"] = true,
        ["_rt_waterrefraction"] = true,
        // arc9 rt
        ["arc9_gunscreen"] = true, 
        ["arc9_pipscope"] = true,
        ["arc9_rtmat_spare"] = true,
        ["arc9_cammat"] = true,
        // arccw
        ["arccw_rtmat"] = true,
        ["arccw_rtmat_cheap"] = true,
        ["arccw_rtmat_spare"] = true,
    }

    if TFA then
        local qualitySizes = {}

        local function InitTFAScopes()
            local h = ScrH()
            qualitySizes = {
                [0] = h,
                [1] = math.Round(h * 0.5),
                [2] = math.Round(h * 0.25),
                [3] = math.Round(h * 0.125),
            }

            for i = 0,3 do
                rt_blacklist[ "tfa_rt_screeno_"..qualitySizes[i] ] = true
            end
        end

        hook.Add("OnScreenSizeChanged", shaderName, InitTFAScopes)

        InitTFAScopes()
    end

    local EyePos = EyePos
    local render = render
    local PushRenderTarget = render.PushRenderTarget
    local rClear = render.Clear
    local PopRenderTarget = render.PopRenderTarget
    local SetMaterial = render.SetMaterial
    local SetRenderTargetEx = render.SetRenderTargetEx
    local GetRenderTarget = render.GetRenderTarget
    local GetViewSetup = render.GetViewSetup

    local screentexture = render.GetScreenEffectTexture()

    local function get_view_proj_matrix(viewSetup)
        local F = -viewSetup.angles:Forward()
        local R =  viewSetup.angles:Right()
        local U = -viewSetup.angles:Up() 

        local mViewAng = Matrix({
            {R.x, R.y, R.z, 0},
            {U.x, U.y, U.z, 0},
            {F.x, F.y, F.z, 0},
            {0,   0,   0,   1},
        })

        -- avoid calculating position offset within shader
        -- this aliviates precision issues and takes less compute
        -- we offset it later within the shader
        /*
        local P = -viewSetup.origin
        local mViewPos = Matrix({
            {1, 0, 0, P.x},
            {0, 1, 0, P.y},
            {0, 0, 1, P.z},
            {0, 0, 0, 1  },
        })*/

        -- mProj = mProj * (mViewAng * mViewPos)
        --mViewAng:Mul(mViewPos)

        local mProj = shaderlib.GetProjMatrix(viewSetup)
        mProj:Mul(mViewAng)
        return mProj
    end

    local avableViewIds = {
        [0] = true;
        [4] = true; -- underwater
    }

    function shaderlib.CanDrawEffects(viewSetup)
        viewSetup = viewSetup or render.GetViewSetup(false)

        local rt = GetRenderTarget()
        if rt then
            local rt_name = rt:GetName()
            --print(rt_name)
            --if string.find(rt_name, "portal") then return false end

            if rt_blacklist[rt_name] then
                return false
            end
        end

        if viewSetup.id and !avableViewIds[viewSetup.id] then return false end

        return true
    end

    function shaderlib.DrawReconstruction(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
        if isDrawSkybox then return end
        if isDraw3DSkybox then return end
        if isDrawingDepth then return end

        local viewSetup = GetViewSetup(false)
        if !shaderlib.CanDrawEffects(viewSetup) then return end
        
        hook.Run("PreDrawReconstruction")

        if NikNaks then -- https://github.com/Facepunch/garrysmod-requests/issues/2979
            wp_reconst_mat:SetFloat("$c1_x", NikNaks.CurrentMap:GetSkyBoxScale())
        end

        shaderlib.mat_wpndepth:SetFloat("$c3_y", render.GetFogMode() - 1)

        local inv_mat = get_view_proj_matrix(viewSetup):GetInverse() --:GetTransposed()
        wp_reconst_mat:SetMatrix("$INVVIEWPROJMAT", inv_mat )
        shaderlib.mat_wpndepth:SetMatrix("$INVVIEWPROJMAT", inv_mat )

        local eyepos = EyePos()

        wp_reconst_mat:SetFloat("$c0_x", eyepos.x)
        wp_reconst_mat:SetFloat("$c0_y", eyepos.y)
        wp_reconst_mat:SetFloat("$c0_z", eyepos.z)

        render.UpdateScreenEffectTexture()
        render.CopyRenderTargetToTexture(screentexture)

        cam.Start2D()
            render.PushRenderTarget(shaderlib.rt_WPDepth)
                render.Clear(0,0,0,0,true)
                SetMaterial(wp_reconst_mat)
                render.DrawScreenQuad()

                -- we can render here box with worldpos coords
                
            PopRenderTarget()


            --[[
            render.PushRenderTarget(shaderlib.rt_NormalsTangents) render.Clear(0,0,0,0,true) PopRenderTarget()
            render.PushRenderTarget(shaderlib.rt_Bump) render.Clear(128,128,255,0,true) PopRenderTarget()
            ]]

            render.PushRenderTarget(shaderlib.rt_NormalsTangents)  render.Clear(0,0,0,0) PopRenderTarget()
            render.PushRenderTarget(shaderlib.rt_Bump) render.Clear(128,128,255,0) PopRenderTarget()

            local rt0 = render.GetRenderTarget()

            render.SetRenderTargetEx(0, shaderlib.rt_NormalsTangents)
            render.SetRenderTargetEx(1, shaderlib.rt_Bump)
 
            /*---------------------------------------------------------------------------
            Encode Normals using «Octahedron normal vector encoding»; Tangents using «Diamond Encoding».
            .RG - Normals, .B - Tangents, .A - sign.
            ---------------------------------------------------------------------------*/

            SetMaterial(shaderlib.mat_wpndepth)
            shaderlib.DrawScreenQuad() // use Multy Render Target, need custom function to DrawScreenQuad

            render.SetRenderTargetEx(1)

            if shaderlib.normals_smooth then
                SetMaterial(mat_smooth)
                render.DrawScreenQuad()
            end

            render.SetRenderTargetEx(0, rt0)
        cam.End2D()

        local ViewProj = shaderlib.GetViewProjMatrix(viewSetup)
        local ViewProjTransposed = ViewProj:GetTransposed()

        hook.Run("PostDrawReconstruction", viewSetup, ViewProj, ViewProjTransposed)
        hook.Run("PostDrawReconstructionPreEffects", viewSetup, ViewProj, ViewProjTransposed)
        hook.Run("PostDrawReconstructionLighting", viewSetup, ViewProj, ViewProjTransposed)
        hook.Run("PostDrawReconstructionEffects", viewSetup, ViewProj, ViewProjTransposed)
    end
end

hook.Add("InitReconstruction", shaderName, InitReconstruction)



