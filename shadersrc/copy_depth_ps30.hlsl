
sampler BASETEXTURE     : register(s0);
float2 TexBaseSize : register( c4 );
struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv           : TEXCOORD0;
};


float4 main(PS_INPUT frag) : COLOR0 {
    float2 uv = frag.uv;
    float depth = tex2D(BASETEXTURE, uv).a;
    return float4(depth,0,0,1);
};
