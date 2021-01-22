# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import imageio

SIZE = (400, 300)

if (sys.argv[1] == "render"):
    mgr = kp.Manager(int(sys.argv[5]))

    tensor_size = kp.Tensor(SIZE)
    tensor_frame = kp.Tensor([0])
    tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

    mgr.eval_tensor_create_def([tensor_out, tensor_size, tensor_frame])

    # read shader
    f = open("scenes/" + sys.argv[2] + ".spv", "rb")

    # create program
    sq = mgr.create_sequence()
    sq.begin()
    sq.record_tensor_sync_device([tensor_frame])
    sq.record_algo_data([tensor_out, tensor_size, tensor_frame], f.read())
    sq.record_tensor_sync_local([tensor_out])
    sq.end()

    # close shader file
    f.close()

    # render frames
    for i in range(int(sys.argv[3]), int(sys.argv[4])):
        print("rendering frame {}".format(i))

        # run program
        tensor_frame[0] = i
        sq.eval()

        # save frame to output
        frame = np.flip(np.array(tensor_out.data()).reshape((SIZE[1], SIZE[0], 3)), axis=0)
        plt.imsave("output/image{}.png".format(i), frame)
elif (sys.argv[1] == "gif"):
    # generate gif
    image_path = Path('output/')
    images = list(image_path.glob('image*.png'))
    image_list = []
    for png in images:
        image_list.append(imageio.imread(png))
    imageio.mimwrite('out.gif', image_list, fps=24)
