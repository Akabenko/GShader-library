#include "common_diamond_encoding.h"
#include "common_octahedron_encoding.h"

sampler NormalTangetBuffer  : register(s0);
float2 TexBaseSize : register( c4 );

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv : TEXCOORD0;
};

struct PS_OUTPUT {
    float4 color0 : COLOR0;
    float4 color1 : COLOR1;
};

PS_OUTPUT main(PS_INPUT frag) {
    PS_OUTPUT o = (PS_OUTPUT)0;

    float2 uv = (frag.P + 0.5)*TexBaseSize;

    float4 normal_tanget = tex2D(NormalTangetBuffer,uv);
    
    float3 world_normal = Decode(normal_tanget.xy);
    float3 tangets = decode_tangent(world_normal, normal_tanget.z);

    o.color0 = float4(world_normal, 1);
    o.color1 = float4(tangets, normal_tanget.a);

    return o;
};

