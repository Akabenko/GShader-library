# GShader library
— a shader library that serves as the foundation for creating [Deferred Renderer (shading & lighting)](https://developer.valvesoftware.com/wiki/Deferred_renderer) shaders, acting as a convenient tool for creating advanced post-processing effects.

### List of textures in the addon:
*  `_rt_WPDepth`
* `_rt_NormalsTangents`
* `_rt_BumpFog`
* `_rt_ResolvedFullFrameDepth`

### The addon includes:
* Reconstruction of WorldPos, WorldNormals and Tangents from `_rt_ResolvedFullFrameDepth`.
* Normal smoothing (BETA).
* Increasing the bit depth of the depth buffer `_rt_ResolvedFullFrameDepth`.
* View and projection matrices: View, Proj, ViewProj. For perspective and orthogonal projection.
* Newly discovered texture formats that allow more flexible work with shaders.
* Encoding Normals and Tangents into a single texture, packing WorldPos and Depth, which will fit within the 4-texture limit in [screenspace_general](https://developer.valvesoftware.com/wiki/Screenspace_General).
* Choice of [normal reconstruction method](https://wickedengine.net/2019/09/improved-normal-reconstruction-from-depth/): Simple, [3 Tap, 4 Tap, Improved](https://gist.github.com/bgolus/a07ed65602c009d5e2f753826e8078a0), [Accurate](https://atyuwen.github.io/posts/normal-reconstruction/).
* Function `shaderlib.DrawScreenQuad()` with Multiple Render Target support.
* Function `shaderlib.DrawVertexScreenQuad()` with input data to vertex shader and MRT support. More info here: [Example 6](https://github.com/meetric1/gmod_shader_guide/blob/main/lua/autorun/client/shader_examples.lua).

### Encoding Normals and Tangents
Normals and Tangents are stored in the render target `_rt_NormalsTangents`, where:
* `.RG` — Normals
* `.B`  — Tangents
* `.A` — Sign: A value of `1` or `-1`. It will help you with lighting and creating Post-Process Parallax Mapping.

Normals are encoded using [Octahedron normal vector encoding](https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/)
Normal decoding is done via the function:
```hlsl
float3 Decode(float2 f)
{
    f = f * 2.0 - 1.0;

    // https://twitter.com/Stubbesaurus/status/937994790553227264
    float3 n = float3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = saturate(-n.z);
    n.xy += n.xy >= 0.0 ? -t : t;
    return normalize(n);
}
```
Tangents are encoded using [Diamond Encoding](https://www.jeremyong.com/graphics/2023/01/09/tangent-spaces-and-diamond-encoding/).
Function of getting tangents based on [thexa4](https://github.com/thexa4/source-pbr/blob/b8c4b76882241ea8cb506e89a61a1f5448d24e71/mp/src/materialsystem/stdshaders/pbr_common_ps2_3_x.h#L63) function.
Tangent decoding is done via the function:
```hlsl
float2 decode_diamond(float p)
{
    float2 v;

    // Remap p to the appropriate segment on the diamond
    float p_sign = sign(p - 0.5f);
    v.x = -p_sign * 4.f * p + 1.f + p_sign * 2.f;
    v.y = p_sign * (1.f - abs(v.x));

    // Normalization extends the point on the diamond back to the unit circle
    return normalize(v);
}

float3 decode_tangent(float3 normal, float diamond_tangent)
{
    // As in the encode step, find our canonical tangent basis span(t1, t2)
    float3 t1;
    if (abs(normal.y) > abs(normal.z))
    {
        t1 = float3(normal.y, -normal.x, 0.f);
    }
    else
    {
        t1 = float3(normal.z, 0.f, -normal.x);
    }
    t1 = normalize(t1);

    float3 t2 = cross(t1, normal);

    // Recover the coordinates used with t1 and t2
    float2 packed_tangent = decode_diamond(diamond_tangent);

    return packed_tangent.x * t1 + packed_tangent.y * t2;
}
```

### Example of working with  _rt_NormalsTangents:
```hlsl
float4 normals_tangets = tex2D(NormalTangentBuffer,uv);
float flipSign = normals_tangets.a;
float3 worldNormal = Decode(normals_tangets.xy);
float3 tangents = decode_tangent(worldNormal, normals_tangets.z);
float3 binormals = normalize(cross(worldNormal,tangents))* flipSign;

float3x3 TBN = float3x3(tangents, binormals, worldNormal);
```

### Packing WorldPos and Depth
WorldPos and Depth are stored in the render target `_rt_WPDepth`, where:
* `.RGB` — `1/WorldPos`: This means that WorldPos is packed into values <1. To unpack, use `float3 worldPos = 1/tex2D(WPDepthBuffer,uv).xyz;` in the shader.
* `.A` — Depth

### _rt_BumpFog
Normals and Tangents are stored in the render target `_rt_NormalsTangents`, where:
* `.RGB` — Reconstructed bumps from FrameBuffer
* `.A`  — Inverted Fog

### Velocity Buffer
Encoding based on method of CryTeck CryEngine 3 — [Advances in Real-Time Rendering cource](https://advances.realtimerendering.com/s2013/index.html). [Implementation by LVutner](https://github.com/Akabenko/GShader-library/blob/main/shadersrc/common_velocity_encoding.h).
* `.R` — X velocity.
* `.A` — Y velocity.

[Velocity buffer decoding sample](https://github.com/Akabenko/GShader-library/blob/main/shadersrc/velocity_buffer_decode_ps30.hlsl)

### NOTE:
 The depth buffer does not write translucent objects, so you will most likely render shaders in the [PreDrawTranslucentRenderables](url=https://wiki.facepunch.com/gmod/GM:PreDrawTranslucentRenderables) hook.

### Special thanks to:
* [Meetric](https://github.com/meetric1) — WorldPos reconstruction.
* notunknowndude — the idea to improve the depth buffer.
* puwada — the tip about texture format compatibility and DirectX.
* [LVutner](https://github.com/LVutner?tab=repositories)  — implementation Velocity Buffer encoding based on CryTeck method.
* [Zaurzo](https://gist.github.com/Zaurzo)  — creating DynamicLight Wrapper.


### Links:
* [GShaders discord](https://discord.gg/JVbhYEZAmQ)
* [Beginner's shader guide](https://github.com/ficool2/sdk_screenspace_shaders)
* [Shader creation basics](https://github.com/meetric1/gmod_shader_guide/tree/main)
* [EGSM - here are some shader examples that might be useful](https://github.com/devonium/EGSM/wiki/example_shaders)


