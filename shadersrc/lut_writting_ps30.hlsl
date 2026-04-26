const float4 color : register( c0 );

float4 main(float2 pPos : VPOS) : COLOR
{
	return color;
}
