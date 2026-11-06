---
name: mgr1-hls-build
description: Build the MGR1 HLS kernels with Vitis HLS 2024.2 — csim gate first, then csynth/cosim/export; what to record in the run ledger and what freezes the phase.
---

# MGR1 HLS build (Vitis HLS 2024.2)

Both flows are one-shot Tcl scripts; run them from the repo root on the
toolchain host (the sandbox has no AMD toolchain):

```bash
cd hls/gru_sequence && vitis_hls -f build.tcl   # gru_step top
cd hls/mnv2_features && vitis_hls -f build.tcl  # conv2d_int8 top
```

## Stage gates (in order, no skipping)

1. `csim_design` must reproduce the oracle bit-exactly: score -7226 on
   `vectors/golden/gru_window.vec`; if csim differs from the Python oracle,
   the C++ diverged — stop, do not csynth.
2. `csynth_design` — record latency/II/BRAM/DSP from the summary.
3. `cosim_design` — the RTL must reproduce the same integers; a cosim
   mismatch after a green csim means a synthesis-order or interface bug.
4. `export_design -format ip_catalog` — the export the Vivado shell binds.

## Ledger

Every run = one row in `results/run_ledger.csv` (date, host, tool,
tool_version, configuration, evidence_level, artifacts). Evidence levels:
calculated / C simulation / RTL co-simulation / routed timing / physical
board. A failed gate freezes the phase and records the blocking
observation — it never silently degrades the working point (docs/07).

## Interface contract (frozen by the build-out)

- Block control stays at the flow default (`ap_ctrl_hs`); port binding
  stays `ap_memory` for the tensor pointers.
- The kernel numerics come from `mgr1::requantize` +
  `hls/common/mgr1_types.h` only; do not re-
  write rounding rules in the kernel bodies.
- The activation LUTs are a GENERATED ROM
  (`hls/common/activation_lut_contents.h`, from
  `tools/gen_lut_header.py`); a diff there means the contract moved —
  regenerate vectors + docs first.
