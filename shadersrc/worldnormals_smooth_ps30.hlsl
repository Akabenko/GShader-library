sampler NormalBuffer    : register(s0);
sampler WorldPosBuffer  : register(s1);
sampler DepthBuffer     : register(s2);

const float4 C0     : register(c0);
const float4 C1     : register(c1);
const float4 C2     : register(c2);

float2 TexBaseSize : register(c4);

struct PS_INPUT {
    float2 P        : VPOS;
    float2 uv       : TEXCOORD0;
};

#define FilterEpsilon      float(C2.x)  // 0.01 - 0.1
#define KernelScale        float(C1.y)  // 1.0 - 3.0

static const float SpatialSigma = float(0.9);

static const float2 offsets[9] = {
    float2(-1,-1), float2(0,-1), float2(1,-1),
    float2(-1,0), float2(0,0), float2(1,0),
    float2(-1,1), float2(0,1), float2(1,1)
};

static const float off_len[9] = {
    length(offsets[0]), length(offsets[1]),length(offsets[2]),
    length(offsets[3]),length(offsets[4]),length(offsets[5]),
    length(offsets[6]),length(offsets[7]),length(offsets[8])
};

static const float spatialDistSquare[9] = {
    -off_len[0]*off_len[0], -off_len[1]*off_len[1],-off_len[2]*off_len[2],
    -off_len[3]*off_len[3],-off_len[4]*off_len[4],-off_len[5]*off_len[5],
    -off_len[6]*off_len[6],-off_len[7]*off_len[7],-off_len[8]*off_len[8]
};

static const float sigma_final = (2.0 * SpatialSigma * SpatialSigma);

static const float spatialWeightes[9] = {
    exp(spatialDistSquare[0] / sigma_final ), exp(spatialDistSquare[1] / sigma_final ),exp(spatialDistSquare[2] / sigma_final ),
    exp(spatialDistSquare[3] / sigma_final ),exp(spatialDistSquare[4] / sigma_final ),exp(spatialDistSquare[5] / sigma_final ),
    exp(spatialDistSquare[6] / sigma_final ),exp(spatialDistSquare[7] / sigma_final ),exp(spatialDistSquare[8] / sigma_final )
};

float3 ApplyFilter(float2 uv, float3 centerNormal, float3 centerPos)
{
    //float depth = abs(C1.x - pow(tex2D(DepthBuffer, uv).r, C0.x));
    //float2 offset = TexBaseSize * KernelScale * depth;
    float2 offset = TexBaseSize * KernelScale;
    
    float3 mean_I = 0, mean_N = 0, cov_IN = 0, var_I = 0;
    float totalWeight = 0;
    
    //[unroll]
    for (int i = 0; i < 9; i++)
    {
        float2 sampleUV = uv + offsets[i] * offset;
        float3 samplePos = 1.0 / tex2D(WorldPosBuffer, sampleUV).xyz;
        float3 sampleNormal = tex2D(NormalBuffer, sampleUV).xyz;
        
        float weight = saturate( dot(centerNormal, sampleNormal) );
        weight *= spatialWeightes[i];

        float3 samplePos_weight = samplePos * weight;
        
        mean_I += samplePos_weight;
        mean_N += sampleNormal * weight;
        cov_IN += samplePos * sampleNormal * weight;
        var_I += samplePos * samplePos_weight;
        totalWeight += weight;
    }
    
    mean_I /= totalWeight;
    mean_N /= totalWeight;
    cov_IN = cov_IN / totalWeight - mean_I * mean_N;
    var_I = var_I / totalWeight - mean_I * mean_I;

    float3 a = cov_IN / (var_I + FilterEpsilon);
    float3 b = mean_N - a * mean_I;

    return a * centerPos + b;
}

float4 main(PS_INPUT i) : COLOR 
{
    float2 uv = (i.P+0.5)*TexBaseSize;
    
    float3 centerNormal = tex2D(NormalBuffer, uv).xyz;
    float3 centerPos = 1/tex2D(WorldPosBuffer, uv).xyz;
    
    float3 filteredNormal = ApplyFilter(uv, centerNormal, centerPos);
    
    filteredNormal = normalize(filteredNormal);
    
    return float4(filteredNormal, 1.0);
}
