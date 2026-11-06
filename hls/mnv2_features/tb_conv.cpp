// Golden-vector testbench for the MobileNetV2 conv kernels (Phase 6/8).
//
// Reads conv_sentinels.vec, runs conv2d_int8, and compares every output
// element against the oracle expectations, then checks the requantization
// sentinel values (rounding ties, most-negative accumulator).

#include "mgr1_types.h"

#include "conv_kernels.cpp"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>

namespace {

bool read_vec(const std::string& path,
              std::map<std::string, std::vector<long long>>& out,
              std::string& err) {
    std::ifstream in(path);
    if (!in) {
        err = "cannot open " + path;
        return false;
    }
    std::string tok;
    if (!(in >> tok) || tok != "MGR1VEC") {
        err = "bad magic";
        return false;
    }
    long long ver = 0;
    in >> ver;
    if (ver != 1) {
        err = "unsupported version";
        return false;
    }
    while (in >> tok) {
        if (tok != "SECTION") {
            err = "expected SECTION, got " + tok;
            return false;
        }
        std::string name;
        long long count = 0;
        if (!(in >> name >> count)) {
            err = "malformed SECTION";
            return false;
        }
        std::vector<long long> v(static_cast<size_t>(count));
        for (long long i = 0; i < count; ++i) {
            if (!(in >> v[static_cast<size_t>(i)])) {
                err = "truncated section " + name;
                return false;
            }
        }
        out[name] = std::move(v);
    }
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: tb_conv <conv_sentinels.vec>\n";
        return 2;
    }
    std::map<std::string, std::vector<long long>> sec;
    std::string err;
    if (!read_vec(argv[1], sec, err)) {
        std::cerr << "error: " << err << "\n";
        return 2;
    }
    const int hin = static_cast<int>(sec["hin"][0]);
    const int win = static_cast<int>(sec["win"][0]);
    const int cin = static_cast<int>(sec["cin"][0]);
    const int cout_ = static_cast<int>(sec["cout"][0]);
    const int k = static_cast<int>(sec["k"][0]);
    const int stride = static_cast<int>(sec["stride"][0]);
    const int pad = static_cast<int>(sec["pad"][0]);
    const int zx = static_cast<int>(sec["zx"][0]);
    const int zout = static_cast<int>(sec["zout"][0]);

    std::vector<int8_t> x, w, want;
    std::vector<int32_t> b, mult, shift;
    for (long long v : sec["input"]) x.push_back(static_cast<int8_t>(v));
    for (long long v : sec["weights"]) w.push_back(static_cast<int8_t>(v));
    for (long long v : sec["bias"]) b.push_back(static_cast<int32_t>(v));
    for (long long v : sec["mult"]) mult.push_back(static_cast<int32_t>(v));
    for (long long v : sec["shift"]) shift.push_back(static_cast<int32_t>(v));
    for (long long v : sec["expected"]) want.push_back(static_cast<int8_t>(v));

    const int hout = hin + 2 * pad - k + 1;
    const int wout = win + 2 * pad - k + 1;
    std::vector<int8_t> out(static_cast<size_t>(cout_) * hout * wout, 0);
    mgr1::conv2d_int8(x.data(), w.data(), b.data(), zx, mult.data(),
                      shift.data(), zout, hin, win, cin, cout_, k, k,
                      stride, pad, out.data());

    int mismatches = 0;
    int first_bad = -1;
    for (size_t i = 0; i < out.size(); ++i) {
        if (out[i] != want[i]) {
            ++mismatches;
            if (first_bad < 0) first_bad = static_cast<int>(i);
        }
    }
    if (mismatches) {
        std::cerr << "FAIL: " << mismatches << " mismatches, first at "
                  << first_bad << " got=" << static_cast<int>(out[first_bad])
                  << " want=" << static_cast<int>(want[first_bad]) << "\n";
        return 1;
    }

    // Requantization sentinels: ties round to even, most-negative
    // accumulator saturates.
    const long long tp = mgr1::requantize(1000000, 18226, 21, 0);
    const long long tn = mgr1::requantize(-1000001, 18226, 21, 0);
    const long long mn = mgr1::requantize(-2147483648LL, 18226, 21, 0);
    if (tp != sec["tie_positive"][0] || tn != sec["tie_negative"][0] ||
        mn != sec["most_negative"][0]) {
        std::cerr << "FAIL: sentinel mismatch tp=" << tp << " tn=" << tn
                  << " mn=" << mn << "\n";
        return 1;
    }
    std::cout << "PASS: conv2d " << cout_ << "x" << hout << "x" << wout
              << " outputs match, sentinels match\n";
    return 0;
}
