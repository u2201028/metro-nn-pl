# Handoff prompt for Vibe CLI

Copy everything below the line into a fresh Vibe CLI session started in the
repository root.

---

You are continuing the MGR1 project: a MobileNetV2 + GRU fight-scoring IP
for the Kria KV260 (K26 / xck26-sfvc784-2LV-c), mixed SystemVerilog and
Vitis HLS, with a frozen INT8 numerical contract and a bit-accurate Python
oracle. The full engineering roadmap is the source of truth for scope; the
repository already implements and verifies everything that does not require
the toolchain or the board.

## Where things stand

State of record (read these first, in this order):

1. `EXECUTION_STATUS.md` — phase-by-phase traceability matrix with evidence
   levels and what is PENDING.
2. `docs/01-acceptance-record.md` — what is accepted, at which evidence
   level, and the frozen numerical contract summary.
3. `docs/08-release-checklist.md` — the release gate list; everything above
   the "Toolchain-gated" section is done.

Everything that can run without Vivado/Vitis/a board has already run here:

- 55 pytest checks pass: `python3 -m pytest tests/ -q`
- C-simulation testbenches PASS against golden vectors:
  - `hls/gru_sequence/tb_gru.cpp` → 32 steps x 128 hidden states + score
    (-7226) bit-match the Python oracle via `vectors/golden/gru_window.vec`
  - `hls/mnv2_features/tb_conv.cpp` → conv outputs + requantization
    sentinels match `vectors/golden/conv_sentinels.vec`
- RTL parses and elaborates cleanly: `python3 tools/check_rtl.py` (pyslang;
  not a simulator)
- Verified numbers: worksheet 2,189,760 B / 299,494,272 MACs per frame;
  GRU 540,672 B weights; dense 17,301,504 vs cached 2,064,384 MACs
  (8.38x, 4.8% of model); GRU cycle model 412 step / 13,184 window /
  17,028 steady update / 3,840 issues / 113.52 us @ 150 MHz; packet
  worksheet 9,408 / 9,410 / 82 / 3 / 4 beats.

## Hard rules (do not violate)

- The frozen numeric contract in `model/integer_oracle/oracle.py` is the
  single source of truth. INT8 symmetric weights (per-output-channel
  scale), INT8 activations (per-tensor, zero point = real zero), INT32
  accumulators, gate inputs Q7.10 with round-half-to-even, gate LUT
  outputs and in-flight hidden Q1.15, committed hidden Q7.8 via `>>8`
  round-half-to-even + saturate, re-expanded with exact `<<8`. GRU gate
  order is PyTorch (reset, update, new); the reset gate multiplies the
  candidate affine result INCLUDING its recurrent bias.
- Generated artifacts are never hand-edited; regenerate them:
  - `python3 tools/gen_csr.py` -> runtime/cpp/csr_defs.h,
    runtime/csr_defs.py, rtl/shell/csr_offsets.svh, docs/05-csr-map.md
    (from ip/schema/csr_map.json)
  - `python3 tools/gen_docs.py` -> docs/03-integer-contract.md,
    docs/06-memory-worksheet.md (from the oracle and worksheet)
  - `python3 tools/gen_vectors.py` -> vectors/golden/*.vec + manifest
    (seeded, deterministic; gru_window.vec is 2.1 MB and regenerates
    bit-identically)
- Golden vectors use the `MGR1VEC 1` sectioned text format
  (`SECTION <name> <count>`, 16 ints per line); C++ testbenches parse it
  with no dependencies.
- Every behavior change to the oracle must be accompanied by regenerated
  vectors, regenerated docs, and a green `pytest` run before commit.

## What to do next (in order)

1. Verify the baseline on your machine:
   `python3 -m pytest tests/ -q` (expect 55 passed), then rebuild and run
   both C-simulation testbenches (commands are in README.md and
   EXECUTION_STATUS.md).
2. If you have Vitis HLS 2025.2: run `hls/gru_sequence/build.tcl` and
   `hls/mnv2_features/build.tcl` (csim -> csynth -> cosim -> export).
   C simulation must reproduce the Python oracle bit-exactly before
   synthesis runs; co-simulation must reproduce it again after synthesis.
   Record each run as one row in `results/run_ledger.csv` with the
   evidence level (RTL co-simulation).
3. If you have Vivado with the K26 part: follow
   `docs/07-vivado-runbook.md` — shell build, implementation, routed
   timing on xck26-sfvc784-2LV-c; record evidence level "routed timing".
4. Board bring-up on the KV260 PYNQ image: DMA loopback (150,528-byte
   frame in, 1,280-byte embedding out, 16-byte completion back), verify
   beat counts from docs/04-packet-abi.md (9,410 / 82 / 3) with the ILA
   before enabling the live path. `runtime/pynq_bringup.ipynb` is the
   starting notebook.
5. Training-gated work (needs GPU + footage): follow
   `docs/02-data-protocol.md` — labeling protocol, difficult negatives,
   dedup before sampling, group-aware splits via
   `data/split_manifest.py`, deterministic windows via `data/sampler.py`,
   metrics via `bench/event_metrics.py` (fix operating thresholds on
   validation only).
6. Update `docs/01-acceptance-record.md`, `EXECUTION_STATUS.md`, and
   `docs/08-release-checklist.md` as each gate clears; flip PENDING to
   DONE only with the evidence level that gate requires.

## Open items in the repo (software-side, no toolchain needed)

- `rtl/tb/` is empty: Verilator/XSim testbenches for the skid buffer,
  packet ingress, CSR block, and GRU sequencer are the next software-side
  deliverable. The cycle models in `bench/` (already verified against the
  roadmap Section 7 trace) define the expected behavior.
- `vivado/shell.tcl` does not exist yet (documented in vivado/README.md).
- The HLS sources currently use plain C++ types with `ap_int` available
  under `MGR1_HLS_BUILD`; before csynth, review `hls/common/mgr1_types.h`
  and add the interface/pragma directives in the build.tcl flow.

## Delivery context

- Branch `vibe/mgr1-roadmap-00fd5d` -> `main` via PR #1 on
  github.com/u2201028/metro-nn-pl (draft). Merge it or keep working on the
  branch; either way keep commits focused and update the PR.
- Commit style: single-line summary + body listing verified numbers and
  evidence levels, as in the existing history.
