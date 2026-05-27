// Code by LaVashik
// tex: Data sampler (LUT)
// coord: Integer coordinates [x, y]
// texelSize: Texel size [1 / width, 1 / height]
// return: Raw data (Float32)
float4 LoadLUT(sampler tex, int2 coord, float2 texelSize)
{
    float2 uv = (coord + 0.5) * texelSize;
    return tex2Dlod(tex, float4(uv, 0, 0));
}

float4 LoadLUT(sampler2D tex, int2 coord, float2 texelSize)
{
    float2 uv = (coord + 0.5) * texelSize;
    return tex2Dlod(tex, float4(uv, 0, 0));
}

float4 LoadLUT(sampler1D tex, int coord, float texelSize)
{
    float2 u = (coord + 0.5) * texelSize;
    return tex1Dlod(tex, float4(u, 0, 0));
}
