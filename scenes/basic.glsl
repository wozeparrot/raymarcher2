#version 450
#include "pre.glsl"

/** Scene settings */
const float EPS = 0.0001;
const int MAX_STEPS = 512;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 128;
const float FOV = 1.5;

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

/** SDF functions */
Hit plane(vec3 p) {
    p -= vec3(0, -1, 0);
    Hit hit;
    hit.dist = p.y;
    hit.mat = mPlane;
    return hit;
}

Hit sphere(vec3 p) {
    p -= vec3(1, 0, 1);
    Hit hit;
    hit.dist = length(p) - 1;
    Mat m = mSphere;
    m.metallic = p.y;
    hit.mat = m;
    return hit;
}

Hit box(vec3 p) {
    p -= vec3(0, 0, -2);
    Hit hit;
    vec3 q = max(abs(p) - vec3(1, 1, 1), 0.0f);
    hit.dist = length(q) - min(max(q.x, max(q.y, q.z)), 0.0f);
    hit.mat = mBox;
    return hit;
}

/** Scene function */
Hit scene(vec3 p) {
    return min(min(plane(p), sphere(p)), box(p));
}

/** Camera function */
Camera camera(const int frame) {
    Camera c;
    c.pos = vec3(-8, sin(float(frame)) + 5.0f, 7);
    c.look = vec3(0, 0, 0);
    return c;
}

/** Sky color function */
vec3 skyColor(vec3 eye, vec3 dirc) {
    return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

/** Lights */
const Light LIGHTS[] = {
    { vec3(0, 3, 0), vec3(10, 10, 10) },
    { vec3(0, 0, 3), vec3(10, 10, 10) }
};
const int LIGHT_COUNT = 2;

#include "main.glsl"