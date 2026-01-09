#include "common_octahedron_encoding.h"
#include "common_diamond_encoding.h"

sampler NormalsBuffer       : register(s0);
sampler WPDepthBuffer       : register(s1);
sampler BlueNoise           : register(s2);

struct PS_INPUT
{
	float2 pPos					: VPOS;
	float4 vTexCoord			: TEXCOORD0;
};

const float maxFilterSize                   : register( c0 ); 
const float4 Constant1                  : register( c1 );

#define projectedParticleConstant   Constant1.x
#define depthThreshold              Constant1.y
#define blurDir                     Constant1.zw
const float4 Constant3                                    : register( c3 );

#define sigma_normal Constant3.x

float2 TexBaseSize              : register( c4 );

float wy_sq_cashed(float sgma, float distance) {
    return exp(sgma*distance*distance);
}

static const int filterSize = 8;

float4 main(PS_INPUT i) : COLOR {
    float2 uv = i.vTexCoord;

    float depth = tex2Dlod(WPDepthBuffer, float4(uv,0,0)).a;

    [BRANCH]
    if (depth == 0.00025) discard;

    float4 normal_buffer = tex2Dlod(NormalsBuffer, float4(uv,0,0));
    float3 n_center = Decode(normal_buffer.xy);

    float sigma = float(filterSize) / 3.0;
    float twoSigma2 = 2.0 * sigma * sigma;

    float3 sum = 0.;
    float wsum = 0.;

    for (int x = -filterSize; x <= filterSize; ++x) {
        float2 coords = x;
        float3 sampl = Decode(tex2Dlod(NormalsBuffer, float4(uv + coords * TexBaseSize, 0,0) ).xy);

        float w = exp(-coords.x * coords.x / twoSigma2);

        sum += sampl * w;
        wsum += w;
    }

    float3 N = normalize(sum/wsum);

    float3 T = decode_tangent(n_center, normal_buffer.z);
    T = normalize(T-dot(N,T)*N); // Gram-Schmidt process

    return float4(Encode(N), encode_tangent(N, T), normal_buffer.w);
}


// https://stackoverflow.com/questions/42894388/smoothing-tangents-using-existing-normals-opengl-lighting
