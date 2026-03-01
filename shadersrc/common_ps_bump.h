#include "common_ps_fxc.h"

sampler basetexture   		: register( s0 );
sampler bumptexture   		: register( s1 );
sampler EnvmapMaskSampler	: register( s2 );

const float4 Constants0 	: register( c0 );
const float4 Constants1 	: register( c1 );

//const float2x4 cBaseTextureTransform : register( c11 );
const float4 cBaseTextureTransform[2] : register( c11 );

//#define DISPLACEMENTS

struct PS_INPUT
{
	float2 pPos					: VPOS;
	float3 uv					: TEXCOORD0;
	#if defined(DISPLACEMENTS)
	float2 projPosZ_projPosW    : TEXCOORD1;
	#endif
};

#define g_AlphaThreshold		Constants0.z
#define g_EnvmapTint			Constants1.x
#define bBaseAlphaEnvmapMask	Constants1.y == 1
#define bEnvmapMask				Constants1.y == 2

// #define SSBUMP


// * 0.5 + 0.5

#if defined(DISPLACEMENTS)

struct PS_OUT 
{
	half4 color0 	: COLOR0;
	float depth		: DEPTH0;
};

#define bias 0.05

PS_OUT main( PS_INPUT i )
#else
half4 main( PS_INPUT i ) : COLOR0
#endif
{
	float2 uv = i.uv.xy;
	half fog = i.uv.z;

	#if defined(DISPLACEMENTS)
	float2 projPosZ_projPosW = i.projPosZ_projPosW;
	#endif

	#if defined(ALPHATEST_)
	float alpha = tex2D(basetexture, uv).a;
	clip( alpha - g_AlphaThreshold );
	#endif

	float4 bump_texcoord = float4(uv, 1.f, 1.f );

	float2 tr_bump_texcoord = float2(
		dot(bump_texcoord, cBaseTextureTransform[0]),
		dot(bump_texcoord, cBaseTextureTransform[1])
	);

	half4 bump_spec = tex2D(bumptexture, tr_bump_texcoord);

	#if defined(SSBUMP)
	//bump_spec.xyz = mad(bump_spec.xyz, 0.5, 0.5);
		float3 bump = bump_spec.xyz;

		//bump = GammaToLinear(bump); // либо перед либо после или LinearToGamam

		// bump = LinearToGamma(bump);

		bump = float3(
			dot(bump, bumpBasisTranspose[0]),
			dot(bump, bumpBasisTranspose[1]),
			dot(bump, bumpBasisTranspose[2])
		);

		bump = bump * 0.5f + 0.5f;
		
		bump = clamp(bump, 0.f, 1.f); // мб нормализация лучше, но результат другой

		//bump = LinearToGamma(bump);
		bump = GammaToLinear(bump); // нужно обязательно. и в материале и здесь. мб виновник clamp

		//bump = normalize( bump );

		bump_spec.xyz = bump;
	#endif

	half specularFactor = bump_spec.a;

	if (bEnvmapMask) {
		specularFactor = Luminance( tex2D(EnvmapMaskSampler, uv).xyz );
	} 

	#if defined(ALPHATEST_)
	if (bBaseAlphaEnvmapMask) {
		specularFactor = 1.0 - tex2D(basetexture, uv).a;
	}
	#endif

	specularFactor *= g_EnvmapTint;
	specularFactor = saturate(specularFactor);
	specularFactor *= fog;
	half4 final = half4(bump_spec.xyz, specularFactor);
	
	#if defined(DISPLACEMENTS)
	PS_OUT Out;
	Out.color0 = final;
	//Out.depth = projPosZ_projPosW.x / projPosZ_projPosW.y - bias; // нужен биаз. мои меши западают. поэтому моя глубина должна откатываться
	Out.depth = (projPosZ_projPosW.x) / (projPosZ_projPosW.y + bias);
	return Out;
	#else
    return final;
    #endif
};
