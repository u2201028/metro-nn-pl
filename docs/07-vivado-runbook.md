# Vivado / Vitis 2024.2 runbook (KV260 / xck26-sfvc784-2LV-c)

**Toolchain lock:** Vivado 2024.2 + Vitis HLS 2024.2 on the FPGA host;
PYNQ 3.1.0 image on the KV260.  Everything in this file is hardware-gated:
each step's evidence lands in `results/run_ledger.csv` and the status flips
in `docs/01-acceptance-record.md` when IT RUNS — never before.

## Phase 8 — HLS IP build (Vitis HLS 2024.2)

```bash
cd hls/gru_sequence && vitis_hls -f build.tcl   # csim -> csynth -> cosim -> export
cd hls/mnv2_features && vitis_hls -f build.tcl
```

Gate per docs/04 + docs/09: the csim stage must reproduce the Python oracle
bit-exactly (score −7226 on `gru_window.vec`); the cosim stage must
reproduce the same integers through the generated RTL.  Each run appends
one `run_ledger.csv` row (tool_version = the 2024.2 build id).

## Phase 1/8 — Shell build (Vivado 2024.2)

```bash
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

Deliverables: routed shell with the CSR block + ingress + skid buffers,
`mgr1_ip` bound through `rtl/shell/mgr1_ip_stub.sv` (stub until the HLS
export exists), timing/utility reports in `results/vivado/`, one ledger row
(evidence level "routed timing", target WNS ≥ 0 at 150 MHz, stretch goal
200 MHz per docs/09 section 8).

## Phase 9 — Board bring-up (KV260 + PYNQ 3.1.0)

1. Flash the Kria KV260 starter-kit boot firmware that matches the 2024.2
   toolchain family, then boot the PYNQ 3.1.0 SD image.
2. Install the shell bitstream + the exported HLS IPs (xclbin/dtu path per
   the PYNQ overlay flow in `runtime/pynq_bringup.ipynb`).
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
