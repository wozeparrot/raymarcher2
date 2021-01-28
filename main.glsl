/** Raymarch function */
Hit raymarch(vec3 eye, vec3 dirc) {
    float depth = EPS;
    for (int i = 0; i < MAX_STEPS; i++) {
        Hit hit = scene(eye + dirc * depth);
        if (hit.dist < EPS) {
            hit.dist = depth;
            return hit;
        }
        depth += hit.dist;
        if (depth >= FAR_CLIP) {
            Hit hit;
            hit.dist = FAR_CLIP;
            return hit;
        }
    }
    Hit hit;
    hit.dist = FAR_CLIP;
    return hit;
}

Hit raymarchO(vec3 eye, vec3 dirc) {
    float depth = EPS;
    for (int i = 0; i < MAX_STEPS; i++) {
        Hit hit = scene(eye + dirc * depth);
        hit.dist *= -1;
        if (hit.dist < EPS) {
            hit.dist = depth;
            return hit;
        }
        depth += hit.dist;
        if (depth >= FAR_CLIP) {
            Hit hit;
            hit.dist = FAR_CLIP;
            return hit;
        }
    }
    Hit hit;
    hit.dist = FAR_CLIP;
    return hit;
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

/** Shadow calculation */
float shadow(vec3 lightDir, float lightDist, vec3 p) {
    float res = 1.0f;
    float ph = 1e20;
    float depth = NEAR_CLIP;
    for (int i = 0; i < MAX_STEPS; i++) {
        Hit hit = scene(p + lightDir * depth);
        if (depth + hit.dist > lightDist) {
            break;
        }
        float y = hit.dist * hit.dist / (2.0 * ph);
        float d = sqrt(hit.dist * hit.dist - y * y);
        res = min(res, 8.0f * d / max(0.0, depth - y));
        depth += hit.dist;
        ph = hit.dist;
        if (res < EPS || depth >= FAR_CLIP) {
            break;
        }
    }
    return clamp(res, 0.0f, 1.0f);
}

float shadow(vec3 lightDir, vec3 p) {
    float res = 1.0f;
    float ph = 1e20;
    float depth = NEAR_CLIP;
    for (int i = 0; i < MAX_STEPS; i++) {
        Hit hit = scene(p + lightDir * depth);
        float y = hit.dist * hit.dist / (2.0 * ph);
        float d = sqrt(hit.dist * hit.dist - y * y);
        res = min(res, 8.0f * d / max(0.0, depth - y));
        depth += hit.dist;
        ph = hit.dist;
        if (res < EPS || depth >= FAR_CLIP) {
            break;
        }
    }
    return clamp(res, 0.0f, 1.0f);
}

/** Reflectance Calculation */
vec4 reflection(ObjHit poh, vec3 p, vec3 dirc, Lights l) {
    vec4 color = vec4(0.0);

    for (int i = 0; i < MAX_BOUNCES; i++) {
        if (poh.mat.reflectance == 0) {
            break;
        }

        Hit hit = raymarch(p, dirc);
        if (hit.dist <= FAR_CLIP - EPS) {
            ObjHit oh = object(hit.id, p + dirc * hit.dist);
            color = mix(color, shade(oh, p + dirc * hit.dist, p, l), poh.mat.reflectance);

            p = p + dirc * hit.dist;
            dirc = reflect(dirc, oh.norm);
            poh = oh;
        } else {
            color = mix(color, vec4(skyColor(p, dirc), 1.0), poh.mat.reflectance);
            break;
        }
    }
    return color;
}

/** Refractance Calculation */
vec4 refraction(ObjHit poh, vec3 p, vec3 dirc, Lights l) {
    vec4 color = vec4(0.0);

    p += dirc * 0.01;

    Hit hit = raymarchO(p, dirc);
    if (hit.dist <= FAR_CLIP - EPS) {
        p += dirc * hit.dist;
        ObjHit oh = object(hit.id, p);
        dirc = refract(dirc, -oh.norm, 1.0 / poh.mat.ior);

        p += dirc * 0.01;

        hit = raymarch(p, dirc);

        oh = object(hit.id, p + dirc * hit.dist);
        color = mix(color, shade(oh, p + dirc * hit.dist, p, l), poh.mat.refractance);
    } else {
        p += dirc * hit.dist;
        ObjHit oh = object(hit.id, p);
        dirc = refract(dirc, -oh.norm, 1.0 / poh.mat.ior);

        p += dirc * 0.01;

        color = mix(color, vec4(skyColor(p, dirc), 1.0), poh.mat.refractance);
    }
    return color;
}

/** PBR Lighting Model */
vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0f - f0) * pow(max(1.0f - cosTheta, 0.0f), 5.0f);
}

float distributionGGX(vec3 N, vec3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float dotNH = max(dot(N, H), 0.0f);
    float dotNH2 = dotNH * dotNH;
	
    float num = a2;
    float denom = (dotNH2 * (a2 - 1.0f) + 1.0f);
    denom = PI * denom * denom;
	
    return num / denom;
}

float geometrySchlickGGX(float dotNV, float roughness) {
    float r = (roughness + 1.0f);
    float k = (r * r) / 8.0f;

    float num   = dotNV;
    float denom = dotNV * (1.0f - k) + k;
	
    return num / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
    float dotNV = max(dot(N, V), 0.0f);
    float dotNL = max(dot(N, L), 0.0f);
    float ggx2  = geometrySchlickGGX(dotNV, roughness);
    float ggx1  = geometrySchlickGGX(dotNL, roughness);
	
    return ggx1 * ggx2;
}

