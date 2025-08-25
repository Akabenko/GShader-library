
/*---------------------------------------------------------------------------
Octahedron normal vector encoding:  https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
Diamond Encoding:                   https://www.jeremyong.com/graphics/2023/01/09/tangent-spaces-and-diamond-encoding/

Reconstruction of normals:
https://wickedengine.net/2019/09/improved-normal-reconstruction-from-depth/
https://gist.github.com/bgolus/a07ed65602c009d5e2f753826e8078a0

Shaderlib authors: Meetric, Akabenko
---------------------------------------------------------------------------*/

local shaderName = "Reconstruction"

local function InitReconstruction()
    function shaderlib.GetWorldPosImageFormat()
        --return (GetConVar("r_shaderlib_wp_format"):GetInt() == 1 and D3D9EX) and IMAGE_FORMAT_RGBA32323232F or IMAGE_FORMAT_RGBA16161616F
        return (GetConVar("r_shaderlib_wp_format"):GetInt() == 1) and IMAGE_FORMAT_RGBA32323232F or IMAGE_FORMAT_RGBA16161616F
    end

    function shaderlib.GetWorldNormalsImageFormat()
        --return (GetConVar("r_shaderlib_wn_format"):GetInt() == 1 and D3D9EX) and IMAGE_FORMAT_RGBA32323232F or IMAGE_FORMAT_RGBA16161616F
        return (GetConVar("r_shaderlib_wn_format"):GetInt() == 1) and IMAGE_FORMAT_RGBA32323232F or IMAGE_FORMAT_RGBA16161616F
    end

    shaderlib.rt_WPDepth = GetRenderTargetEx("_rt_WPDepth", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 8388608),
        0,
        shaderlib.GetWorldPosImageFormat()
    )

    shaderlib.rt_NormalsTangents = GetRenderTargetEx("_rt_NormalsTangents", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 8388608),
        0,
        shaderlib.GetWorldNormalsImageFormat()
    )

    shaderlib.mat_wpndepth      = shaderlib.mat_wpndepth or Material("pp/wpn_reconstruction_improved")
    local mat_wpndepth_smooth   = Material("pp/normals_smooth")
    local mat_wp_depth          = Material("pp/wp_reconstruction")
    local tangets               = Material("pp/encode_normals_tangents")

    local Matrix = Matrix

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

    local rt_blacklist = {
        ["_rt_waterreflection"] = true,
        ["_rt_waterrefraction"] = true,
    }

    local EyePos = EyePos
    local render = render
    local PushRenderTarget = render.PushRenderTarget
    local rClear = render.Clear
    local PopRenderTarget = render.PopRenderTarget
    local SetMaterial = render.SetMaterial
    local DrawScreenQuad = render.DrawScreenQuad
    local SetRenderTargetEx = render.SetRenderTargetEx
    local GetRenderTarget = render.GetRenderTarget
    local GetViewSetup = render.GetViewSetup

    function shaderlib.DrawReconstruction(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
        if isDrawSkybox then return end
        if isDraw3DSkybox then return end
        if isDrawingDepth then return end
        if bDrawCSM then return end

        local rt = GetRenderTarget()

        if rt and rt_blacklist[rt:GetName()]  then
           return
        end

        local viewSetup = GetViewSetup(false)
        viewSetup.znear = 1// 7
        viewSetup.zfar = 4000 // spans 4000, znear of 1 (correct if wrong)

        local ViewProj = get_view_proj_matrix(viewSetup)
        ViewProj:Invert()

        shaderlib.mat_wpndepth:SetMatrix("$INVVIEWPROJMAT", ViewProj)
        shaderlib.mat_wpndepth:SetFloat("$c0_w", viewSetup.zfar)
        shaderlib.mat_wpndepth:SetFloat("$c1_w", viewSetup.znear)

        local eyePos = EyePos()

        shaderlib.mat_wpndepth:SetFloat("$c0_x", eyePos.x)
        shaderlib.mat_wpndepth:SetFloat("$c0_y", eyePos.y)
        shaderlib.mat_wpndepth:SetFloat("$c0_z", eyePos.z)
    
        cam.Start2D()
            if shaderlib.mrt_enabled then
                PushRenderTarget(shaderlib.rt_NormalsTangents) rClear(0,0,0,0) PopRenderTarget()
                PushRenderTarget(shaderlib.rt_WPDepth) rClear(0,0,0,0) PopRenderTarget()

                SetRenderTargetEx(0, shaderlib.rt_NormalsTangents)
                SetRenderTargetEx(1, shaderlib.rt_WPDepth) // .RGB - 1/WorldPos, .A - Depth from render.GetResolvedFullFrameDepth()
                
                SetMaterial(shaderlib.mat_wpndepth) 
                shaderlib.DrawScreenQuad() // use Multy Render Target, need custom function to DrawScreenQuad

                if shaderlib.normals_smooth then
                    SetMaterial(mat_wpndepth_smooth) // 3x3 filer; smooth normals -> tangets
                    DrawScreenQuad()
                end

                /*---------------------------------------------------------------------------
                Encode Normals using «Octahedron normal vector encoding»; Tangents using «Diamond Encoding».
                .RG - Normals, .B - Tangents, .A - sign.
                ---------------------------------------------------------------------------*/
                SetMaterial(tangets)
                DrawScreenQuad()

                SetRenderTargetEx(0)
                SetRenderTargetEx(1)
            else
                --non mrt reconstruction
                mat_wp_depth:SetMatrix("$INVVIEWPROJMAT", ViewProj)
                mat_wp_depth:SetMatrix("$VIEWPROJMAT", shaderlib.GetViewProjMatrix(viewSetup))
                mat_wp_depth:SetFloat("$c0_w", viewSetup.zfar)
                mat_wp_depth:SetFloat("$c1_w", viewSetup.znear)
                mat_wp_depth:SetFloat("$c0_x", eyePos.x)
                mat_wp_depth:SetFloat("$c0_y", eyePos.y)
                mat_wp_depth:SetFloat("$c0_z", eyePos.z)

                PushRenderTarget(shaderlib.rt_NormalsTangents)
                    rClear(0,0,0,0)

                    SetMaterial(shaderlib.mat_wpndepth) 
                    DrawScreenQuad()

                    if shaderlib.normals_smooth then
                        SetMaterial(mat_wpndepth_smooth) // 3x3 filer; smooth normals -> tangets
                        DrawScreenQuad()
                    end

                    SetMaterial(tangets)
                    DrawScreenQuad()
                PopRenderTarget()

                PushRenderTarget(shaderlib.rt_WPDepth)
                    rClear(0,0,0,0)
                    SetMaterial(mat_wp_depth)
                    DrawScreenQuad()
                PopRenderTarget()
            end

            hook.Run("PostDrawReconstruction", viewSetup)
        cam.End2D()
    end
end

hook.Add("InitReconstruction", shaderName, InitReconstruction)
