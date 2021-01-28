/** Struct typedefs */
struct Mat {
    vec3 albedo;
    float metallic;
    float roughness;
    float ambient;
    float reflectance;
    float refractance;
    float ior;
};

struct Light {
    vec3 pos;
    vec3 intensity;
};

struct Camera {
    vec3 pos;
    vec3 look;
};

struct Hit {
    float dist;
    uint id;
};

struct ObjHit {
    vec3 norm;
    Mat mat;
};

/** Forward Declaration */
vec3 calcNormal(vec3 p);
vec4 shade(ObjHit oh, vec3 p, vec3 eye, Lights l);
float shadow(vec3 lightDir, float lightDist, vec3 p);
float shadow(vec3 lightDir, vec3 p);

/** Helper functions */
// min between hits
Hit min(Hit x, Hit y) {
    if (x.dist < y.dist) {
        return x;
    } else {
        return y;
    }
}

/** Constants */
#define UP vec3(0, 1, 0)
#define PI 3.1415926538

/** Shader io */
layout (set = 0, binding = 2) buffer bframe { float aframe[]; };
float frame = aframe[0];