#version 450

/** Scene settings */
const float EPS = 0.001;
const int MAX_STEPS = 8192;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 384;
const float FOV = 4.0;
const int MAX_BOUNCES = 0;
#define Lights Light[1]

#include "pre.glsl"

/** Constants */
const Mat mTerrain = Mat(
    vec3(0.025, 0.12, 0.03),
    0.0,
    0.7,
    0.2,
    0.0,
    0.0,
    1.0
);

const Mat mTree = Mat(
    vec3(0.025, 0.2, 0.03),
    0.0,
    0.7,
    0.2,
    0.0,
    0.0,
    1.0
);

/** Utils */
float rhash(vec2 p) {
    p = 50.0f*fract(p*0.3183345f + vec2(0.71,0.113));
    return -1.0f+2.0f*fract(p.x*p.y*(p.x+p.y));
}

vec2 rhash2(vec2 p) {
    const vec2 k = vec2(0.3183345, 0.3678345);
    p = p * k + k.yx;
    return fract(16.0 * k * fract(p.x * p.y * (p.x + p.y)));
}

float rhash3(float n) {
    return fract(n * 17.0 * fract(n * 0.3183456));
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

float noise2(vec3 x) {
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    
    float n = p.x + 317.0 * p.y + 157.0 * p.z;
    
    float a = rhash3(n + 0.0);
    float b = rhash3(n + 1.0);
    float c = rhash3(n + 317.0);
    float d = rhash3(n + 318.0);
    float e = rhash3(n + 157.0);
	float f = rhash3(n + 158.0);
    float g = rhash3(n + 474.0);
    float h = rhash3(n + 475.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
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

const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );

float fbm_4(vec3 x) {
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for(int i = 0; i < 4; i++)
    {
        float n = noise2(x);
        a += b * n;
        b *= s;
        x = f * m3 * x;
    }
	return a;
}

float sdEllipsoidY(vec3 p, vec2 r) {
    float k0 = length(p / r.xyx);
    float k1 = length(p / (r.xyx * r.xyx));
    return k0 * (k0 - 1.0) / k1;
}

/** Object Declaration */
#define Terrain 0
ObjHit terrainOH(vec3 p) {
    Mat m = mTerrain;
    vec3 norm = calcNormal(p);
    return ObjHit(norm, m);
}

#define Tree 1
ObjHit treeOH(vec3 p) {
    Mat m = mTree;
    vec3 norm = calcNormal(p);
    return ObjHit(norm, m);
}

// Object ID switch
ObjHit object(uint id, vec3 p) {
    switch (id) {
        case Terrain:
        return terrainOH(p);
        case Tree:
        return treeOH(p);
    }
}

/** SDF functions */
Hit terrainSDF(vec3 p) {
    p -= vec3(0, -2, 0);
    p /= 40.0f;
    Hit hit;
    float e = fbm(vec2(p.x, p.z));
    e *= 0.2f;
    hit.dist = (p.y - e);
    hit.id = Terrain;
    return hit;
}

Hit treeSDF(vec3 p, float pd) {
    p -= vec3(50, 0, -50);
    Hit hit;

    float d = 10.0;
    vec2 n = floor(p.xz);
    vec2 f = fract(p.xz);
    for (int i = 0; i <= 1; i++)
    for (int j = 0; j <= 1; j++) {
        vec2 g = vec2(float(i), float(j)) - step(f, vec2(0.5));
        vec2 o = rhash2(n + g);
        vec2 v = rhash2(n + g + vec2(13.1, 71.7));
        vec2 r = g - f + o;

        float height = 2.0 * (0.4 + 0.8 * v.x);
        float width = 0.9 * (0.5 + 0.2 * v.x + 0.3 * v.y);
        vec3 q = vec3(r.x, p.y - height * 0.5, r.y);

        float k = sdEllipsoidY(q, vec2(width, 0.5 * height));
        if (k < d) {
            d = k;
        }
    }

    // float s = fbm_4(p * 3);
    // s *= s;
    // float att = 1.0 - smoothstep(200, 500, d);
    // d += 2.0 * s * att * att;

    if (noise2(p / 40) < -0.1) {
        d = FAR_CLIP + EPS;
    }

    hit.dist = d;
    hit.id = Tree;
    return hit;
}

/** Scene function */
Hit scene(vec3 p) {
    // return terrainSDF(p);
    Hit t = terrainSDF(p);
    return min(t, treeSDF(p, t.dist));
}

/** Camera function */
Camera camera() {
    Camera c;
    c.pos = vec3(30 + frame / 2, 10, frame / 2);
    c.look = vec3(30 + frame / 2, 8, 50 + frame / 2);
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
