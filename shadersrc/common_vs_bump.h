#include "common_vs_fxc.h"
#include "shader_constant_register_map.h"

struct VS_INPUT
{
    float4 vPos                         : POSITION;
    float2 vTexCoord                    : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 vProjPos_POSITION    : POSITION;
    float3 vTexCoord			: TEXCOORD0;
    float2 projPosZ_projPosW    : TEXCOORD1;
};

VS_OUTPUT main( const VS_INPUT v )
{
    VS_OUTPUT o = ( VS_OUTPUT )0;

    float3 worldPos = mul4x3( v.vPos, cModel[0] );
    float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
    o.vProjPos_POSITION = vProjPos;

    float pixelFogFactor = RangeFog( vProjPos.xyz ); // 1 - число
    o.vTexCoord = float3( v.vTexCoord, pixelFogFactor );
    o.projPosZ_projPosW = vProjPos.zw;
    
    return o;
}
