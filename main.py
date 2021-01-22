# imports
import kp
import sys
import numpy as np
import matplotlib.pyplot as plt

SIZE = (320, 240)

mgr = kp.Manager()

tensor_size = kp.Tensor(SIZE)
tensor_frame = kp.Tensor([0])
tensor_out = kp.Tensor(np.zeros((SIZE[0] * SIZE[1] * 3)))

mgr.eval_tensor_create_def([tensor_out, tensor_size, tensor_frame])

# read shader
f = open("scenes/" + sys.argv[1] + ".spv", "rb")

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
