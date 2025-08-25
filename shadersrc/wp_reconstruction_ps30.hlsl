#include "wpn_reconstruction.h"

float4 main(PS_INPUT frag) : COLOR {
    float2 vpos = frag.P + 0.5;
    float2 uv = vpos*TexBaseSize;
    float depth = tex2D(BASETEXTURE, uv).r;
    float3 world_pos = reconstructPosition(uv, depth);

    return float4(1/world_pos, depth);
};

