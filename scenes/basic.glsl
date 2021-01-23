#version 450

/** Scene settings */
const float EPS = 0.001;
const int MAX_STEPS = 4096;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 128;
const float FOV = 1.5;

#include "pre.glsl"

/** Constants */
const Mat mSphere = Mat(
    vec3(0.5, 0.2, 0.8),
    1.0,
    0.4,
    0.2,
    0.0
);

const Mat mPlane = Mat(
    vec3(0.4, 0.4, 0.4),
    0.0,
    1.0,
    0.2,
    0.0
);

const Mat mBox = Mat(
    vec3(0.3, 0.9, 0.6),
    0.6,
    0.4,
    0.1,
    0.0
);

/** Object Declaration */
#define Sphere 1
#define Plane 2
#define Box 3

ObjHit planeOH(vec3 p) {
    vec3 norm = vec3(0, 1, 0);
    return ObjHit(norm, mPlane);
}

ObjHit sphereOH(vec3 p) {
    vec3 norm = calcNormal(p);
    return ObjHit(norm, mSphere);
}

ObjHit boxOH(vec3 p) {
    vec3 norm = calcNormal(p);
    return ObjHit(norm, mBox);
}

// Object ID switch
ObjHit object(uint id, vec3 p) {
    switch (id) {
        case Sphere:
        return sphereOH(p);
        case Plane:
        return planeOH(p);
        case Box:
        return boxOH(p);
    }
}

/** SDF functions */
Hit planeSDF(vec3 p) {
    p -= vec3(0, -1, 0);
    Hit hit;
    hit.dist = p.y;
    hit.id = Plane;
    return hit;
}

Hit sphereSDF(vec3 p) {
    p -= vec3(1, 0, 1);
    Hit hit;
    hit.dist = length(p) - abs(sin(frame / 10) * 2);
    hit.id = Sphere;
    return hit;
}

Hit boxSDF(vec3 p) {
    p -= vec3(0, sin(frame / 10) * 4, -2);
    Hit hit;
    vec3 q = max(abs(p) - vec3(1, 1, 1), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Box;
    return hit;
}

/** Scene function */
Hit scene(vec3 p) {
    return min(min(planeSDF(p), sphereSDF(p)), boxSDF(p));
}

/** Camera function */
Camera camera() {
    Camera c;
    c.pos = vec3(sin(frame / 20) * 10, 5.0f, cos(frame / 20) * 10);
    c.look = vec3(0, 0, 0);
    return c;
}

/** Sky color function */
vec3 skyColor(vec3 eye, vec3 dirc) {
    return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

/** Lights */
#define Lights Light[2]
Lights lights() {
    return Lights(
        Light(vec3(sin(frame / 10) * 10, 3, 0), vec3(10, 10, 10)),
        Light(vec3(0, 0, 3), vec3(10, 10, 10))
    );
}

#include "main.glsl"
