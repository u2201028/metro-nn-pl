// Golden-vector testbench for the GRU sequence kernel (roadmap Phase 6/8).
//
// Reads the sectioned .vec format:
//   MGR1VEC 1
//   SECTION <name> <count>
//   <count integers, 16 per line, decimal>
//
// Replays 32 gru_step calls from zero state and compares every committed
// hidden state and the final score against the oracle expectations.
// On mismatch writes failure.txt with step/index/got/want and exits 1.

#include "gru_top.hpp"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

namespace {

struct VecFile {
    std::map<std::string, std::vector<int64_t>> sections;
};

bool read_vec(const std::string& path, VecFile& out, std::string& err) {
    std::ifstream in(path);
    if (!in) {
        err = "cannot open " + path;
        return false;
    }
    std::string token;
    if (!(in >> token) || token != "MGR1VEC") {
        err = "bad magic in " + path;
        return false;
    }
    int version = 0;
    in >> version;
    if (version != 1) {
        err = "unsupported MGR1VEC version";
        return false;
    }
    while (in >> token) {
        if (token != "SECTION") {
            err = "expected SECTION, got " + token;
            return false;
        }
        std::string name;
        int64_t count = 0;
        if (!(in >> name >> count)) {
            err = "malformed SECTION header";
            return false;
        }
        std::vector<int64_t> values(static_cast<size_t>(count));
        for (int64_t i = 0; i < count; ++i) {
            if (!(in >> values[static_cast<size_t>(i)])) {
                err = "truncated section " + name;
                return false;
            }
        }
        out.sections[name] = std::move(values);
    }
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: tb_gru <golden.vec>\n";
        return 2;
    }
    VecFile vec;
    std::string err;
    if (!read_vec(argv[1], vec, err)) {
        std::cerr << "error: " << err << "\n";
        return 2;
    }
    for (const auto& kv : vec.sections) {
        std::cout << "section " << kv.first << " (" << kv.second.size()
                  << " values)\n";
    }
    const auto& sec = vec.sections;
    if (!sec.count("I") || !sec.count("H") || !sec.count("T") ||
        !sec.count("mult_gx") || !sec.count("shift_gx") ||
        !sec.count("w_ih") || !sec.count("w_hh") || !sec.count("b_ih") ||
        !sec.count("b_hh") || !sec.count("frames") ||
        !sec.count("expected_states") || !sec.count("score")) {
        std::cerr << "error: missing required section\n";
        return 2;
    }
    const int I = static_cast<int>(sec.at("I")[0]);
    const int H = static_cast<int>(sec.at("H")[0]);
    const int T = static_cast<int>(sec.at("T")[0]);
    const int32_t mult_gx = static_cast<int32_t>(sec.at("mult_gx")[0]);
    const int32_t shift_gx = static_cast<int32_t>(sec.at("shift_gx")[0]);
    std::vector<int8_t> w_ih, w_hh, head_w;
    std::vector<int32_t> b_ih, b_hh;
    for (int64_t v : sec.at("w_ih")) w_ih.push_back(static_cast<int8_t>(v));
    for (int64_t v : sec.at("w_hh")) w_hh.push_back(static_cast<int8_t>(v));
    for (int64_t v : sec.at("b_ih")) b_ih.push_back(static_cast<int32_t>(v));
    for (int64_t v : sec.at("b_hh")) b_hh.push_back(static_cast<int32_t>(v));
    for (int64_t v : sec.at("head_w")) head_w.push_back(static_cast<int8_t>(v));

    std::vector<int> frames;
    for (int64_t v : sec.at("frames")) frames.push_back(static_cast<int>(v));
    const std::vector<int64_t>& want_states = sec.at("expected_states");
    const int32_t want_score = static_cast<int32_t>(sec.at("score")[0]);

    std::vector<int> h(static_cast<size_t>(H), 0);
    std::vector<int> got_states;
    got_states.reserve(static_cast<size_t>(T) * static_cast<size_t>(H));
    for (int t = 0; t < T; ++t) {
        mgr1::gru_step(frames.data() + static_cast<int64_t>(t) * I,
                       h.data(), w_ih.data(), w_hh.data(),
                       b_ih.data(), b_hh.data(),
                       mult_gx, shift_gx, mult_gx, shift_gx,
                       h.data(), H);
        for (int i = 0; i < H; ++i) {
            got_states.push_back(h[static_cast<size_t>(i)]);
        }
    }
    const int32_t got_score =
        mgr1::gru_score(h.data(), head_w.data(),
                        static_cast<int32_t>(sec.at("head_b")[0]), H);

    std::ofstream failure("failure.txt");
    bool ok = true;
    for (int t = 0; t < T && ok; ++t) {
        for (int i = 0; i < H; ++i) {
            const int64_t idx = static_cast<int64_t>(t) * H + i;
            const int64_t want = want_states[idx];
            const int got = got_states[idx];
            if (got != want) {
                failure << "step=" << t << " index=" << i
                        << " got=" << got << " want=" << want << "\n";
                ok = false;
                break;
            }
        }
    }
    if (ok && got_score != want_score) {
        failure << "step=score got=" << got_score
                << " want=" << want_score << "\n";
        ok = false;
    }
    if (!ok) {
        failure.close();
        std::cerr << "FAIL: mismatch, see failure.txt\n";
        return 1;
    }
    std::cout << "PASS: " << T << " steps x " << H
              << " hidden states match, score " << got_score << "\n";
    return 0;
}
