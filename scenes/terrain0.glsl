#version 450

/** Scene settings */
const float EPS = 0.001;
const int MAX_STEPS = 4096;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 512;
const float FOV = 4.0;
const int MAX_BOUNCES = 0;
#define Lights Light[1]

#include "pre.glsl"

/** Constants */
const Mat mTerrain = Mat(
    vec3(0.49, 0.27, 0.13),
    0.0,
    0.7,
    0.2,
    0.0,
    0.0,
    1.0
);

/** Utils */
float rhash(vec2 p) {
    p = 50.0f*fract(p*0.3183f + vec2(0.71,0.113));
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
    for (int i = 0; i < 9; i++) {
        t += a * noise(f * p);
        f *= 2.0f;
        a *= 0.5f;
    }
    return t;
}

/** Object Declaration */
#define Terrain 1

ObjHit terrainOH(vec3 p) {
    Mat m = mTerrain;
    vec3 norm = calcNormal(p);
    const vec3 peak = mix(vec3(0.18, 0.1, 0.05), vec3(0.2), clamp((0.5 + p.y / 10) + noise(vec2(p.x, p.z)), 0.0, 1.0));
    const vec3 base = mix(vec3(0.025, 0.12, 0.03), vec3(0.18, 0.1, 0.05), clamp(0.9 + p.y / 10, 0.0, 1.0));
    m.albedo = mix(base, peak, clamp(smoothstep(0.3, 0.5, p.y / 10), 0.0, 1.0));
    return ObjHit(norm, m);
}

// Object ID switch
ObjHit object(uint id, vec3 p) {
    switch (id) {
        case Terrain:
        return terrainOH(p);
    }
}

/** SDF functions */
Hit terrainSDF(vec3 p) {
    p -= vec3(0, -2, 0);
    p /= 40.0f;
    Hit hit;
    float e = fbm(vec2(p.x, p.z));
    e *= 0.5f;
    hit.dist = (p.y - e);
    hit.id = Terrain;
    return hit;
}

/** Scene function */
Hit scene(vec3 p) {
    return terrainSDF(p);
}

/** Camera function */
Camera camera() {
    Camera c;
    c.pos = vec3(30 - frame / 2, frame / 2, -frame / 2);
    c.look = vec3(50 - frame / 2, 8 + frame / 4, -50 + frame / 2);
    return c;
}

/** Sky color function */
vec3 skyColor(vec3 eye, vec3 dirc) {
    return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

/** Custom Shading */
#define CUSTOM_SHADING 1
vec4 cshade(ObjHit oh, vec3 p, vec3 eye, Lights l) {
    vec4 color = shade(oh, p, eye, l);

    float dist = length(eye - p);
    vec3 rayDir = normalize(p - eye);

    float fogAmount = 1.0 - exp(-0.000002 * dist * dist);
    float sunAmount = max(dot(rayDir, normalize(l[0].pos - p)), 0.0);
    vec3 fogColor = mix(vec3(0.5, 0.6, 0.7), vec3(1.0, 0.9, 0.7), pow(sunAmount, 8.0));
    return mix(color, vec4(fogColor, 1.0), fogAmount);
}

/** Lights */
Lights lights() {
    return Lights(
        Light(vec3(100, 1000, -100), vec3(1.64, 1.27, 0.99) * 10000000)
    );
}

#include "main.glsl"
