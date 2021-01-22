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

struct Hit {
    float dist;
    Mat mat;
};

struct Camera {
    vec3 pos;
    vec3 look;
};

/** Helper functions */
Hit min(Hit x, Hit y) {
    if (x.dist < y.dist) {
        return x;
    } else {
        return y;
    }
}

/** Constants */
const vec3 UP = vec3(0, 1, 0);
#define PI 3.1415926538