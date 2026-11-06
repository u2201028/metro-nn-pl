// Portable single-producer/single-consumer FIFO for the MGR1 dataflow
// cascade.  One header, two worlds:
//   - plain C++17 (sandbox C simulation, zig c++ / g++): a bounded ring.
//   - Vitis HLS 2024.2: the same access pattern maps to hls::stream when
//     MGR1_HLS_BUILD is defined by the toolchain flow.
// DEPTH is a compile-time bound; push() in csim asserts on overflow, so any
// in-sandbox violation is caught immediately instead of wrapping silently.

#ifndef MGR1_STREAM_H
#define MGR1_STREAM_H

#include <cassert>

#ifdef MGR1_HLS_BUILD
#include "ap_int.h"
#include "hls_stream.h"
#endif

#include "mgr1_types.h"

namespace mgr1 {

#ifdef MGR1_HLS_BUILD

template <typename T, int DEPTH>
struct fifo {
    hls::stream<T> s;
    explicit fifo(const char* name = "mgr1_fifo") : s(name) {}
    void push(const T& v) { s.write(v); }
    T pop() { return s.read(); }
    bool empty() const { return s.empty(); }
    bool full() const { return s.full(); }
};

#else  // C-simulation model

template <typename T, int DEPTH>
struct fifo {
    static_assert(DEPTH > 0, "fifo depth must be positive");
    T buf[DEPTH];
    int rd, wr, cnt;
    explicit fifo(const char* = "mgr1_fifo")
        : rd(0), wr(0), cnt(0) {}

    void push(const T& v) {
        assert(cnt < DEPTH && "fifo overflow in cascade");
        buf[wr] = v;
        wr = (wr + 1) % DEPTH;
        ++cnt;
    }

    T pop() {
        assert(cnt > 0 && "fifo underflow in cascade");
        T v = buf[rd];
        rd = (rd + 1) % DEPTH;
        --cnt;
        return v;
    }

    T front() const {
        assert(cnt > 0 && "front() on empty fifo");
        return buf[rd];
    }

    bool empty() const { return cnt == 0; }
    bool full() const { return cnt == DEPTH; }
};

#endif  // MGR1_HLS_BUILD

}  // namespace mgr1

#endif  // MGR1_STREAM_H
