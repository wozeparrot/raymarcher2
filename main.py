# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import imageio

SIZE = (640, 480)

if (sys.argv[1] == "render"):
    # init manager
    mgr = kp.Manager(int(sys.argv[5]))

    # shader inputs
    tensor_size = kp.Tensor(SIZE)
    tensor_frame = kp.Tensor([0])
    tensor_offset = kp.Tensor([0])
    tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

    # allocate memory on gpu
    mgr.eval_tensor_create_def([tensor_out, tensor_size, tensor_frame, tensor_offset])

    # read shader
    f = open("scenes/" + sys.argv[2] + ".spv", "rb")

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
    for i in range(int(sys.argv[3]), int(sys.argv[4])):
        print("rendering frame {}".format(i))

        # run program
        tensor_frame[0] = i
        sq_sdf.eval()
        # split into smaller chunks
        for j in range(16):
            print("- rendering chunk {}".format(j))
            tensor_offset[0] = j
            sq_sdo.eval()
            sq_r.eval()
        sq_sl.eval()

        # save frame to output
        frame = np.flip(np.array(tensor_out.data()).reshape((SIZE[1], SIZE[0], 3)), axis=0)
        plt.imsave("output/image{}.png".format(i), frame)
elif (sys.argv[1] == "gif"):
    # generate gif
    image_list = []
    # read in images
    for it in range(int(sys.argv[2]), int(sys.argv[3])):
        image_list.append(imageio.imread('output/image'+str(it)+'.png'))
    # generate gif from images
    imageio.mimwrite('out.gif', image_list, format='GIF', fps=24)
