# 04 — Toolchain runbook notes (Vivado / Vitis HLS 2024.2)

Everything in this file is hardware-gated; each run lands as one row in
`results/run_ledger.csv` with the evidence level it actually reached. Gate
discipline (docs/07): no phase advances while the previous phase's evidence
is PENDING.

## Phase 8 — HLS IP build (Vitis HLS 2024.2)

```bash
cd hls/gru_sequence && vitis_hls -f build.tcl   # csim -> csynth -> cosim -> export
cd hls/mnv2_features && vitis_hls -f build.tcl
```

Gate: csim must reproduce the Python oracle bit-exactly (score -7226 on
`gru_window.vec`) BEFORE csynth runs; cosim must reproduce it again after
synthesis. Every run appends one ledger row with the tool build id.

## Phase 1/8 — shell build (Vivado 2024.2)

```bash
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

Deliverable: routed shell on the K26 part; timing in `results/vivado/`;
WNS < 0 freezes the phase (no constraint relaxation without a ledger row +
an accepted review of the report).

## Phase 9 — board bring-up (KV260 + PYNQ 3.1.0)

1. Flash the Kria KV260 Starter Kit boot firmware that matches the 2024.2
   toolchain family, then boot the PYNQ 3.1.0 SD image.
2. Install the shell bitstream + the exported HLS IPs.
3. ILA-first DMA loopback: 150,528 B frame in, verify beats 9,410 / 82 / 3
   (docs/04) BEFORE enabling the live camera path.
4. Run `runtime/pynq_bringup.ipynb`: packet drivers, then the event watch
   (`bench/event_metrics.py` thresholds on the completion logit stream).
5. Record every board run in `results/run_ledger.csv` (evidence level
   "physical board").

## Reconciliation rules (repeat BUY-side checks)

- The exact part string resolved from the KV260 project (xck26-sfvc784-2LV-c)
  is reused verbatim by HLS and Vivado; never retype it.
- Tool versions recorded per run: `vitis_hls -version`, `vivado -version`,
  the PYNQ image id, and the board frame's boot firmware id.
- A routed-timing miss FREEZES the phase (no silent constraint relaxation):
  record WNS, the failing path report, and either close timing or step the
  clock back to the 150 MHz floor per docs/09 section 8.
