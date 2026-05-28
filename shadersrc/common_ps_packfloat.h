// https://gamedev.stackexchange.com/questions/7859/hlsl-pack-4-values-into-32-bit-float
// 32bit floats have 24 bits of significant precision, so the best precision you're going to get is 6 bits per component.
half4 UnpackConst4(float i)
{
   return fmod(float4(i / 262144.0, i / 4096.0, i / 64.0, i), 64.0)/63;
}
