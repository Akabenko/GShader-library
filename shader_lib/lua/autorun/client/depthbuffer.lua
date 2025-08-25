

local libname = "shaderlib"

local function UpgradeDepthBuffer()
    // This is an improvement of the depth buffer image format. The standard image format is: IMAGE_FORMAT_RGBA8888
    // Thanks to notunknowndude for the idea of a way to upgrade the depth buffer.

    GetRenderTargetEx( render.GetResolvedFullFrameDepth():GetName(), ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        --MATERIAL_RT_DEPTH_SHARED, --MATERIAL_RT_DEPTH_NONE
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 65536),
        0,
        --render.GetDXLevel() == 92 and IMAGE_FORMAT_RGBA32323232F or ( D3D9EX and IMAGE_FORMAT_R32F or IMAGE_FORMAT_RGBA16161616F )
        render.GetDXLevel() == 92 and IMAGE_FORMAT_RGBA32323232F or IMAGE_FORMAT_R32F
    )

    /*---------------------------------------------------------------------------
    Selecting the image format of the depth buffer:

    IMAGE_FORMAT_R32F not works on Linux (dx 92).
    IMAGE_FORMAT_RGBA32323232F not works without d3d9ex (mat_disable_d3d9ex 0)

    Best format for depth buffer is IMAGE_FORMAT_R32F. 

    But if it is not available to us, then we preserve the quality of the depth buffer,
    leaving 32 Bit, but use the IMAGE_FORMAT_RGBA32323232F format, which costs more video memory.
    We sacrifice it for the sake of the quality of the depth buffer.

    If d3d9ex is not available, then we use at least 16 bit, but the IMAGE_FORMAT_R16F bit format does
    not work (ShaderAPIDX8::CreateD3DTexture: Invalid color format!). So we use IMAGE_FORMAT_RGBA16161616F.
    But it's still twice as good as the standard image format.
    ---------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------------
    About the depth buffer render.GetResolvedFullFrameDepth() (_rt_resolvedfullframedepth):

    Before increasing the bit depth of the depth buffer, it worked at a distance of 4000.
    In the shader, the depth at >=4000 units was equal to 1 in the shader.

    After upgrading the depth buffer from IMAGE_FORMAT_RGBA8888 to IMAGE_FORMAT with floating point format,
    it started writing numbers above >1. It began to record depth at a distance of >4000 units, namely the entire scene. 
    Now it turns out that the distance of 0 — 4000 units is from 0 to 1, 4000 — 8000 units from 1 to 2 and so on.

    In this case the sky is equal to exactly depth == 1:
    if (tex2D(DepthBuffer,uv).r) == 1 discard;
    Although on other engines, the check is done by  depth >= 1.
    ---------------------------------------------------------------------------*/

    hook.Add("NeedsDepthPass", libname, function()
        if bDrawCSM or bDrawSnowMap then return false end
        return true
    end)

    /*---------------------------------------------------------------------------
    When rendering a shadow map, artifacts may appear with the scene when NeedsDepthPass return true.
    That's why we output return false when rendering CSM or any other scene renders.
    
    FIX:
    bDrawCSM = true
    render.RenderView(viewSetup)
    bDrawCSM = false
    ---------------------------------------------------------------------------*/
end

hook.Add("InitPostShaderlib", libname, UpgradeDepthBuffer)

