# Accelerator architecture — latency-first, hybrid wrapper, 2024.2 (roadmap evolution)

This document is the design authority for the hyper-optimized accelerator
build-out.  It supersedes the *schedulable baseline* (Section 7 of the
roadmap file) without touching the frozen numerical contract:
`model/integer_oracle/oracle.py` remains the single source of truth for
every integer in this document.

Decisions recorded from stakeholder answers (2024-11-06):

| Decision | Value |
| :---- | :---- |
| Toolchain | Vivado 2024.2 / Vitis HLS 2024.2 / PYNQ 3.1.0 |
| Composition | **Hybrid wrapper** — per-operator HLS cores as submodules + a thin RTL top wrapper owning DMA, stream splitting, control FSMs |
| First objective | **Latency** — single camera, lowest window→score delay; ≤ 400 cycles/step target; Fmax ≥ 200 MHz if timing closes |
| Skills / wiki | In-repo: `.vibe/skills/`, `docs/wiki/` |

## 1. End-to-end signal path

```
camera ──> PS (PYNQ 3.1.0, V4L2) ──> DMA (AXI HP0, 128-bit) ──> ingress (rtl)
        frame packet 150,528 B + ABI header (9,410 beats)
                │
                ▼
        mgr1_shell (CSR block + packet ingress + skid buffers)
                │
                ▼
        mgr1_accel_top (rtl/top)  ← THE hybrid wrapper (this build-out)
          ├─ layer distributor FSM (53 layers in the frozen graph)
          ├─ mgr1_conv_ip  (HLS dataflow cascade, DDR weight ring)
          ├─ mgr1_gru_ip   (HLS vector engine + resident weight banks)
          └─ stat writers → CSR counter snapshot ports
                │
                ▼
        completion packet (16 B) back to PS; event watcher in software
```

Software-side, `runtime/mgr1_driver.py` is the controllable surface:
packets are built with `runtime/packet_abi.py`, registers through the
generated accessors (`runtime/csr_defs.py`), and the event loop is
`bench/event_metrics.py` semantics.

## 2. Why the conv cascade, not the GRU, dominates frame latency

Per-frame accounting from the frozen worksheet (`tools/worksheet.py`):

| Segment | MACs | At 2,496 INT8 MAC/cycle | At 150 MHz | At 200 MHz |
| :---- | ----: | ----: | ----: | ----: |
| Conv cascade (53 layers) | 299,494,272 | ~120,000 cycles | 0.80 ms | 0.60 ms |
| GRU window (32 × 412) | 1,996,800 (dense) | schedulable | 113.52 µs | 85.1 µs |
| GRU cached replay | 2,064,384 incl. projection | schedulable | 85-114 µs | |

