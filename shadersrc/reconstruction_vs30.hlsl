
#include "common_vs_fxc.h"

struct VS_INPUT
{
    float4 vPos                     : POSITION;
    float2 uv                       : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 projPos                  : POSITION;
    float2 uv                       : TEXCOORD0;
    float3 fogParams                : TEXCOORD1;
};

VS_OUTPUT main( const VS_INPUT v )
{
    VS_OUTPUT o = ( VS_OUTPUT )0;
    float4 vProjPos = mul(  v.vPos, cViewProj );
    o.projPos = vProjPos;
    //o.projPos = v.vPos;
    o.uv = v.uv;
    o.fogParams = cFogParams.xwz;
    return o;
}
