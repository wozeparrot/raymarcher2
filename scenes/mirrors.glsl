#version 450

/** Scene settings */
const float EPS = 0.001;
const int MAX_STEPS = 4096;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 128;
const float FOV = 1.5;
const int MAX_BOUNCES = 6;
#define Lights Light[6]

#include "pre.glsl"

/** Constants */
const Mat mObj = Mat(
    vec3(0.5, 0.2, 0.8),
    1.0,
    0.4,
    0.2,
    0.0,
    0.0,
    1.0
);

const Mat mWall = Mat(
    vec3(0.0, 0.0, 0.0),
    0.0,
    1.0,
    0.0,
    1.0,
    0.0,
    1.0
);

/** Object Declaration */
#define Obj 1
#define Wall 2

ObjHit objOH(vec3 p) {
    vec3 norm = calcNormal(p);
    Mat m = mObj;
    m.albedo =  vec3(0.5 + sin(frame / 24) / 2, 0.2, 0.8);
    return ObjHit(norm, m);
}

ObjHit wallOH(vec3 p) {
    vec3 norm = calcNormal(p);
    return ObjHit(norm, mWall);
}

// Object ID switch
ObjHit object(uint id, vec3 p) {
    switch (id) {
        case Obj:
        return objOH(p);
        case Wall:
        return wallOH(p);
    }
}

/** SDF functions */
Hit planeSDF(vec3 p) {
    p -= vec3(0, -6, 0);
    Hit hit;
    hit.dist = p.y;
    hit.id = Wall;
    return hit;
}

Hit boxSDF(vec3 p) {
    p -= vec3(-1, 0, 0);
    Hit hit;
    vec3 q = max(abs(p) - vec3(0.5, 0.5, 0.5), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Obj;
    return hit;
}

Hit sphereSDF(vec3 p) {
    p -= vec3(1, 0, 0);
    Hit hit;
    hit.dist = length(p) - abs(sin(frame / 12));
    hit.id = Obj;
    return hit;
}

Hit wall0SDF(vec3 p) {
    p -= vec3(0, 0, -6);
    Hit hit;
    vec3 q = max(abs(p) - vec3(10, 10, 1), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Wall;
    return hit;
}

Hit wall1SDF(vec3 p) {
    p -= vec3(6, 0, 0);
    Hit hit;
    vec3 q = max(abs(p) - vec3(1, 10, 10), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Wall;
    return hit;
}

Hit wall2SDF(vec3 p) {
    p -= vec3(0, 0, 6);
    Hit hit;
    vec3 q = max(abs(p) - vec3(10, 10, 1), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Wall;
    return hit;
}

Hit wall3SDF(vec3 p) {
    p -= vec3(-6, 0, 0);
    Hit hit;
    vec3 q = max(abs(p) - vec3(1, 10, 10), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Wall;
    return hit;
}

Hit wall4SDF(vec3 p) {
    p -= vec3(0, 6, 0);
    Hit hit;
    vec3 q = max(abs(p) - vec3(10, 1, 10), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.id = Wall;
    return hit;
}

Hit smin(Hit a, Hit b, float k) {
    float h = max(k - abs(a.dist - b.dist), 0.0) / k;
    a.dist = min(a.dist, b.dist) - h * h * h * k * (1.0 / 6.0);
    return a;
}

/** Scene function */
Hit scene(vec3 p) {
    Hit walls = min(min(min(wall0SDF(p), wall1SDF(p)), min(wall2SDF(p), wall3SDF(p))), wall4SDF(p));
    Hit objs = smin(boxSDF(p), sphereSDF(p), 3);
    return min(min(planeSDF(p), objs), walls);
}

/** Camera function */
Camera camera() {
    Camera c;
    c.pos = vec3(sin(frame / 24) * 4, 2, cos(frame / 24) * 4);
    c.look = vec3(0, 0, 0);
    return c;
}

/** Sky color function */
vec3 skyColor(vec3 eye, vec3 dirc) {
    return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

/** Lights */
Lights lights() {
    return Lights(
        Light(vec3(3, 1, -3), vec3(10, 10, 10)),
        Light(vec3(3, -1, 3), vec3(10, 10, 10)),
        Light(vec3(-3, -1, -3), vec3(10, 10, 10)),
        Light(vec3(-3, 1, 3), vec3(10, 10, 10)),
        Light(vec3(0, -3, 0), vec3(10, 10, 10)),
        Light(vec3(0, 3, 0), vec3(10, 10, 10))
    );
}

#include "main.glsl"
