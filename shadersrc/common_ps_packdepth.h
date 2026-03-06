// https://stackoverflow.com/questions/48288154/pack-depth-information-in-a-rgba-texture-using-mediump-precison

static const float f256_256 = (256.0*256.0);
static const float f256_256_256 = (f256_256*256.0);
static const float f256_256_1 = (f256_256-1);
static const float3 inv3_256 = 1.0 / float3(1.0, 256.0, f256_256);
static const float f256_256_256_1 = (f256_256_256 - 1.0);
static const float inv_512 = 1.0/512.0;
static const float f256_256_256_div1 = f256_256_256 / f256_256_256_1;
static const float f256_256_div1 = f256_256 / f256_256_1;
static const float f256_256_1_div = f256_256_1 / f256_256;
static const float f256_256_256_1_div = f256_256_256_1 / f256_256_256;
static const float2 inv_256_2 = 1.0 / float2(1.0, 256.0);
static const float4 f256_4 = float4(1.0, 256.0, f256_256, f256_256_256);
static const float4 inv_f256_4 = 1/f256_4;
static const float3 f3_256 = float3(1.0, 256.0, f256_256);

half2 PackDepth16( in float depth )
{
    float depthVal = depth * f256_256_1_div;
    float3 encode = frac( depthVal * f3_256 );
    return encode.xy - encode.yz / 256.0 + inv_512;
}

half UnpackDepth16( in float2 pack )
{
    float depth = dot( pack, inv_256_2 );
    return depth * f256_256_div1;
}

half3 PackDepth24( in float depth )
{
    float depthVal = depth * f256_256_256_1_div;
    float4 encode = frac( depthVal * f256_4 );
    return encode.xyz - encode.yzw / 256.0 + inv_512;
}

float UnpackDepth24( in float3 pack )
{
  float depth = dot( pack, inv3_256 );
  return depth * f256_256_256_div1;
}

half4 PackDepth32( in float depth )
{
    depth *= f256_256_256_1_div;
    float4 encode = frac( depth * f256_4 );
    return float4( encode.xyz - encode.yzw / 256.0, encode.w ) + inv_512;
}

float UnpackDepth32( in float4 pack )
{
    float depth = dot( pack, inv_f256_4 );
    return depth * f256_256_256_div1;
}

