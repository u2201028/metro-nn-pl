// Activation LUTs for the MGR1 kernels, bit-identical to
// model/integer_oracle/oracle.py (Phase 4 frozen contract).
//
// Domain: Q7.10 signed input -> Q1.15 signed output.  Table construction
// rounds half-to-even, matching Python's round(); std::nearbyint with the
// default FE_TONEAREST rounding mode gives the same result.

#include "mgr1_types.h"

#include <cmath>
#include <vector>

namespace mgr1 {

namespace {

std::vector<int> g_sigmoid_lut;
std::vector<int> g_tanh_lut;

}  // namespace

void build_luts() {
    if (!g_sigmoid_lut.empty()) return;
    g_sigmoid_lut.resize(65536);
    g_tanh_lut.resize(65536);
    const double e = 2.718281828459045;
    for (int i = -32768; i < 32768; ++i) {
        double s = 32767.0 / (1.0 + std::pow(e, -i / 1024.0));
        double t = 32767.0 * (std::pow(e, 2 * i / 1024.0) - 1.0)
                           / (std::pow(e, 2 * i / 1024.0) + 1.0);
        g_sigmoid_lut[i + 32768] = static_cast<int>(std::nearbyint(s));
        g_tanh_lut[i + 32768] = static_cast<int>(std::nearbyint(t));
    }
}

int sigmoid_q15(int i) {
    build_luts();
    return g_sigmoid_lut[sat(-32768, 32767, i) + 32768];
}

int tanh_q15(int i) {
    build_luts();
    return g_tanh_lut[sat(-32768, 32767, i) + 32768];
}

}  // namespace mgr1
