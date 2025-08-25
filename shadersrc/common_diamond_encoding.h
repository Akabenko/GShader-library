
// https://www.jeremyong.com/graphics/2023/01/09/tangent-spaces-and-diamond-encoding/

float encode_diamond(float2 p)
{
    // Project to the unit diamond, then to the x-axis.
    float x = p.x / (abs(p.x) + abs(p.y));

    // Contract the x coordinate by a factor of 4 to represent all 4 quadrants in
    // the unit range and remap
    float py_sign = sign(p.y);
    return -py_sign * 0.25f * x + 0.5f + py_sign * 0.25f;
}

float2 decode_diamond(float p)
{
    float2 v;

    // Remap p to the appropriate segment on the diamond
    float p_sign = sign(p - 0.5f);
    v.x = -p_sign * 4.f * p + 1.f + p_sign * 2.f;
    v.y = p_sign * (1.f - abs(v.x));

    // Normalization extends the point on the diamond back to the unit circle
    return normalize(v);
}

// Given a normal and tangent vector, encode the tangent as a single float that can be
// subsequently quantized.
float encode_tangent(float3 normal, float3 tangent)
{
    // First, find a canonical direction in the tangent plane
    float3 t1;
    if (abs(normal.y) > abs(normal.z))
    {
        // Pick a canonical direction orthogonal to n with z = 0
        t1 = float3(normal.y, -normal.x, 0.f);
    }
    else
    {
        // Pick a canonical direction orthogonal to n with y = 0
        t1 = float3(normal.z, 0.f, -normal.x);
    }
    t1 = normalize(t1);

    // Construct t2 such that t1 and t2 span the plane
    float3 t2 = cross(t1, normal);

    // Decompose the tangent into two coordinates in the canonical basis
    float2 packed_tangent = float2(dot(tangent, t1), dot(tangent, t2));

    // Apply our diamond encoding to our two coordinates
    return encode_diamond(packed_tangent);
}

float3 decode_tangent(float3 normal, float diamond_tangent)
{
    // As in the encode step, find our canonical tangent basis span(t1, t2)
    float3 t1;
    if (abs(normal.y) > abs(normal.z))
    {
        t1 = float3(normal.y, -normal.x, 0.f);
    }
    else
    {
        t1 = float3(normal.z, 0.f, -normal.x);
    }
    t1 = normalize(t1);

    float3 t2 = cross(t1, normal);

    // Recover the coordinates used with t1 and t2
    float2 packed_tangent = decode_diamond(diamond_tangent);

    return packed_tangent.x * t1 + packed_tangent.y * t2;
}