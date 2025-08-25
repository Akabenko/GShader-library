#include "wpn_reconstruction.h"

struct PS_OUTPUT {
    float4 color0 : COLOR0;
    float4 color1 : COLOR1;
};

PS_OUTPUT main(PS_INPUT frag) {
    PS_OUTPUT o = (PS_OUTPUT)0;

    float2 vpos = frag.P + 0.5;
    float2 uv = vpos*TexBaseSize;
    float depth = tex2D(BASETEXTURE, uv).r;

    float3 world_normal;
    float3 world_pos = reconstructPosition(uv, depth);

    #if defined(_RECONSTRUCTIONMETHOD_3_TAP)
        float2 uv1 = (vpos + float2(1, 0) * depth_dimensions)*TexBaseSize; // right 
        float2 uv2 = (vpos + float2(0, 1) * depth_dimensions)*TexBaseSize; // top

        float3 P1 = reconstructPosition(uv1);
        float3 P2 = reconstructPosition(uv2);

        world_normal = normalize(cross(P2 - world_pos, P1 - world_pos));
    #elif defined(_RECONSTRUCTIONMETHOD_4_TAP)
        // get view space position at 1 pixel offsets in each major direction
        float3 viewSpacePos_l = reconstructPosition( (vpos + float2(-1.0, 0.0))*TexBaseSize );
        float3 viewSpacePos_r = reconstructPosition( (vpos + float2( 1.0, 0.0))*TexBaseSize );
        float3 viewSpacePos_d = reconstructPosition( (vpos + float2( 0.0,-1.0))*TexBaseSize );
        float3 viewSpacePos_u = reconstructPosition( (vpos + float2( 0.0, 1.0))*TexBaseSize );

        // get the difference between the current and each offset position
        float3 hDeriv = viewSpacePos_r - viewSpacePos_l;
        float3 vDeriv = viewSpacePos_u - viewSpacePos_d;

        // get view space normal from the cross product of the diffs
        world_normal = -normalize(cross(hDeriv, vDeriv));
    #elif defined(_RECONSTRUCTIONMETHOD_IMPROVED)
        // get view space position at 1 pixel offsets in each major direction
        float3 viewSpacePos_l = reconstructPosition( (vpos + float2(-1.0, 0.0) )*TexBaseSize );
        float3 viewSpacePos_r = reconstructPosition( (vpos + float2( 1.0, 0.0) )*TexBaseSize );
        float3 viewSpacePos_d = reconstructPosition( (vpos + float2( 0.0,-1.0) )*TexBaseSize );
        float3 viewSpacePos_u = reconstructPosition( (vpos + float2( 0.0, 1.0) )*TexBaseSize );

        // get the difference between the current and each offset position
        float3 l = world_pos - viewSpacePos_l;
        float3 r = viewSpacePos_r - world_pos;
        float3 d = world_pos - viewSpacePos_d;
        float3 u = viewSpacePos_u - world_pos;

        // pick horizontal and vertical diff with the smallest z difference
        float3 hDeriv = abs(l.z) < abs(r.z) ? l : r;
        float3 vDeriv = abs(d.z) < abs(u.z) ? d : u;

        // get view space normal from the cross product of the two smallest offsets
        world_normal = -normalize(cross(hDeriv, vDeriv));
    #elif defined(_RECONSTRUCTIONMETHOD_ACCURATE)
        // based on Yuwen Wu's Accurate Normal Reconstruction 
        // https://atyuwen.github.io/posts/normal-reconstruction/
        // basically as accurate as you can get!
        // no artifacts on depth disparities
        // no artifacts on edges
        // artifacts on triangles that are <3 pixels across

        // unity's compiled fragment shader stats: 66 math, 9 tex

        // get view space position at 1 pixel offsets in each major direction

        float2 uv1 = (vpos + float2(-1.0, 0.0) )*TexBaseSize;
        float2 uv2 = (vpos + float2( 1.0, 0.0) )*TexBaseSize;
        float2 uv3 = (vpos + float2( 0.0,-1.0) )*TexBaseSize;
        float2 uv4 = (vpos + float2( 0.0, 1.0) )*TexBaseSize;

        float3 viewSpacePos_l = reconstructPosition( uv1 );
        float3 viewSpacePos_r = reconstructPosition( uv2 );
        float3 viewSpacePos_d = reconstructPosition( uv3 );
        float3 viewSpacePos_u = reconstructPosition( uv4 );

        // get the difference between the current and each offset position
        float3 l = world_pos - viewSpacePos_l;
        float3 r = viewSpacePos_r - world_pos;
        float3 d = world_pos - viewSpacePos_d;
        float3 u = viewSpacePos_u - world_pos;

        // get depth values at 1 & 2 pixels offsets from current along the horizontal axis
        float4 H = half4(
            getRawDepth( uv1 ),
            getRawDepth( uv2 ),
            getRawDepth( (vpos + float2(-2.0, 0.0) )*TexBaseSize),
            getRawDepth( (vpos + float2( 2.0, 0.0) )*TexBaseSize)
        );

        // get depth values at 1 & 2 pixels offsets from current along the vertical axis
        float4 V = half4(
            getRawDepth( uv3 ),
            getRawDepth( uv4 ),
            getRawDepth( (vpos + float2(0.0,-2.0) )*TexBaseSize),
            getRawDepth( (vpos + float2(0.0, 2.0) )*TexBaseSize)
        );

        // current pixel's depth difference from slope of offset depth samples
        // differs from original article because we're using non-linear depth values
        // see article's comments
        float2 he = abs((2 * H.xy - H.zw) - depth);
        float2 ve = abs((2 * V.xy - V.zw) - depth);

        // pick horizontal and vertical diff with the smallest depth difference from slopes
        float3 hDeriv = he.x < he.y ? l : r;
        float3 vDeriv = ve.x < ve.y ? d : u;

        // get view space normal from the cross product of the best derivatives
        world_normal = -normalize(cross(hDeriv, vDeriv));
    #else
        // normals calculation for the hell of it
        // dont reference this code!!!!! ddx is imprecise and has poor edge continuity
        world_normal = normalize(cross(ddy(world_pos), ddx(world_pos)));
    #endif

    o.color0 = float4(world_normal, 1.0);
    o.color1 = float4(1/world_pos, depth);

    return o;
};

/*
Reconstruction of normals:
https://wickedengine.net/2019/09/improved-normal-reconstruction-from-depth/
https://gist.github.com/bgolus/a07ed65602c009d5e2f753826e8078a0
https://atyuwen.github.io/posts/normal-reconstruction/
*/


