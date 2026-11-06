# Vivado / Vitis runbook (roadmap Phases 1, 8, 9)

**Hardware-gated.**  Every command below requires the Vivado/Vitis
toolchain and the KV260 board.  Nothing in this file is executed in the
sandbox; each step's evidence is recorded as PENDING in
`docs/01-acceptance-record.md` until run on hardware.

## Phase 1 — Shell build (Vivado)

```bash
# On the Vivado host:
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

Deliverable: shell bitstream with the AXI4-Lite CSR block, the packet
ingress, and the MGR1 IP instantiated.  Evidence: routed timing report on
the K26 part, recorded in `results/`.

## Phase 8 — HLS IP build (Vitis HLS 2025.2)

```bash
cd hls/gru_sequence && vitis_hls -f build.tcl
cd hls/mnv2_features && vitis_hls -f build.tcl
```

Each `build.tcl` runs `csim_design -argv <golden .vec>`, `csynth_design`,
`cosim_design -argv <golden .vec>` and `export_design -format ip_catalog`.
C simulation must reproduce the Python oracle bit-exactly before synthesis
runs; co-simulation must reproduce it again after synthesis.

## Phase 9 — Board bring-up (KV260 / PYNQ)

1. Flash the PYNQ image for Kria KV260.
2. Install the shell bitstream and the exported HLS IPs.
3. Run the DMA loopback: 150,528-byte frame in, embedding out, completion
   packet back.  Verify the beat counts from `docs/04-packet-abi.md`
   (9,410 / 82 / 3) on the ILA before enabling the live path.
4. Run the PYNQ notebook `runtime/pynq_bringup.ipynb` on the board.

## Gate discipline

- No phase advances while the previous phase's evidence is PENDING.
- Every phase exit records its evidence level in
  `docs/01-acceptance-record.md` and one row in `results/run_ledger.csv`.
- A failed gate freezes the phase and records the blocking observation;
  it never silently degrades the working point.
