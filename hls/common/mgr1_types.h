// Shared numeric contract for the MGR1 HLS kernels (roadmap Phase 6).
//
// In Vitis HLS builds, ap_int/ap_uint from the HLS headers replace the
// plain integer typedefs below; the arithmetic and rounding rules are
// identical in both builds and are verified against model/integer_oracle.
//
// Frozen formats:
//   INT8 weights, symmetric, per-output-channel scales.
//   INT8 activations, per-tensor scale, zero point = real zero.
//   INT32 accumulators.
//   Gate inputs Q7.10 (INT16), round-half-to-even.
//   Gate LUT outputs and in-flight hidden state Q1.15 (INT16).
//   Committed hidden state Q7.8 (INT8); commit = arithmetic shift by 8
//   with round-half-to-even and saturation.

#ifndef MGR1_TYPES_H
#define MGR1_TYPES_H

#include <cstdint>
#include <limits>

#ifdef MGR1_HLS_BUILD
#include "ap_int.h"
typedef ap_int<8>  i8_t;
typedef ap_int<16> i16_t;
typedef ap_int<32> i32_t;
typedef ap_int<64> i64_t;
#else
typedef int8_t  i8_t;
typedef int16_t i16_t;
typedef int32_t i32_t;
typedef int64_t i64_t;
#endif

namespace mgr1 {

constexpr int Q15_ONE = 32767;
constexpr int Q15_MIN = -32768;
constexpr int GATE_FRAC = 10;
constexpr int HIDDEN_SHIFT = 8;

// Exact round-half-to-even of num/den, den > 0.
inline int64_t round_half_even(int64_t num, int64_t den) {
    int64_t q = num / den;
    int64_t r = num % den;
    int64_t r2 = 2 * r;
    if (r2 > den || (r2 == den && (q & 1))) q += 1;
    else if (r2 < -den || (r2 == -den && (q & 1))) q -= 1;
    return q;
}

inline int sat(int lo, int hi, int64_t v) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return static_cast<int>(v);
}

// Frozen requantization: multiply by a fixed-point multiplier, shift right
// with round-half-to-even on the exact product, add the zero point,
// saturate to the output type.
inline int requantize(int64_t acc, int32_t multiplier, int shift,
                      int zero_point = 0, int lo = -128, int hi = 127) {
    int64_t product = acc * static_cast<int64_t>(multiplier);
    int64_t rounded = (shift > 0) ? round_half_even(product, 1LL << shift)
                                  : product;
    return sat(lo, hi, rounded + zero_point);
}

// Q7.10 -> Q1.15 sigmoid, saturating at both tails.
int sigmoid_q15(int i);

// Q7.10 -> Q1.15 tanh, saturating at both tails.
int tanh_q15(int i);

}  // namespace mgr1

#endif  // MGR1_TYPES_H
