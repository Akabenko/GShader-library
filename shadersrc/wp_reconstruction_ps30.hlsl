
sampler BASETEXTURE     : register(s0);
sampler DepthSkyBuffer  : register(s1);

const float4 C0     : register(c0); // xyz = cEyePos
const float scale   : register(c1);
float2 TexBaseSize : register( c4 );
const float4x4 g_invViewProjMatrix              : register( c15 );

#include "wpn_reconstruction.h"

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv           : TEXCOORD0;
};

float4 main(PS_INPUT frag) : COLOR
{
    float2 uv = (frag.P + 0.5)*TexBaseSize;

    float depth = tex2Dlod(BASETEXTURE, float4(uv,0,0)).r;
    float depth_sky = tex2Dlod(DepthSkyBuffer, float4(uv,0,0)).r;
    
    depth = lerp(
        depth, 
        lerp(depth_sky * scale, 1.0, float(depth_sky == 1.0)),
        float(depth == 1.0)
    );

    //depth = (depth == 1.0) ? (tex2Dlod(DepthSkyBuffer, uv).r * scale) : depth;

    depth = to_linear(depth);

    return 1/float4( reconstructPosition(uv, depth), depth );
};
