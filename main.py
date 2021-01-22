# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt

SIZE = (320, 240)

mgr = kp.Manager()

tensor_size = kp.Tensor([2, 2, 2])
tensor_frame = kp.Tensor([0])
tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

mgr.eval_tensor_create_def([tensor_size, tensor_frame, tensor_out])

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

frame = np.array(tensor_out.data()).reshape((SIZE[1], SIZE[0], 3))
plt.imsave("image.png", frame)
