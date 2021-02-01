# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt
import imageio
import argparse
import logging
import subprocess

# silent import pygame
import contextlib
with contextlib.redirect_stdout(None):
    import pygame

# base render function
def render_base(args, folder):
    SIZE = (args.width, args.height)

    # pygame setup if visual enabled
    surf = None
    if (args.vis):
        pygame.init()
        surf = pygame.display.set_mode(SIZE)

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

        # visualize
        if (args.vis):
            # create surface from array
            surf2 = pygame.surfarray.make_surface(np.swapaxes(frame, 0, 1) * 255)

            # weird pygame bug
            surf.blit(surf2, (0, 0))
            pygame.display.update()
            surf.blit(surf2, (0, 0))
            pygame.display.update()

            # stop on last frame
            if (i == args.end):
                while True:
                    for event in pygame.event.get():
                        if event.type == pygame.QUIT:
                            quit()


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


# generate gif
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
    render_parser.add_argument("--start", type=int, default=0, help="frame to start rendering from")
    render_parser.add_argument("--end", type=int, default=0, help="frame to stop rendering on")
    render_parser.add_argument("--device", type=int, default=0, help="which device to render on")
    render_parser.add_argument("--width", type=int, default=320, help="width of image to render")
    render_parser.add_argument("--height", type=int, default=240, help="height of image to render")
    render_parser.add_argument("--vis", action="store_true", help="show frames after rendering")
    render_parser.set_defaults(func=render)

    # pyrender subcommand
    pyrender_parser = subparsers.add_parser("pyrender", help="render a python scene")
    pyrender_parser.add_argument("scene", type=str, help="name of the scene to render")
    pyrender_parser.add_argument("--start", type=int, default=0, help="frame to start rendering from")
    pyrender_parser.add_argument("--end", type=int, default=0, help="frame to stop rendering on")
    pyrender_parser.add_argument("--device", type=int, default=0, help="which device to render on")
    pyrender_parser.add_argument("--width", type=int, default=320, help="width of image to render")
    pyrender_parser.add_argument("--height", type=int, default=240, help="height of image to render")
    pyrender_parser.add_argument("--vis", action="store_true", help="show frames after rendering")
    pyrender_parser.set_defaults(func=pyrender)

    # gif subcommand
    gif_parser = subparsers.add_parser("gif", help="turn rendered images into out.gif")
    gif_parser.add_argument("start", type=int, help="frame to start gif from")
    gif_parser.add_argument("end", type=int, help="frame to stop gif on")
    gif_parser.set_defaults(func=gif)

    args = parser.parse_args()
    args.func(args)