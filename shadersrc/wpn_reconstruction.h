
// cEyePos in screenspace is messed up for obvious reasons
// quick hack to push it into our shader
#define cEyePos C0.xyz

float to_linear(float x) {
    return x * 4000;
}

float getProjPosZ(float2 uv) {
    return 1/to_linear(tex2Dlod(BASETEXTURE, float4(uv,0,0)).r) - 1;
}

/*
float3 reconstructPosition(float2 uv) {
    float2 uv_offset = uv * 2 - 1;
    float4 projPos = mul(float4(uv_offset.x, uv_offset.y, getProjPosZ(uv), 1), g_invViewProjMatrix);
    float3 world_pos = projPos.xyz/projPos.w;
    return world_pos;
}
*/

float3 reconstructPosition(float2 uv, float z)
{
    return mad( mul( float4( mad(uv, 2, -1), 0, 1), g_invViewProjMatrix ), z, cEyePos);
}

float3 reconstructPosition(float2 uv)
{
    return mad( mul( float4( mad(uv, 2, -1), 0, 1), g_invViewProjMatrix ), to_linear(tex2D(BASETEXTURE, uv).r), cEyePos);
}



