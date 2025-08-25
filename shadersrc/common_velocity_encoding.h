
// Based on CryTeck CryEngine 3 — Advances in Real-Time Rendering cource
// Implementation by LVutner

float2 VelocityEncode(float2 v)
{
    v = sqrt(abs(v)) * (v.xy > 0.0 ? 1.0 : -1.0);
    v = v * 0.5f + 127.0 / 255.0;
    return v;
}
 
float2 VelocityDecode(float2 v)
{
    v = (v - 127.0 / 255.0) * 2.0;
    v = (v * v) * (v.xy > 0.0 ? 1.0 : -1.0);
    return v;
}
