// https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-27-motion-blur-post-processing-effect
#include "common_velocity_encoding.h"

sampler WPDepthBuffer           : register(s0);
const float2 g_velocityBlurParams : register( c0 );
float2 texelSize    : register( c4 );
const float4x4 g_previousViewProjectionMatrix : register( c11 );

struct PS_INPUT
{
    float2 pPos                                 : VPOS;
    float4 vTexCoord                            : TEXCOORD0;
};

float4 main( PS_INPUT i ) : COLOR
{
    float2 texCoord = (i.pPos+0.5)*texelSize;

    float4 wpndepth = tex2D(WPDepthBuffer,texCoord);

    //float zOverW = wpndepth.a;
    //if (zOverW == 1) discard;

    float4 worldPos = float4(1/wpndepth.xyz,1);

    float2 currentPos = texCoord * 2 - 1;

    float4 previousPos = mul(worldPos, g_previousViewProjectionMatrix);
    previousPos.xy /= previousPos.w;

    float2 V = (currentPos.xy - previousPos.xy) * g_velocityBlurParams;

    //encoding
    float2 V_enc = VelocityEncode(V);

    return float4(V_enc.x,0,0,V_enc.y);
}

// https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-27-motion-blur-post-processing-effect

