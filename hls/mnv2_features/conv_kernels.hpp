// PUBLIC prototypes of the MobileNetV2 integer conv kernels.
// Definitions live in conv_kernels.cpp (design file).  The testbench
// includes this HEADER only - including the .cpp from the tb would collide
// with build.tcl's add_files during the Vitis csim/cosim link.

#ifndef MGR1_CONV_KERNELS_H
#define MGR1_CONV_KERNELS_H

#include "mgr1_types.h"

namespace mgr1 {

void conv2d_int8(const int8_t* x, const int8_t* w, const int32_t* b,
                 int zx, const int32_t* mult, const int32_t* shift,
                 int zout,
                 int hin, int win, int cin,
                 int cout, int kh, int kw,
                 int stride, int pad,
                 int8_t* out);

void depthwise_conv2d_int8(const int8_t* x, const int8_t* w, const int32_t* b,
                           int zx, const int32_t* mult, const int32_t* shift,
                           int zout,
                           int hin, int win, int cin,
                           int kh, int kw,
                           int stride, int pad,
                           int8_t* out);

// LUT builders / lookups (hls/common/activation_luts.cpp).
void build_luts();
int sigmoid_q15(int i);
int tanh_q15(int i);

}  // namespace mgr1

#endif  // MGR1_CONV_KERNELS_H
