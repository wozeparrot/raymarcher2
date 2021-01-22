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

/** Normal estimation */
const vec2 kcn = vec2(1, -1);
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
    float depth = NEAR_CLIP;
    for (int i = 0; i < MAX_STEPS; i++) {
        Hit hit = scene(p + lightDir * depth);
        if (depth + hit.dist > lightDist) {
            break;
        }
        res = min(res, 10.0f * hit.dist / depth);
        depth += hit.dist;
        if (res < EPS || depth >= FAR_CLIP) {
            break;
        }
    }
    return clamp(res, 0.0f, 1.0f);
}

/** PBR Lighting Model */
vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0f - f0) * pow(max(1.0f - cosTheta, 0.0f), 5.0f);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float dotNH = max(dot(N, H), 0.0f);
    float dotNH2 = dotNH * dotNH;
	
    float num = a2;
    float denom = (dotNH2 * (a2 - 1.0f) + 1.0f);
    denom = PI * denom * denom;
	
    return num / denom;
}

float geometrySchlickGGX(float dotNV, float roughness)
{
    float r = (roughness + 1.0f);
    float k = (r * r) / 8.0f;

    float num   = dotNV;
    float denom = dotNV * (1.0f - k) + k;
	
    return num / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float dotNV = max(dot(N, V), 0.0f);
    float dotNL = max(dot(N, L), 0.0f);
    float ggx2  = geometrySchlickGGX(dotNV, roughness);
    float ggx1  = geometrySchlickGGX(dotNL, roughness);
	
    return ggx1 * ggx2;
}

vec3 lightC(Light light, Mat mat, vec3 p, vec3 eye) {
    vec3 norm = calcNormal(p);
    vec3 viewDir = normalize(eye - p);

    vec3 lightDir = normalize(light.pos - p);
    vec3 halfwayDir = normalize(lightDir + viewDir);

    float dist = length(light.pos - p);
    float attenuation = 1.0f / (dist * dist);
    vec3 radiance = light.intensity * attenuation;

    vec3 f0 = vec3(0.04);
    f0 = mix(f0, mat.albedo, mat.metallic);
    vec3 f = fresnelSchlick(max(dot(halfwayDir, viewDir), 0.0f), f0);

    float ndf = distributionGGX(norm, halfwayDir, mat.roughness);
    float g = geometrySmith(norm, viewDir, lightDir, mat.roughness);

    vec3 num = ndf * g * f;
    float denom = 4.0f * max(dot(norm, viewDir), 0.0f) * max(dot(norm, lightDir), 0.0f);
    vec3 specular = num / max(denom, EPS);

    vec3 kS = f;
    vec3 kD = vec3(1.0) - kS;

    kD *= 1.0f - mat.metallic;

    float dotNL = max(dot(norm, lightDir), 0.0f);
    return (kD * mat.albedo / PI + specular) * radiance * dotNL * shadow(lightDir, dist, p);
}

/** Shading function */
vec4 shade(Mat mat, vec3 p, vec3 eye) {
    vec3 color = mat.albedo * 0.03f * mat.ambient;

    for (int i = 0; i < LIGHT_COUNT; i++) {
        color += lightC(LIGHTS[i], mat, p, eye);
    }

    return vec4(color, 1.0);
}

/** Camera matrix calculation */
mat4 setCamera(vec3 eye, vec3 look, float rot ) {
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
layout (set = 0, binding = 2) buffer bframe { int frame[]; };

/** Main render function */
void main() {
    uint gid = gl_GlobalInvocationID.x;

    vec2 fpos = vec2(gid % uint(size[0]), gid / uint(size[0]));

    Camera cam = camera(frame[0]);
    vec3 eye = cam.pos;
    vec3 look = cam.look;

    vec2 rp = rayPixel(vec2(size[0], size[1]), fpos);
    mat4 cm = setCamera(eye, look, 0.0f);
    vec3 dirc = (normalize(vec4(rp, FOV, 1)) * cm).xyz;

    // Raymarch
    Hit hit = raymarch(eye, dirc);

    // Background skycolor called from scene
    vec3 color = skyColor(eye, dirc);

    // Only compute color if hit
    if (hit.dist <= FAR_CLIP - EPS) {
        vec4 res = shade(hit.mat, eye + dirc * hit.dist, eye);
        color = color * (1.0f - res.w) + res.xyz;
    }

    // Color correction
    color = color / (color + 1.0f);
    color = pow(color, vec3(1.0f / 2.2f));

    // Clamp color and output
    color = clamp(color, 0.0f, 1.0f);
    outf[gid * 3] = color.x;
    outf[gid * 3 + 1] = color.y;
    outf[gid * 3 + 2] = color.z;
}