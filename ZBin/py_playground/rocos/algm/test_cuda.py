from numba import cuda
import numpy as np
import math

# @cuda.jit
# def my_kernel(io_array):
#     pos = cuda.grid(1)
#     if pos < io_array.size:
#         io_array[pos] *= 2 # do the computation

# # Host code   
# data = np.ones(256)
# threadsperblock = 256
# blockspergrid = math.ceil(data.shape[0] / threadsperblock)
# my_kernel[blockspergrid, threadsperblock](data)
# print(data)

# -------------------

@cuda.jit
def matmul(A, B, C):
    """Perform matrix multiplication of C = A * B
    """
    row, col = cuda.grid(2)
    if row < C.shape[0] and col < C.shape[1]:
        tmp = 0.
        for k in range(A.shape[1]):
            tmp += A[row, k] * B[k, col]
        C[row, col] = tmp