A 30 fps camera delivers a frame every 33.3 ms, so both fit; latency-first
therefore means: (a) fill the device's MAC throughput for the conv stack
(it is 12× the GRU), (b) shorten the GRU step issue schedule, (c) overlap
frame N's replay with frame N+1's conv (the roadmap's double-buffer rule).

## 3. Conv cascade architecture (per-op cores, dataflow)

Every layer is an independent HLS core compiled from one parameterized
body with per-layer parameters (FINN-style *layer engines*, one engine per
graph node; no runtime shape control — the graph is frozen by design and
configurability lives in the CSR/prog layer).

```
per layer core:
  hls::stream<V8> in                     // 8 activations per beat
  └─ ping-pong line buffers (k-1 rows)   // exact stencil, zero padding
  └─ windowed MAC array                  // unroll factor from Table 1
  └─ INT32 accumulators / bias / requantize (oracle primitives)
  └─ ReLU (int8 sat) where the graph says so
  └─ hls::stream<V8> out                 // next engine's input
```

**Design rule (from the xck26 budget):** the whole cascade runs at
`II = 1` beat per engine with per-engine unroll factors sized so the
*sum* of MACs/cycle across simultaneously-active engines ≤ 2,496
(1248 DSP48E2 × 2 INT8 MAC, the standard DSP-packing bound).  Because the
dataflow engines are a pipeline, the aggregate is bounded by the **largest
band pair**, not the sum (bands drain before the next layer saturates).

Table 1 — per-stage unroll (U) and burst-band choices (7×7 tail collapses):

| Stage band | Layers | per-pixel MACs | U (pixels in flight) | MACs/cycle |
| :---- | ---- | ----: | ----: | ----: |
| stem 3×3 s2 | 1 | 27 × 32 | 16 | 13,824 → 6 DSP-packs |
| 32-96ch Exp | 1 | 16 × 96 | 8 | 12,288 |
| 96-144ch Exp/Proj | 5 | ≤ 20,736 | 4 (pixel batch) | ≤ 20,736 |
| 320-960ch Exp/Proj | 7 | ≤ 153,600 | 1 (vectorized over C) | ≤ 19,200 |
| all depthwise | 16 | 9 × C | 8 | ≤ 13,824 |
| final 1×1 320→1280 | 1 | 409,600 | 2-4 | ≤ 24,576 |

Exact per-layer numbers are generated into `docs/09a-unroll-plan.md` by
`tools/gen_unroll_plan.py` (checked in; deterministic, seeded derived from
the worksheet — same generation discipline as the other generators).

**Weight transport:** conv weights total 2,189,760 B > on-chip 1.7 MB, so
they stream DDR→engines through a **weight ring on AXI HP1** with a
per-layer bank table (the same accounting the roadmap Section 5B ring
uses).  Weights are read once per layer per frame (no re-fetch inside a
layer); the ring's fill overlaps the previous layer's drain — budget:
burst ≥ 64 beats, one outstanding descriptor per layer.

**On-chip residency:** GRU weights (540,672 B) stay resident:
`w_ih` 491,520 B in URAM (URAM 36 Kb blocks = 4608 B; 491,520/4608 = 107
blocks; 96 available → 90% utilization) with the tail in BRAM, or BRAM
only if the URAM timing model prefers it (implementation decides; both
legal at the contract).

## 4. GRU engine (vectorized, latency-first)

The frozen step is `a ≡ W_ih x`, `u ≡ W_hh h`, `r,z,n` then commit.  The
illustrative engine was P=8 lanes, Q=16 inputs (issue 384 cycles/step +
28 overhead = 412).  Latency-first upgrades, all parameter changes of the
same engine (numbers still from `bench/gru_cycle_model.py` semantics):

| Knob | Baseline | Latency-first | Effect |
| :---- | ---- | ---- | :---- |
| `OUT_GROUP` (P) | 8 | 16 (dual banks) | recurrent issues 384 → 192/step |
| issue rate (banks) | 1 bank | 2 banks, 双 issue | 2 issues/cycle |
| step total | 412 | **192 + 28 = 220** | window 13,184 → **7,040** |
| hidden commit | 28-cycle sweep | pipelined with next step's first issues | hidden in flight, −6 cycles/step |

Sequencer RTL is already parameterized (`IN_TILE`, `OUT_GROUP`,
`STEP_OVERHEAD`, `PROJ_DRAIN`); the new work is the **dual-bank issue
(RTL) + the vectorized HLS hidden engine** that matches it.

## 5. Hybrid wrapper RTL (`rtl/top/mgr1_accel_top.sv`)

Responsibilities (and nothing more):
1. split the ingress's healthy frame stream into the layer-engine fan-in,
2. own the per-layer GO/busy FSM (CSR COMMAND SUBMIT → engine start →
   done collect → completion packet),
3. wire the weight ring (AXI HP1 master) and the GRU dispatch,
4. publish counters (CNT_ACCEPTED/COMPLETED/…-style snapshot pairs) into
   the CSR snapshot area (params already in `mgr1_csr` package),
5. expose ILA taps: `s_axis_*`, `pkt_accept`, engine start/done,
   weight-ring fills (ILA beat targets from docs/04 remain
   9,410 / 82 / 3).

The exported HLS IPs stay per-op (per answer 2): the wrapper binds
`mgr1_conv_ip` + `mgr1_gru_ip` through the stub file
(`rtl/shell/mgr1_ip_stub.sv` precedent; new file
`rtl/top/mgr1_ip_stubs.sv` documents both IP port maps until export).

## 6. Resource budget (xck26-sfvc784-2LV-c, before synthesis)

| Resource | Available | Est. budget | Notes |
| :---- | ----: | ----: | :---- |
| DSP48E2 | 1,248 | ≤ 1,104 (88%) | 2×INT8/DSP packing; leave timing margin |
| BRAM (36 Kb) | 288 | ~210 | line buffers + GRU banks + LUT ROMs |
| URAM | 96 | ≤ 107 → cap 96 | GRU w_ih; spill the tail to BRAM |
| LUT | 230,080 | ≤ 150,000 | control, packet fabric, requantize glue |
| Fmax | — | 200 MHz target, 150 MHz floor | 6.67 ns / 5.0 ns clocks; see §8 |

## 7. Software system (PYNQ 3.1.0)

`runtime/mgr1_driver.py` (new): allocates contiguous frames, packs header
beats via `runtime/packet_abi.py`, pushes to the ingress ring, polls/receives
completion packets, exposes `submit_frame() -> logit`, and the event loop
(`bench/event_metrics.py` thresholds).  `runtime/pynq_bringup.ipynb` is
retargeted to PYNQ 3.1.0 and extended: DMA loopback → per-op packet run →
live camera event watch.

## 8. Timing plan (latency-first, 2024.2)

- `aclk` primary constraint 5.0 ns (200 MHz) with a *known-good fallback*
  6.67 ns (150 MHz) constraint set; the routed WNS at 5.0 ns decides which
  is the submitted bitstream (runbook records both).
- Conv engines: `dataflow` region → no global II claim; per-engine `II=1`
  asserted via the pragmas; the wrapper is the only unpipelined logic
  (FSM depth ≤ 6 LUT levels on critical paths).
- GRU: dual issues need 2 × 512-bit weight bank reads/cycle → URAM dual
  port; formal sleeps to the routed report.

## 9. Verification plan (unchanged discipline, new artifacts)

| Level | Artifact | Runs here? |
| :---- | :---- | :---- |
| C simulation | optimized conv dataflow kernels vs golden `conv_sentinels.vec` + a new per-layer golden vector (gen discipline) | YES (zig c++ C++17) |
| C simulation | vectorized GRU engine vs `gru_window.vec` (same vectors, new kernel) | YES |
| Elaboration | `tools/check_rtl.py` extended to `rtl/top/` | YES |
| csim/cosim | Vitis HLS 2024.2 `build.tcl` per kernel | toolchain host |
| routed timing | `vivado/shell.tcl` on xck26, 2024.2 | toolchain host |
| board | KV260 + PYNQ 3.1.0 route | board host |

## 10. References (the primary inspirations, per the brief)

- FINN / FINN-R (Xilinx/AMD): per-layer streaming dataflow engines, line
  buffers, DSP packing — the direct model for §3.
- hls4ml (fast ML on FPGAs): HLS kernel + streaming inter-core wiring.
- NVidia DeepStream-class pipelines (video→meta eventing): the software
  event-loop separation in §7.
- TPU / Gemmini / NVDLA: systolic and tiled engines; the weight-ring +
  banked-resident split in §3 is the tiny-PRAM cousin of Gemmini's PE
  array fed by a DMA weight queue.
- Eyeriss / TENET (dataflow analysis): row-stationary vs weight-stationary
  scheduling; this design is weight-streaming-because-DRAM-bound for the
  conv stack, weight-resident for the GRU (both extremal points — a
  deliberate, budget-justified split).
- AMD Vitis HLS 2024.2 UG1399 dataflow & pragmas; UG949 Ultrafast at
  150/200 MHz; Kria KV260 official base/dynamic Vitis flows.
