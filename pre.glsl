/** Struct typedefs */
struct Mat {
    vec3 albedo;
    float metallic;
    float roughness;
    float ambient;
    float reflectance;
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
Hit scene(vec3 p);

/** Helper functions */
// min between hits
Hit min(Hit x, Hit y) {
    if (x.dist < y.dist) {
        return x;
    } else {
        return y;
    }
}

// normal estimation
#define kcn vec2(1, -1)
vec3 calcNormal(vec3 p) {
    return normalize(
        kcn.xyy * scene(p + kcn.xyy * EPS).dist +
        kcn.yyx * scene(p + kcn.yyx * EPS).dist +
        kcn.yxy * scene(p + kcn.yxy * EPS).dist +
        kcn.xxx * scene(p + kcn.xxx * EPS).dist
    );
}

/** Constants */
#define UP vec3(0, 1, 0)
#define PI 3.1415926538

/** Shader io */
layout (set = 0, binding = 2) buffer bframe { float aframe[]; };
float frame = aframe[0];