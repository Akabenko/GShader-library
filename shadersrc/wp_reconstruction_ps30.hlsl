sampler BASETEXTURE     : register(s0);

const float4 C0     : register(c0); // xyz = cEyePos
const float scale   : register(c1);
float2 TexBaseSize : register( c4 );
const float4x4 g_invViewProjMatrix              : register( c15 );

#include "wpn_reconstruction.h"

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv           : TEXCOORD0;
};

float4 main(PS_INPUT frag) : COLOR0 {
    float2 uv = (frag.P + 0.5)*TexBaseSize;
    float depth = tex2D(BASETEXTURE, uv).r;
    depth = to_linear(depth);
    return 1/float4( reconstructPosition(uv, depth), depth );
};
