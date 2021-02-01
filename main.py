# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt
import imageio
import argparse
import logging
import subprocess

# render size
SIZE = (320, 240)

# base render function
def render_base(args, folder):
    # change verbosity level
    kp_logger = logging.getLogger("kp")
    kp_logger.setLevel(50 - (max(min(args.verbose, 4), 0) * 10))

    # init manager
    mgr = kp.Manager(args.device)

    # shader inputs
    tensor_size = kp.Tensor(SIZE)
    tensor_frame = kp.Tensor([0])
    tensor_offset = kp.Tensor([0])
    tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

    # allocate memory on gpu
    mgr.eval_tensor_create_def([tensor_out, tensor_size, tensor_frame, tensor_offset])

    # read shader
    f = open(folder + args.scene + ".spv", "rb")

    # create sequences
    sq_sdf = mgr.create_sequence()
    sq_sdf.begin()
    sq_sdf.record_tensor_sync_device([tensor_frame])
    sq_sdf.end()

    sq_sdo = mgr.create_sequence()
    sq_sdo.begin()
    sq_sdo.record_tensor_sync_device([tensor_offset])
    sq_sdo.end()

    sq_r = mgr.create_sequence()
    sq_r.begin()
    sq_r.record_algo_data([tensor_out, tensor_size, tensor_frame, tensor_offset], f.read())
    sq_r.end()

    sq_sl = mgr.create_sequence()
    sq_sl.begin()
    sq_sl.record_tensor_sync_local([tensor_out])
    sq_sl.end()

    # close shader file
    f.close()

    # render frames
    for i in range(args.start, args.end + 1):
        if (args.verbose > 0):
            print("rendering frame {}".format(i))

        # run program
        tensor_frame[0] = i
        # copy frame to shader
        sq_sdf.eval()
        # split into smaller chunks
        for j in range(16):
            if (args.verbose > 1):
                print("- rendering chunk {}".format(j))

            tensor_offset[0] = j
            # copy offset to shader
            sq_sdo.eval()
            # run shader
            sq_r.eval()
        # copy frame from shader
        sq_sl.eval()

        # save frame to output
        frame = np.flip(np.array(tensor_out.data()).reshape((SIZE[1], SIZE[0], 3)), axis=0)
        plt.imsave("output/image{}.png".format(i), frame)


# render a spv scene
def render(args):
    render_base(args, "scenes/")


# render a python scene
def pyrender(args):
    # compile python shader
    with open("pyscenes/" + args.scene + ".py", "r") as f:
        exec(f.read())
    subprocess.run(["glslc", "-fshader-stage=compute", "-I.", "-O", "pyscenes/" + args.scene + ".glsl", "-o", "pyscenes/" + args.scene + ".spv"])

    render_base(args, "pyscenes/")


def gif(args):
    # generate gif
    image_list = []
    # read in images
    for it in range(args.start, args.end + 1):
        image_list.append(imageio.imread('output/image'+str(it)+'.png'))
    # generate gif from images
    imageio.mimwrite('out.gif', image_list, format='GIF', fps=24)


# argument parsing
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", "-v", default=0, action="count", help="change verbosity level")

    # create subcommand parsers
    subparsers = parser.add_subparsers(dest="subcommand", required=True, help="run subcommand")

    # render subcommand
    render_parser = subparsers.add_parser("render", help="render scene")
    render_parser.add_argument("scene", type=str, help="name of the scene to render")
    render_parser.add_argument("--start", default=0, help="frame to start rendering from")
    render_parser.add_argument("--end", default=0, help="frame to stop rendering on")
    render_parser.add_argument("--device", default=0, help="which device to render on")
    render_parser.set_defaults(func=render)

    # pyrender subcommand
    pyrender_parser = subparsers.add_parser("pyrender", help="render a python scene")
    pyrender_parser.add_argument("scene", type=str, help="name of the scene to render")
    pyrender_parser.add_argument("--start", default=0, help="frame to start rendering from")
    pyrender_parser.add_argument("--end", default=0, help="frame to stop rendering on")
    pyrender_parser.add_argument("--device", default=0, help="which device to render on")
    pyrender_parser.set_defaults(func=pyrender)

    # gif subcommand
    gif_parser = subparsers.add_parser("gif", help="turn rendered images into out.gif")
    gif_parser.add_argument("start", type=int, help="frame to start gif from")
    gif_parser.add_argument("end", type=int, help="frame to stop gif on")
    gif_parser.set_defaults(func=gif)

    args = parser.parse_args()
    args.func(args)