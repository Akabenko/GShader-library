
float bayer2(float2 a) {
    a = floor(a);
    return frac(dot(a, float2(0.5, a.y * 0.75)));
}

// Dithering lookup (bayer16)
#define bayer4(a) (mad(bayer2(0.5*(a)), 0.25, bayer2(a)))
#define bayer8(a) (mad(bayer4(0.5*(a)), 0.25, bayer2(a)))
#define bayer16(a) (mad(bayer8(0.5*(a)), 0.25, bayer2(a)))
