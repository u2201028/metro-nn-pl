#ifndef MGR1_GRU_TOP_H
#define MGR1_GRU_TOP_H

#include "mgr1_types.h"

namespace mgr1 {

// One GRU step at the frozen integer boundaries.  h_prev and h_out are
// committed Q7.8 states; x is the INT8 input projection operand.
void gru_step(const int* x, const int* h_prev,
              const int8_t* w_ih, const int8_t* w_hh,
              const int32_t* b_ih, const int32_t* b_hh,
              int32_t mult_gx, int32_t shift_gx,
              int32_t mult_gh, int32_t shift_gh,
              int* h_out, int h_size);

// Single-logit classifier head: 128 MACs + bias.
int32_t gru_score(const int* h, const int8_t* head_w, int32_t head_b,
                  int h_size);

// LUT builders / lookups shared by all kernels (defined in
// hls/common/activation_luts.cpp).
void build_luts();
int sigmoid_q15(int i);
int tanh_q15(int i);

}  // namespace mgr1

#endif  // MGR1_GRU_TOP_H
