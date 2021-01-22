# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import imageio
from pygifsicle import optimize

SIZE = (4096, 4096)

mgr = kp.Manager()

tensor_size = kp.Tensor(SIZE)
tensor_frame = kp.Tensor([0])
tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

mgr.eval_tensor_create_def([tensor_out, tensor_size, tensor_frame])

# read shader
f = open("a.spv", "rb")

# create program
sq = mgr.create_sequence()
sq.begin()
sq.record_tensor_sync_device([tensor_frame])
sq.record_algo_data([tensor_out, tensor_size, tensor_frame], f.read())
sq.record_tensor_sync_local([tensor_out])
sq.end()

# close shader file
f.close()

# run program
sq.eval()

frame = np.flip(np.array(tensor_out.data()).reshape((SIZE[1], SIZE[0], 3)), axis=0)
plt.imsave("image.png", frame)



# decomment once you're done
#image_path = Path('images')
#images = list(image_path.glob('*.png'))
#image_list = []
#for png in images:
#    image_list.append(imageio.imread(png))
#imageio.mimwrite('out.gif', image_list, fps=24)
#optimize('out.gif')
