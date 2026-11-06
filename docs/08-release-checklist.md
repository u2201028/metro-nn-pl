# Release checklist (roadmap Sections 6 and 14)

Every line must be checked before a release is tagged.  Evidence levels:
**calculated** (reproducible by the checked-in calculators), **C
simulation** (executed in the sandbox), **RTL co-simulation** (Vitis HLS
`cosim_design`), **routed timing** (Vivado implementation), **physical
board** (KV260).  A line is DONE only at the level stated; anything else
stays PENDING.

## Correctness

- [ ] Golden vectors for every operator exist (`vectors/golden/*.vec`) — C simulation
- [ ] Oracle ↔ HLS C++ ↔ RTL equality at declared integer boundaries — C simulation DONE; RTL PENDING
- [ ] Cached replay == dense replay on first window, first wrap, high-motion and long-background runs — C simulation
- [ ] Gate-order witness passes (reset gate multiplies the candidate affine result including its recurrent bias) — C simulation
- [ ] Sentinel list executed: ties, most-negative accumulator, zero-point check — C simulation
- [ ] CSR map ↔ generated artifacts ↔ RTL decode consistency — schema ↔ generated
- [ ] Packet worksheet beat counts (9,408 / 9,410 / 82 / 3 / 4) — C simulation
- [ ] Cycle models reproduce the Section 7 occupancy trace — calculated
- [ ] Activation LUT ROM header regenerated from the oracle and passing boundary witnesses (`tools/gen_lut_header.py`, `tests/test_lut_header.py`) — calculated
- [ ] RTL testbenches (skid buffer, packet ingress, CSR block, GRU sequencer) pass under XSim (`vivado/run_xsim.sh`) — RTL simulation

## Packaging

- [ ] Model container packs and validates (pack / parse / corrupt / truncate) — C simulation
- [ ] Split manifests versioned, groups never split, duplication checks run — calculated
- [ ] Packet ABI doc matches the codec — calculated
- [ ] Integer contract regenerated from the oracle — calculated
- [ ] Memory worksheet regenerated from the worksheet — calculated

## Toolchain-gated (PENDING until run on the toolchain)

- [ ] Vitis HLS csim / csynth / cosim / export for both kernels
- [ ] Vivado synthesis, implementation, routed timing on xck26-sfvc784-2LV-c
- [ ] DMA loopback (150,528 B frame in, embedding out, completion back)
- [ ] Board bring-up on the KV260 PYNQ image
- [ ] Training on real footage; teacher training sign-off

## Release tag

- [ ] All correctness lines DONE
- [ ] All toolchain-gated lines DONE
- [ ] `results/run_ledger.csv` has one row per run with tool versions
- [ ] `EXECUTION_STATUS.md` traceability matrix updated
