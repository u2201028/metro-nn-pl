// MobileNetV2 integer convolution kernels (roadmap Section 4 / Phase 6).
//
// Signed INT8 convolutions with INT32 accumulation, signed zero point,
// exact padding (pad value = input zero point), stride 1 or 2, and
// channel tails handled by masks.  Reduction order: input channel
// outermost, then kernel rows and columns; the bias is added once after
// the full reduction.  Requantization follows the frozen record in
// model/integer_oracle/oracle.py.  Both kernels produce channel-major
// (CHW) output tensors.

#include "mgr1_types.h"

namespace mgr1 {

void conv2d_int8(const int8_t* x, const int8_t* w, const int32_t* b,
                 int zx, const int32_t* mult, const int32_t* shift,
                 int zout,
                 int hin, int win, int cin,
                 int cout, int kh, int kw,
                 int stride, int pad,
                 int8_t* out) {
    const int hout = (hin + 2 * pad - kh) / stride + 1;
    const int wout = (win + 2 * pad - kw) / stride + 1;
    for (int oc = 0; oc < cout; ++oc) {
        for (int oy = 0; oy < hout; ++oy) {
            for (int ox = 0; ox < wout; ++ox) {
                int64_t acc = b[oc];
                for (int ic = 0; ic < cin; ++ic) {
                    for (int ky = 0; ky < kh; ++ky) {
                        for (int kx = 0; kx < kw; ++kx) {
                            const int iy = oy * stride + ky - pad;
                            const int ix = ox * stride + kx - pad;
                            if (iy >= 0 && iy < hin && ix >= 0 && ix < win) {
                                acc += (static_cast<int64_t>(x[(iy * win + ix) * cin + ic]) - zx)
                                     * w[((oc * cin + ic) * kh + ky) * kw + kx];
                            }
                        }
                    }
                }
                out[((oc * hout + oy) * wout + ox)] =
                    static_cast<int8_t>(requantize(acc, mult[oc], shift[oc], zout));
            }
        }
    }
}

void depthwise_conv2d_int8(const int8_t* x, const int8_t* w, const int32_t* b,
                           int zx, const int32_t* mult, const int32_t* shift,
                           int zout,
                           int hin, int win, int cin,
                           int kh, int kw,
                           int stride, int pad,
                           int8_t* out) {
    const int hout = (hin + 2 * pad - kh) / stride + 1;
    const int wout = (win + 2 * pad - kw) / stride + 1;
    for (int c = 0; c < cin; ++c) {
        for (int oy = 0; oy < hout; ++oy) {
            for (int ox = 0; ox < wout; ++ox) {
                int64_t acc = b[c];
                for (int ky = 0; ky < kh; ++ky) {
                    for (int kx = 0; kx < kw; ++kx) {
                        const int iy = oy * stride + ky - pad;
                        const int ix = ox * stride + kx - pad;
                        if (iy >= 0 && iy < hin && ix >= 0 && ix < win) {
                            acc += (static_cast<int64_t>(x[(iy * win + ix) * cin + c]) - zx)
                                 * w[c * kh * kw + ky * kw + kx];
                        }
                    }
                }
                out[(c * hout + oy) * wout + ox] =
                    static_cast<int8_t>(requantize(acc, mult[c], shift[c], zout));
            }
        }
    }
}

}  // namespace mgr1
