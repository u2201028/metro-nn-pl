# 9. Accelerator architecture — hybrid wrapper build-out (2024.2 family)

Decision record for the latency-first build-out on xck26-sfvc784-2LV-c.
Numerical exactness is NOT negotiable: `model/integer_oracle/oracle.py`
stays the single source of truth; every RTL/HLS artifact in this build-out
reproduces it bit-exactly at the boundaries already frozen in
`docs/03-integer-contract.md`.

## 9.1 Composition (decided)

```
        AXI-Stream (packet ABI v1, docs/04)
host DMA ──────────────► axis_packet_ingress ─┬─► mgr1_conv_ip ─┬─► egress skid ─► host
                                              │   (blackbox      │
                                              │    until 8A)     │
                                 csr_block ◄──┴── counters/faults �┘
```

- `rtl/top/mgr1_accel_top.sv` — structural composition root; binds the
  per-op IP pair; byte-derived from the verified shell so the Phase-1
  fabric (csr_block, ingress, egress skids) is reused, not reimplemented.
- `rtl/top/mgr1_ip_stubs.sv` — zero-effect blackbox stubs with the port
  maps the HLS 2024.2 export must fill (mgr1_conv_ip, mgr1_gru_ip).
- The shell (`rtl/shell/mgr1_shell.sv`) remains the Phase-1 fabric used
  for the pre-silicon XSim checks; the accel top supersedes it as the
  synthesis root from Phase 8A on.

## 9.2 Latency-first plan (per-op; single camera)

| Segment | Frozen baseline | Latency-first target | Mechanism |
| :---- | ----: | ----: | :---- |
| GRU step | 412 cyc | 220 cyc | dual weight banks (2 issues/cycle) + pipelined commit sweep |
| GRU window (32 steps) | 13,184 cyc | 7,040 cyc | step reduction only |
| Conv cascade (53 layers) | ~120 K cyc @ 2,496 MAC/cyc | engine-per-node dataflow | row-token transport (mgr1_stream.h), line buffers per node |
| Frame → completion | conv + window + assembly | overlap conv(N+1) with window(N) | replay ring is already double-buffered by contract |

## 9.3 Resource budget (xck26)

| Resource | Available | Budget | Notes |
| :---- | ----: | ----: | :---- |
| DSP48E2 | 1,248 | ≤ 1,104 (89 %) | 2×INT8 packed MACs; leave timing margin |
| BRAM36 | 288 | ~210 | line buffers, GRU w_hh bank, activation queues |
| URAM36 | 96 | ≤ 107 → cap 96 | GRU w_ih plane (491,520 B; 107 blocks; tail in BRAM) |
| LUT | 230,080 | ≤ 150 K | control + packet fabric + requantize glue |

## 9.4 Binding contract (Phase 8A)

- `rtl/top/mgr1_ip_stubs.sv` documents the port maps that the exported
  HLS IPs must match; the stubs are zero-effect idles so the top
  elaborates and passes the shell's XSim checks before silicon.
- The HLS export (`vitis_hls -f hls/gru_sequence/build.tcl`) replaces the
  stubs by IP versioning rules in docs/07; nothing else in the top may
  change at binding time.

## 9.5 Open items (Phase 6C, toolchain-host)

- Dataflow cascade C++ engines: the ROW-TOKEN transport contract is fixed
  here (mgr1_stream.h); the synthesizable engine bodies are written and
  verified on the toolchain host where csynth QoR feedback exists —
  writing them blind in this sandbox produced placeholder-grade guesses,
  which is exactly what the frozen-oracle discipline forbids.
- Weight-ring DMA sizing: one outstanding descriptor per layer, 64-beat
  bursts; sizing analysis lands with the first csynth utilization report.
