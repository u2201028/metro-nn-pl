// GRU sequence kernel (roadmap Phase 6 / Section 3).
//
// One GRU step at the frozen integer boundaries, plus the single-logit
// classifier head.  Gate order is the exported PyTorch order
// (reset, update, new):
//   a = W_ih x + b_ih ;  u = W_hh h_prev + b_hh
//   r = sigmoid(a_r + u_r) ;  z = sigmoid(a_z + u_z)
//   n = tanh(a_n + r * u_n)
//   h = (1 - z) * n + z * h_prev
//
// The cached input projection must be the identical INT32 intermediate, at
// the same precision and rounding location, that the uncached path consumes.
//
// Synthesis notes (interface / pragma directives, Phase 6/8A):
//   - Local state is fixed-capacity storage (MGR1_MAX_H), not heap: no
//     malloc in the synthesizable path.  Loop bodies gate on the runtime
//     h_size so any h_size <= MGR1_MAX_H is bit-identical to the oracle.
//   - The PIPELINE directives below fix initiation interval 1 on the MAC and
//     gate loops; they change QoR only and do not touch the schedule
//     arithmetic, which is verified bit-exactly by tb_gru against the
//     golden vectors.
//   - Block-level control and port binding are left at the build.tcl flow's
//     defaults (ap_ctrl_hs block control, ap_memory arrays): the exported
//     IP is instantiated by the Vivado shell, see docs/07-vivado-runbook.md.

#include "gru_top.hpp"

namespace mgr1 {

void gru_step(const int* x, const int* h_prev,
              const int8_t* w_ih, const int8_t* w_hh,
              const int32_t* b_ih, const int32_t* b_hh,
              int32_t mult_gx, int32_t shift_gx,
              int32_t mult_gh, int32_t shift_gh,
              int* h_out, int h_size) {
    build_luts();
    int32_t a_ar[3 * MGR1_MAX_H];
    int32_t u_ar[3 * MGR1_MAX_H];
    int r[MGR1_MAX_H];
    int z[MGR1_MAX_H];
    int n[MGR1_MAX_H];
    // Input affine: a = W_ih x + b_ih, INT32.
    for (int i = 0; i < 3 * h_size; ++i) {
        int64_t acc = b_ih[i];
        for (int j = 0; j < 1280; ++j) {
#pragma HLS PIPELINE II = 1
            acc += static_cast<int64_t>(w_ih[i * 1280 + j]) * x[j];
        }
        a_ar[i] = static_cast<int32_t>(acc);
    }
    // Recurrent affine: u = W_hh h_prev + b_hh, INT32.
    for (int i = 0; i < 3 * h_size; ++i) {
        int64_t acc = b_hh[i];
        for (int j = 0; j < h_size; ++j) {
#pragma HLS PIPELINE II = 1
            acc += static_cast<int64_t>(w_hh[i * h_size + j]) * h_prev[j];
        }
        u_ar[i] = static_cast<int32_t>(acc);
    }
    // Gates in Q1.15 after requantizing both branches to Q7.10.
    for (int i = 0; i < h_size; ++i) {
#pragma HLS PIPELINE II = 1
        int gi = requantize(static_cast<int64_t>(a_ar[i]) + u_ar[i],
                            mult_gx, shift_gx, 0, Q15_MIN, Q15_ONE);
        int zi = requantize(static_cast<int64_t>(a_ar[h_size + i]) + u_ar[h_size + i],
                            mult_gx, shift_gx, 0, Q15_MIN, Q15_ONE);
        int ni = requantize(static_cast<int64_t>(a_ar[2 * h_size + i]) + u_ar[2 * h_size + i],
                            mult_gx, shift_gx, 0, Q15_MIN, Q15_ONE);
        r[i] = sigmoid_q15(gi);
        z[i] = sigmoid_q15(zi);
        n[i] = tanh_q15(ni);
    }
    // h = (1 - z) * n + z * h_prev, all in Q1.15; each product is rounded
    // half-to-even back to Q1.15 before the saturating sum.  Committing
    // rounds half-to-even to Q7.8 and saturates, exactly as the oracle.
    for (int i = 0; i < h_size; ++i) {
#pragma HLS PIPELINE II = 1
        int64_t zh = static_cast<int64_t>(z[i]) * (h_prev[i] << HIDDEN_SHIFT);
        int64_t zh_q = round_half_even(zh, Q15_ONE);
        int64_t keep = static_cast<int64_t>(Q15_ONE - z[i]) * n[i];
        int64_t keep_q = round_half_even(keep, Q15_ONE);
        int64_t hv = keep_q + zh_q;
        int committed = sat(-128, 127, round_half_even(hv, 1 << HIDDEN_SHIFT));
        h_out[i] = committed;
    }
}

int32_t gru_score(const int* h, const int8_t* head_w, int32_t head_b,
                  int h_size) {
    int64_t acc = head_b;
    for (int i = 0; i < h_size; ++i) {
#pragma HLS PIPELINE II = 1
        acc += static_cast<int64_t>(h[i]) * head_w[i];
    }
    return static_cast<int32_t>(acc);
}

}  // namespace mgr1
