#include "common_velocity_encoding.h"

sampler VelocityBuffer      : register(s0);
float2 texelSize            : register( c4 );

struct PS_INPUT
{
    float2 pPos                                 : VPOS;
    float4 vTexCoord                            : TEXCOORD0;
};

float4 main( PS_INPUT i ) : COLOR
{
    float2 ui = (i.pPos+0.5)*texelSize;
    float2 V = VelocityDecode(tex2D(VelocityBuffer,ui).ra);
    return float4(V,0,1);
}