// Cook-Torrance BRDF
vec3 lightC(Light light, ObjHit oh, vec3 p, vec3 eye) {
    // Normalized view direction
    vec3 viewDir = normalize(eye - p);

    // Normalized light direction
    vec3 lightDir = normalize(light.pos - p);
    // Normalized halfway direction between light and view
    vec3 halfwayDir = normalize(lightDir + viewDir);

    // Distance to light from point
    float dist = length(light.pos - p);
    // Inverse square law
    float attenuation = 1.0f / (dist * dist);
    vec3 radiance = light.intensity * attenuation;

    // Fresnel approximation
    vec3 f0 = vec3(0.04);
    f0 = mix(f0, oh.mat.albedo, oh.mat.metallic);
    vec3 f = fresnelSchlick(max(dot(halfwayDir, viewDir), 0.0f), f0);

    // Microfacet roughness estimation
    float ndf = distributionGGX(oh.norm, halfwayDir, oh.mat.roughness);
    // Microfacet occlusion estimation
    float g = geometrySmith(oh.norm, viewDir, lightDir, oh.mat.roughness);

    // Specular calculation
    vec3 num = ndf * g * f;
    float denom = 4.0f * max(dot(oh.norm, viewDir), 0.0f) * max(dot(oh.norm, lightDir), 0.0f);
    vec3 specular = num / max(denom, EPS);
    vec3 kS = f;

    // Diffuse calculation
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0f - oh.mat.metallic;

    // Calculate final color
    float dotNL = max(dot(oh.norm, lightDir), 0.0f);
    return (kD * oh.mat.albedo / PI + specular) * radiance * dotNL * shadow(lightDir, dist, p);
}

/** Shading function */
vec4 shade(ObjHit oh, vec3 p, vec3 eye, Lights l) {
    vec3 color = oh.mat.albedo * 0.03f * oh.mat.ambient;

    for (int i = 0; i < l.length(); i++) {
        color += lightC(l[i], oh, p, eye);
    }

    return vec4(color, 1.0);
}

/** Camera matrix calculation */
mat4 setCamera(vec3 eye, vec3 look, float rot) {
	vec3 cw = normalize(look - eye);
	vec3 cp = vec3(sin(rot), cos(rot), 0.0f);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
    return mat4(
        cu, 0,
        cv, 0,
        cw, 0,
        0, 0, 0, 1
    );
}

/** Ray to pixel function */
vec2 rayPixel(vec2 size, vec2 pos) {
    return (-size + 2.0f * pos) / size.y;
}

/** Shader io */
layout (set = 0, binding = 0) buffer boutf { float outf[]; };
layout (set = 0, binding = 1) buffer bsize { float size[]; };
layout (set = 0, binding = 3) buffer boffset { float offset[]; };

/** Main render function */
void main() {
    // calculate global id and offset
    uint gid = gl_GlobalInvocationID.x + (uint(offset[0]) * (uint(size[0] * size[1]) / 16));
    if (gid > (uint(offset[0] + 1) * (uint(size[0] * size[1]) / 16)) || gid < (uint(offset[0]) * (uint(size[0] * size[1]) / 16))) {
        return;
    }

    // decode 2d position from 1d array
    vec2 fpos = vec2(gid % uint(size[0]), gid / uint(size[0]));

    // Get camera data from scene
    Camera cam = camera();
    vec3 eye = cam.pos;
    vec3 look = cam.look;

    // Calculate ray direction based on pixel position
    vec2 rp = rayPixel(vec2(size[0], size[1]), fpos);
    // Apply view matrix to ray direction
    mat4 cm = setCamera(eye, look, 0.0);
    vec3 dirc = (cm * normalize(vec4(rp, FOV, 1))).xyz;

    // Raymarch
    Hit hit = raymarch(eye, dirc);

    // Background skycolor called from scene
    vec3 color = skyColor(eye, dirc);

    // Only compute color if hit
    if (hit.dist <= FAR_CLIP - EPS) {
        vec3 p = eye + dirc * hit.dist;

        // Get lights for frame
        Lights l = lights();
        // Get object hit data
        ObjHit oh = object(hit.id, p);

        // Allow scene to define custom shading
        #ifdef CUSTOM_SHADING
        vec4 res = cshade(oh, p, eye, l);
        #else
        vec4 res = shade(oh, p, eye, l);
        #endif

        // Mix final color
        color = color * (1.0f - res.w) + res.xyz;

        // Reflections
        if (oh.mat.reflectance > 0.0) {
            res = reflection(oh, p, reflect(dirc, oh.norm), l);
            color = mix(color, res.xyz, oh.mat.reflectance);
        }

        // Refraction
        if (oh.mat.refractance > 0.0) {
            res = refraction(oh, p, refract(dirc, oh.norm, oh.mat.ior / 1.0), l);
            color = mix(color, res.xyz, oh.mat.refractance);
        }
    }

    // Gamma correction
    color = color / (color + 1.0f);
    color = pow(color, vec3(1.0f / 2.2f));

    // Clamp color and output
    color = clamp(color, 0.0f, 1.0f);
    outf[gid * 3] = color.x;
    outf[gid * 3 + 1] = color.y;
    outf[gid * 3 + 2] = color.z;
}