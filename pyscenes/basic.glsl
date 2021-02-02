#version 450

const float EPS = 0.001;
const int MAX_STEPS = 4096;
const float NEAR_CLIP = 0.01;
const float FAR_CLIP = 128;
const float FOV = 1.5;
const int MAX_BOUNCES = 10;
#define Lights Light[2]

#include "pre.glsl"

const Mat mat_simple = Mat(
	vec3(0.2, 0, 0.2),
	1,
	0.4,
	0,
	0.7,
	0.0,
	1.0
);

const Mat mat_floor = Mat(
	vec3(0.2, 1.0, 0.2),
	0,
	1,
	0.2,
	0,
	0.0,
	1.0
);

#define obj_ball0 0
ObjHit obj_ball0OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball1 1
ObjHit obj_ball1OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball2 2
ObjHit obj_ball2OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball3 3
ObjHit obj_ball3OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball4 4
ObjHit obj_ball4OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball5 5
ObjHit obj_ball5OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_ball6 6
ObjHit obj_ball6OH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_simple);
}

#define obj_floor 7
ObjHit obj_floorOH(vec3 p) {
	vec3 norm = calcNormal(p);
	return ObjHit(norm, mat_floor);
}

ObjHit object(uint id, vec3 p) {
	switch (id) {
		case obj_ball0:
		return obj_ball0OH(p);
		case obj_ball1:
		return obj_ball1OH(p);
		case obj_ball2:
		return obj_ball2OH(p);
		case obj_ball3:
		return obj_ball3OH(p);
		case obj_ball4:
		return obj_ball4OH(p);
		case obj_ball5:
		return obj_ball5OH(p);
		case obj_ball6:
		return obj_ball6OH(p);
		case obj_floor:
		return obj_floorOH(p);
	}
}

Hit obj_ball0SDF(vec3 p) {
	p -= vec3(0, 1, 0);
	Hit hit;
	hit.id = obj_ball0;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball1SDF(vec3 p) {
	p -= vec3(2, 1.5, 0);
	Hit hit;
	hit.id = obj_ball1;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball2SDF(vec3 p) {
	p -= vec3(-2, 0, 0);
	Hit hit;
	hit.id = obj_ball2;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball3SDF(vec3 p) {
	p -= vec3(0, 1.5, 2);
	Hit hit;
	hit.id = obj_ball3;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball4SDF(vec3 p) {
	p -= vec3(0, 0, -2);
	Hit hit;
	hit.id = obj_ball4;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball5SDF(vec3 p) {
	p -= vec3(2, 2, 2);
	Hit hit;
	hit.id = obj_ball5;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_ball6SDF(vec3 p) {
	p -= vec3(-2, -0.5, -2);
	Hit hit;
	hit.id = obj_ball6;
	hit.dist = length(p) - 1;
	return hit;
}

Hit obj_floorSDF(vec3 p) {
	p -= vec3(0, -2, 0);
	Hit hit;
	hit.id = obj_floor;
	hit.dist = p.y;
	return hit;
}

Hit scene(vec3 p) {
	Hit hmin;
	hmin.dist = 128.011;
	Hit hit;
	hit = obj_ball0SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball1SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball2SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball3SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball4SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball5SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_ball6SDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	hit = obj_floorSDF(p);
	if (hit.dist < hmin.dist) {
		hmin = hit;
	}
	return hmin;
}

Camera camera() {
	Camera c;
	c.pos = vec3(-2, 3, -7);
	c.look = vec3(0, 1.5, 0);
	return c;
}

vec3 skyColor(vec3 eye, vec3 dirc) {
	return (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));
}

Lights lights() {
	return Lights(
		Light(vec3(0, 10, 10), vec3(10, 10, 10)),
		Light(vec3(0, 10, -10), vec3(10, 10, 10))
	);
}

#include "main.glsl"