
//#include "common_velocity_encoding.h"
#include "common_ps_fxc.h"
#include "common_diamond_encoding.h"
#include "common_octahedron_encoding.h"

sampler BASETEXTURE         : register(s0);
sampler FrameBuffer         : register(s1);
sampler WPDepthBuffer       : register(s2);

const float4 C0     : register(c0); // xyz = cEyePos
const float4 C1     : register(c1);
const float4 C2     : register(c2);
const float4 C3     : register(c3);

float2 TexBaseSize : register( c4 );

const float4x4 g_pViewProj          : register( c11 );
const float4x4 g_invViewProjMatrix  : register( c15 );

float getRawDepth(float2 uv) {
    return tex2Dlod(WPDepthBuffer, float4(uv,0,0) ).a;
    //return 1/(tex2D(BASETEXTURE, uv).r*4000);
}

#include "wpn_reconstruction.h"

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv           : TEXCOORD0;
    float3 fogParams    : TEXCOORD1;
};

#define depth_dimensions C1.x

struct PS_OUTPUT {
    float4 color0 : COLOR0; // .xy worldNormals, .b tangent, .a sign
    half4 color1 : COLOR1; // .xyz bumps, .a fog
    //float4 color2 : COLOR2; // .ra velocity buffer 
};

//#define bias float(0.000009) //0.000009
#define strength 1
#define g_velocityBlurParams 1

float3 getWorldPos(float2 uv) {
    return 1/tex2Dlod(WPDepthBuffer, float4(uv,0,0)).xyz;
}

float3 getWorldPos(float2 uv, out float depth ) {
    float4 wp_depth = tex2Dlod(WPDepthBuffer, float4(uv,0,0));
    depth = wp_depth.a;
    return 1/wp_depth.xyz;
}

void compute_tangent_cheap(float3 N, out float3 T) {
    float3 c1 = cross(N, float3(0.0, 0.0, 1.0));
    float3 c2 = cross(N, float3(0.0, 1.0, 0.0));
    T = (dot(c1, c1) > dot(c2, c2)) ? c1 : c2;
    T = -T * rsqrt(dot(T, T));
}

// Compute the matrix used to transform tangent space normals to world space
// This expects DirectX normal maps in Mikk Tangent Space http://www.mikktspace.com
void compute_tangent_frame(float3 N, float3 P, out float3 T, out float sign_det)
{
    float3 dp1 = ddx(P);
    float3 dp2 = ddy(P);

    float2 uvX = P.zy;
    float2 uvY = P.xz;
    float2 uvZ = P.xy;

    float3 weights = abs(N);
    //weights /= (weights.x + weights.y + weights.z); // no UV - use Triplanar
    float inv_sum = rcp(weights.x + weights.y + weights.z);
    weights *= inv_sum;

    float2 duv1 = weights.x * ddx(uvX) + weights.y * ddx(uvY) + weights.z * ddx(uvZ);
    float2 duv2 = weights.x * ddy(uvX) + weights.y * ddy(uvY) + weights.z * ddy(uvZ);

    duv1 += 1e-5; // fixe some noise (but not everywhere)
    duv2 += 1e-5;

    sign_det = dot(dp2, cross(N, dp1)) > 0.0 ? -1 : 1;

    float3x3 M = float3x3(dp1,dp2,cross(dp1, dp2));
    float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
    T = normalize(mul(float2(duv1.x, duv2.x), inverseM));
    T = (T - dot(T, N) * N); // Otho Tangets
    T = normalize(T);
}

#define ViewProjX g_pViewProj[0]
#define ViewProjY g_pViewProj[1]
#define ViewProjZ g_pViewProj[2]
#define ViewProjW g_pViewProj[3]

float3 mul_wp(float3 position) {
    return float3(
        dot(position, ViewProjX.xyz)+ViewProjX.w,
        dot(position, ViewProjY.xyz)+ViewProjY.w,
        dot(position, ViewProjW.xyz)+ViewProjW.w
    );
}

#define bias            C3.x
    
#define PIXELFOGTYPE    C3.y

