#include "common_diamond_encoding.h"
#include "common_octahedron_encoding.h"

sampler WPNDepthBuffer  : register(s0);
sampler NormalBuffer    : register(s1);
float2 TexBaseSize : register( c4 );

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv : TEXCOORD0;
};

struct PS_OUTPUT {
    float4 color0 : COLOR0;
};

void compute_tangent_frame(float3 N, float3 P, out float3 T, out float sign_det)
{
    float3 dp1 = ddx(P);
    float3 dp2 = ddy(P);

    float2 uvX = P.zy;
    float2 uvY = P.xz;
    float2 uvZ = P.xy;

    float3 weights = abs(N);
    weights /= (weights.x + weights.y + weights.z); // no UV - use Triplanar

    float2 duv1 = weights.x * ddx(uvX) + weights.y * ddx(uvY) + weights.z * ddx(uvZ);
    float2 duv2 = weights.x * ddy(uvX) + weights.y * ddy(uvY) + weights.z * ddy(uvZ);

    sign_det = dot(dp2, cross(N, dp1)) > 0.0 ? -1 : 1;

    float3x3 M = float3x3(dp1,dp2,cross(dp1, dp2));
    float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
    T = normalize(mul(float2(duv1.x, duv2.x), inverseM));
    T = (T - dot(T, N) * N); // Otho Tangets
    T = normalize(T);
}

PS_OUTPUT main(PS_INPUT frag) {
    PS_OUTPUT o = (PS_OUTPUT)0;

    float2 uv = (frag.P + 0.5)*TexBaseSize;
    
    float3 world_normal = tex2D(NormalBuffer,uv).rgb;
    float3 world_pos = 1/tex2D(WPNDepthBuffer,uv).rgb;

    float3 tangent;
    float sign_det;
    compute_tangent_frame(world_normal, world_pos, tangent, sign_det);

    float2 encode_normals = Encode(world_normal);
    float encode_tangents = encode_tangent(world_normal, tangent);

    o.color0 = float4(encode_normals, encode_tangents, sign_det);

    return o;
};




