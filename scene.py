# global list of lights
lights = []
# global dict of objects
objects = {}
# global list of materials
materials = {}

# camera
cam_pos = (0, 0, 0)
cam_look = (0, 1, 0)

# global settings
EPS = 0.001
MAX_STEPS = 4096
NEAR_CLIP = 0.01
FAR_CLIP = 128
FOV = 1.5
MAX_BOUNCES = 2

# generates scene file
def generate(name):
    # declare globals
    global lights, objects, materials
    global cam_pos, cam_look
    global EPS, MAX_STEPS, NEAR_CLIP, FAR_CLIP, FOV, MAX_BOUNCES

    # open file
    f = open("pyscenes/" + name + ".glsl", "w")

    f.write("#version 450\n\n")

    # generate settings
    f.write("const float EPS = {};\n".format(EPS))
    f.write("const int MAX_STEPS = {};\n".format(MAX_STEPS))
    f.write("const float NEAR_CLIP = {};\n".format(NEAR_CLIP))
    f.write("const float FAR_CLIP = {};\n".format(FAR_CLIP))
    f.write("const float FOV = {};\n".format(FOV))
    f.write("const int MAX_BOUNCES = {};\n".format(MAX_BOUNCES))
    f.write("#define Lights Light[{}]\n\n".format(len(lights)))

    f.write("#include \"pre.glsl\"\n\n")

    # generate materials
    for i, (name, mat) in enumerate(materials.items()):
        f.write("const Mat mat_{} = Mat(\n".format(name))
        f.write("\tvec3{},\n".format(mat[0]))
        f.write("\t{},\n".format(mat[1]))
        f.write("\t{},\n".format(mat[2]))
        f.write("\t{},\n".format(mat[3]))
        f.write("\t{},\n".format(mat[4]))
        f.write("\t{},\n".format(mat[5]))
        f.write("\t{}\n".format(mat[6]))
        f.write(");\n\n")

    # generate objhits
    for i, (name, obj) in enumerate(objects.items()):
        f.write("#define obj_{} {}\n".format(name, i))

        f.write("ObjHit obj_{}OH(vec3 p) {{\n".format(name))
        f.write("\tvec3 norm = calcNormal(p);\n")
        f.write("\treturn ObjHit(norm, mat_{});\n".format(obj[3]))
        f.write("}\n\n")
    
    # generate object id switch
    f.write("ObjHit object(uint id, vec3 p) {\n")
    f.write("\tswitch (id) {\n")
    for i, (name, obj) in enumerate(objects.items()):
        f.write("\t\tcase obj_{}:\n".format(name))
        f.write("\t\treturn obj_{}OH(p);\n".format(name))
    f.write("\t}\n}\n\n")

    # generate object sdfs
    for i, (name, obj) in enumerate(objects.items()):
        if (obj[0] == "sphere"):
            f.write("Hit obj_{}SDF(vec3 p) {{\n".format(name))
            f.write("\tp -= vec3{};\n".format(obj[1]))
            f.write("\tHit hit;\n")
            f.write("\thit.id = obj_{};\n".format(name))
            f.write("\thit.dist = length(p) - 1;\n")
            f.write("\treturn hit;\n")
            f.write("}\n\n")
        elif (obj[0] == "box"):
            pass
        elif (obj[0] == "plane"):
            f.write("Hit obj_{}SDF(vec3 p) {{\n".format(name))
            f.write("\tp -= vec3{};\n".format(obj[1]))
            f.write("\tHit hit;\n")
            f.write("\thit.id = obj_{};\n".format(name))
            f.write("\thit.dist = p.y;\n")
            f.write("\treturn hit;\n")
            f.write("}\n\n")
            pass
    
    # generate scene function
    f.write("Hit scene(vec3 p) {\n")
    f.write("\tHit hmin;\n")
    f.write("\thmin.dist = {};\n".format(FAR_CLIP + NEAR_CLIP + EPS))
    f.write("\tHit hit;\n")
    for i, (name, obj) in enumerate(objects.items()):
        f.write("\thit = obj_{}SDF(p);\n".format(name))
        f.write("\tif (hit.dist < hmin.dist) {\n")
        f.write("\t\thmin = hit;\n")
        f.write("\t}\n")
    f.write("\treturn hmin;\n")
    f.write("}\n\n")

    # generate camera function
    f.write("Camera camera() {\n")
    f.write("\tCamera c;\n")
    f.write("\tc.pos = vec3{};\n".format(cam_pos))
    f.write("\tc.look = vec3{};\n".format(cam_look))
    f.write("\treturn c;\n")
    f.write("}\n\n")

    # generate skycolor function
    f.write("vec3 skyColor(vec3 eye, vec3 dirc) {\n")
    f.write("\treturn (0.9f * vec3(0.4, 0.65, 1.0)) - (dirc.y * vec3(0.4, 0.36, 0.4));\n")
    f.write("}\n\n")

    # generate light function
    f.write("Lights lights() {\n")
    f.write("\treturn Lights(\n")
    for i, light in enumerate(lights):
        f.write("\t\tLight(vec3{}, vec3{})".format(light[0], light[1]))
        if (i != len(lights) - 1):
            f.write(",\n")
        else:
            f.write("\n")
    f.write("\t);\n}\n\n")

    f.write("#include \"main.glsl\"")

    # close file
    f.close()


def Object(name, kind, pos, scale, mat):
    # declare globals
    global objects

    # check if it is a supported object
    if (kind not in ["sphere", "box", "plane"]):
        return
    
    # put object into dict
    objects[name] = (kind, pos, scale, mat)


def Material(name, albedo, metallic, roughness, ambient, reflectance, refractance, ior):
    # declare globals
    global materials

    # put material into dict
    materials[name] = (albedo, metallic, roughness, ambient, reflectance, refractance, ior)


def Camera(pos, look):
    # declare globals
    global cam_pos, cam_look
    
    # set camera variables
    cam_pos = pos
    cam_look = look


def Light(pos, color):
    # declare globals
    global lights

    lights.append((pos, color))