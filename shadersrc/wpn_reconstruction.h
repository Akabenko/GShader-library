#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);

const float4 C0     : register(c0); // xyz = cEyePos
const float4 C1     : register(c1);
const float4 C2     : register(c2);
const float4 C3     : register(c3);

float2 TexBaseSize : register( c4 );
float2 Tex1Size    : register( c5 );
float2 Tex2Size    : register( c6 );
float2 Tex3Size    : register( c7 );

const float4x4 g_viewProjMatrix : register( c11 );
const float4x4 g_invViewProjMatrix : register( c15 );

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv : TEXCOORD0;
};

// cEyePos in screenspace is messed up for obvious reasons
// quick hack to push it into our shader
#define cEyePos C0.xyz

#define zfar C0.w
#define znear C1.w

#define depth_dimensions C1.x

float to_linear(float x) {
    //return x * zfar + znear;    // spans 4000, znear of 1 (correct if wrong)
    return x * (zfar-znear) + znear;
}

float getRawDepth(float2 uv) { return (tex2Dlod(BASETEXTURE, float4(uv,0,0)).r) ; }

float3 reconstructPosition(float2 uv, float z)
{
    float2 uv_offset = uv;
    uv_offset = uv * 2 - 1;

    // get direction
    float3 world_pos = mul(float4(uv_offset.x, uv_offset.y, 0, 1), g_invViewProjMatrix).xyz;

    // normalize
    // usually you'd divide by znear but we setup the projection matrix in a way where z=0 is already normalized
    world_pos = world_pos * to_linear(z);
    // offset
    world_pos += cEyePos;
    return world_pos;
}

float3 reconstructPosition(float2 uv)
{
    float2 uv_offset = uv;
    float z = tex2D(BASETEXTURE, uv_offset).r;
    uv_offset = uv * 2 - 1;

    // get direction
    float3 world_pos = mul(float4(uv_offset.x, uv_offset.y, 0, 1), g_invViewProjMatrix).xyz;

    // normalize
    // usually you'd divide by znear but we setup the projection matrix in a way where z=0 is already normalized
    world_pos = world_pos * to_linear(z);
    // offset
    world_pos += cEyePos;
    return world_pos;
}