PS_OUTPUT main(PS_INPUT frag) {
    PS_OUTPUT o = (PS_OUTPUT)0;

    float2 vpos = frag.P + 0.5;
    //float2 vpos = frag.P;

    //float2 uv = (frag.P + 0.5)*TexBaseSize;
    float2 uv = vpos*TexBaseSize;

    float4 wp_depth = tex2Dlod(WPDepthBuffer, float4(uv,0,0));

    float depth = wp_depth.a;
    //float depth = getRawDepth(uv);

    [BRANCH]
    if (depth == 0.00025) discard;

    float3 world_pos = 1/wp_depth.xyz;
    //float3 world_pos = getWorldPos( uv, );

    half3 fogParams = frag.fogParams;
    half fog = 1;
    
    if (PIXELFOGTYPE != PIXEL_FOG_TYPE_NONE) {
        fog = max( fogParams.z, mad( 1 - 1/depth, fogParams.y, fogParams.x) );
    }

    float3 world_normal;

    #if defined(_RECONSTRUCTIONMETHOD_3_TAP)
        float2 uv1 = (vpos + float2(depth_dimensions, 0) )*TexBaseSize; // right 
        float2 uv2 = (vpos + float2(0, depth_dimensions) )*TexBaseSize; // top

        float3 P1 = getWorldPos(uv1);
        float3 P2 = getWorldPos(uv2);

        world_normal = normalize(cross(P2 - world_pos, P1 - world_pos));

        half3 center = tex2Dlod(FrameBuffer, float4(uv,0,0) ).rgb;

        half3 C1 = tex2Dlod(FrameBuffer, float4(uv1,0,0) ).rgb;
        half3 C2 = tex2Dlod(FrameBuffer, float4(uv2,0,0) ).rgb;

        float bumpX = Luminance( C2 - center );
        float bumpY = Luminance( C1 - center );
    #elif defined(_RECONSTRUCTIONMETHOD_4_TAP)
        // get view space position at 1 pixel offsets in each major direction
        float2 uv1 = (vpos + float2(-1.0, 0.0))*TexBaseSize;
        float2 uv2 = (vpos + float2( 1.0, 0.0))*TexBaseSize;
        float2 uv3 = (vpos + float2( 0.0,-1.0))*TexBaseSize;
        float2 uv4 = (vpos + float2( 0.0, 1.0))*TexBaseSize;

        float3 viewSpacePos_l = getWorldPos( uv1 );
        float3 viewSpacePos_r = getWorldPos( uv2 );
        float3 viewSpacePos_d = getWorldPos( uv3 );
        float3 viewSpacePos_u = getWorldPos( uv4 );

        // get the difference between the current and each offset position
        float3 hDeriv = viewSpacePos_r - viewSpacePos_l;
        float3 vDeriv = viewSpacePos_u - viewSpacePos_d;

        // get view space normal from the cross product of the diffs
        world_normal = -normalize(cross(hDeriv, vDeriv));

        half3 color_l = tex2Dlod(FrameBuffer, float4(uv1,0,0) ).rgb;
        half3 color_r = tex2Dlod(FrameBuffer, float4(uv2,0,0) ).rgb;
        half3 color_d = tex2Dlod(FrameBuffer, float4(uv3,0,0) ).rgb;
        half3 color_u = tex2Dlod(FrameBuffer, float4(uv4,0,0) ).rgb;

        half bumpX = Luminance( color_r - color_l );
        half bumpY = Luminance( color_u - color_d );
    #elif defined(_RECONSTRUCTIONMETHOD_IMPROVED)
        float2 uv1 = (vpos + float2(-1.0, 0.0) )*TexBaseSize;
        float2 uv2 = (vpos + float2( 1.0, 0.0) )*TexBaseSize;
        float2 uv3 = (vpos + float2( 0.0,-1.0) )*TexBaseSize;
        float2 uv4 = (vpos + float2( 0.0, 1.0) )*TexBaseSize;

        // get view space position at 1 pixel offsets in each major direction
        float3 viewSpacePos_l = getWorldPos( uv1 );
        float3 viewSpacePos_r = getWorldPos( uv2 );
        float3 viewSpacePos_d = getWorldPos( uv3 );
        float3 viewSpacePos_u = getWorldPos( uv4 );

        // get the difference between the current and each offset position
        float3 l = world_pos - viewSpacePos_l;
        float3 r = viewSpacePos_r - world_pos;
        float3 d = world_pos - viewSpacePos_d;
        float3 u = viewSpacePos_u - world_pos;

        // pick horizontal and vertical diff with the smallest z difference
        //float3 hDeriv = abs(l.z) < abs(r.z) ? l : r;
        //float3 vDeriv = abs(d.z) < abs(u.z) ? d : u;
        float use_right = float(abs(l.z) > abs(r.z));
        float use_bottom = float(abs(d.z) > abs(u.z));

        float3 hDeriv = lerp(l, r, use_right);
        float3 vDeriv = lerp(d, u, use_bottom);

        // get view space normal from the cross product of the two smallest offsets
        world_normal = -normalize(cross(hDeriv, vDeriv));

        half3 color_l = tex2Dlod(FrameBuffer, float4(uv1,0,0) ).rgb;
        half3 color_r = tex2Dlod(FrameBuffer, float4(uv2,0,0) ).rgb;
        half3 color_d = tex2Dlod(FrameBuffer, float4(uv3,0,0) ).rgb;
        half3 color_u = tex2Dlod(FrameBuffer, float4(uv4,0,0) ).rgb;

        half bumpX = lerp(Luminance(color_r - color_l), Luminance(color_l - color_r), use_right);
        half bumpY = lerp(Luminance(color_u - color_d), Luminance(color_d - color_u), use_bottom);
    #elif defined(_RECONSTRUCTIONMETHOD_ACCURATE)
        // based on Yuwen Wu's Accurate Normal Reconstruction 
        // https://atyuwen.github.io/posts/normal-reconstruction/
        // basically as accurate as you can get!
        // no artifacts on depth disparities
        // no artifacts on edges
        // artifacts on triangles that are <3 pixels across

        // unity's compiled fragment shader stats: 66 math, 9 tex

        // get view space position at 1 pixel offsets in each major direction

        float2 uv1 = uv + float2(-1.0, 0.0) * TexBaseSize;
        float2 uv2 = uv + float2( 1.0, 0.0) * TexBaseSize;
        float2 uv3 = uv + float2( 0.0,-1.0) * TexBaseSize;
        float2 uv4 = uv + float2( 0.0, 1.0) * TexBaseSize;

        float depth1;
        float depth2;
        float depth3;
        float depth4;

        float3 viewSpacePos_l = getWorldPos( uv1, depth1 );
        float3 viewSpacePos_r = getWorldPos( uv2, depth2 );
        float3 viewSpacePos_d = getWorldPos( uv3, depth3 );
        float3 viewSpacePos_u = getWorldPos( uv4, depth4 );

        // get the difference between the current and each offset position
        float3 l = world_pos - viewSpacePos_l;
        float3 r = viewSpacePos_r - world_pos;
        float3 d = world_pos - viewSpacePos_d;
        float3 u = viewSpacePos_u - world_pos;

        // get depth values at 1 & 2 pixels offsets from current along the horizontal axis
        float4 H = half4(
            depth1,
            depth2,
            getRawDepth( uv + float2(-2.0, 0.0) * TexBaseSize),
            getRawDepth( uv + float2( 2.0, 0.0) * TexBaseSize)
        );

        // get depth values at 1 & 2 pixels offsets from current along the vertical axis
        float4 V = half4(
            depth3,
            depth4,
            getRawDepth( uv + float2(0.0,-2.0) * TexBaseSize),
            getRawDepth( uv + float2(0.0, 2.0) * TexBaseSize)
        );

        // current pixel's depth difference from slope of offset depth samples
        // differs from original article because we're using non-linear depth values
        // see article's comments

        //float2 he = abs(H.xy * H.zw * rcp(2 * H.zw - H.xy) - depth);
        //float2 ve = abs(V.xy * V.zw * rcp(2 * V.zw - V.xy) - depth);

        //float2 he = abs((2 * H.xy - H.zw) - depth);
        //float2 ve = abs((2 * V.xy - V.zw) - depth);

        // pick horizontal and vertical diff with the smallest depth difference from slopes
        //float3 hDeriv = he.x < he.y+bias ? l : r;
        //float3 vDeriv = ve.x < ve.y ? d : u;
        //float3 hDeriv = (he.x < he.y + bias) ? l : r;
        //float3 vDeriv = (ve.x < ve.y + bias) ? d : u;
        //float3 hDeriv = lerp(l, r, he.x > he.y);
        //float3 vDeriv = lerp(d, u, ve.x > ve.y);
        float2 he = abs((H.xy * H.zw) * rcp(max(2.0 * H.zw - H.xy, 1e-5)) - depth);
        float2 ve = abs((V.xy * V.zw) * rcp(max(2.0 * V.zw - V.xy, 1e-5)) - depth);

        // Без ветвлений - лучше для GPU
        float3 hDeriv = lerp(l, r, float(he.x > he.y));
        float3 vDeriv = lerp(d, u, float(ve.x > ve.y));

        // get view space normal from the cross product of the best derivatives
        world_normal = -normalize(cross(hDeriv, vDeriv));

        half3 colorLeft    =   tex2Dlod(FrameBuffer, float4(uv1,0,0) ).rgb;
        half3 colorRight   =   tex2Dlod(FrameBuffer, float4(uv2,0,0) ).rgb;
        half3 colorBottom  =   tex2Dlod(FrameBuffer, float4(uv3,0,0) ).rgb;
        half3 colorTop     =   tex2Dlod(FrameBuffer, float4(uv4,0,0) ).rgb;
        
        //float bumpX = he.x < he.y ? 0 : Luminance( colorRight - colorLeft );
        //float bumpY = ve.x < ve.y ? 0 : Luminance( colorTop - colorBottom );
        half bumpX = lerp(0.0, Luminance(colorRight - colorLeft), float(he.x > he.y));
        half bumpY = lerp(0.0, Luminance(colorTop - colorBottom), float(ve.x > ve.y));
    #else
        // normals calculation for the hell of it
        // dont reference this code!!!!! ddx is imprecise and has poor edge continuity

        half luma = Luminance( tex2Dlod(FrameBuffer, float4(uv,0,0) ).rgb );

        half bumpX = -ddx(luma);
        half bumpY = -ddy(luma);

        world_normal = normalize(cross(ddy(world_pos), ddx(world_pos))); // на линуксе дохнет и не работает
    #endif

    float3 tangent;
    float sign_det = 1;

    #if defined(_RECONSTRUCTIONMETHOD_ACCURATE) || defined(_RECONSTRUCTIONMETHOD_IMPROVED)
    compute_tangent_frame(world_normal, world_pos, tangent, sign_det); // Mikk Tangent Space
    #else
    compute_tangent_cheap(world_normal, tangent);
    #endif

    o.color0 = float4(
        Encode(world_normal),
        encode_tangent(world_normal, tangent),
        sign_det
    );

    half3 normal = half3(bumpX * strength, bumpY * strength, 1);
    #if !defined(_RECONSTRUCTIONMETHOD_SIMPLE)
    //normal.z = sqrt(max(0.0, 1.0 - normal.x * normal.x - normal.y * normal.y));
    normal.z = sqrt(1.0 - normal.x * normal.x - normal.y * normal.y);
    //normal.z = sqrt(saturate(1.0 - dot(normal.xy, normal.xy)));
    #endif

    normal = normalize(normal);
    normal = mad(normal, 0.5, 0.5);
    normal = GammaToLinear(normal);

    o.color1 = float4(normal, fog);

    /*
    float2 currentPos = mad(uv, 2, -1);
    float3 previousPos = mul_wp(world_pos);
    previousPos.xy /= previousPos.z;

    float2 Velocity = currentPos.xy - previousPos.xy;
    float2 V_enc = VelocityEncode(Velocity);
    o.color2 = float4(V_enc.x,0,0,V_enc.y);
    */

    return o;
};

/*
Reconstruction of normals:
https://wickedengine.net/2019/09/improved-normal-reconstruction-from-depth/
https://gist.github.com/bgolus/a07ed65602c009d5e2f753826e8078a0
https://atyuwen.github.io/posts/normal-reconstruction/
*/




