#version 450
#include "pre.glsl"

/** Scene settings */
const float EPS = 0.001;
const int MAX_STEPS = 2048;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 256;
const float FOV = 45;

/** Constants */
const Mat mTerrain = Mat(
    vec3(0.79, 0.57, 0.43),
    0.0,
    0.7,
    0.2,
    0.0
);

/** Utils */
float rhash(vec2 p) {
    p = 50.0f*fract(p*0.3183099f + vec2(0.71,0.113));
    return -1.0f+2.0f*fract(p.x*p.y*(p.x+p.y));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
	
	vec2 u = f * f * (3.0f - 2.0f * f);

    return mix(mix(rhash(i + vec2(0.0,0.0)), 
                   rhash(i + vec2(1.0,0.0)), u.x),
               mix(rhash(i + vec2(0.0,1.0)), 
                   rhash(i + vec2(1.0,1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float f = 1.0f;
    float a = 1.0f;
    float t = 0.0f;
    for (int i = 0; i < 10; i++) {
        t += a * noise(f * p);
        f *= 2.0f;
        a *= 0.5f;
    }
    return t;
}

vec3 tNormal(const vec3 p)
{
    return normalize(vec3(fbm(vec2(p.x - EPS, p.z)) - fbm(vec2(p.x + EPS, p.z)),
                          2.0f * EPS,
                          fbm(vec2(p.x, p.z - EPS)) - fbm(vec2(p.x, p.z + EPS))));
}

/** SDF functions */
Hit terrain(vec3 p) {
    p -= vec3(0, -2, 0);
    p /= 6.0f;
    Hit hit;
    float e = fbm(vec2(p.x, p.z));
    // e = e + 0.15f * smoothstep(-0.08f, -0.01f, e);
    e *= 0.5f;
    hit.dist = (p.y - e);

    Mat m = mTerrain;
    
    vec3 norm = tNormal(p);
    if (dot(norm, vec3(0, 1, 0)) > 0.1f) {
        m.albedo = vec3(1);
    }
    hit.mat = m;
    
    return hit;
}

/** Scene function */
Hit scene(vec3 p) {
    return terrain(p);
}

/** Camera function */
Camera camera() {
    Camera c;
    c.pos = vec3(30 - frame, 10 + sin(frame / 40) * 0.4, -50);
    c.look = vec3(0 - frame, 8 + cos(frame / 40) * 0.4, -50);
    return c;
}

/** Sky color function */
vec3 skyColor(vec3 eye, vec3 dirc) {
    return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

/** Lights */
#define Lights Light[1]
Lights lights() {
    return Lights(
        Light(vec3(30 - frame, 80, -60), vec3(10000, 10000, 10000))
    );
}

#include "main.glsl"
