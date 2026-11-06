# Execution status — traceability matrix

One row per roadmap phase: the artifacts that satisfy it, the evidence
level reached in this sandbox, and what remains PENDING.  Evidence levels:
**calculated** (reproducible here), **C simulation** (executed here),
**RTL co-simulation**, **routed timing**, **physical board**, **live**,
**field** — the last four require the toolchain or the board.

| Phase | Deliverable | Artifacts | Evidence here | PENDING |
| :---- | :---- | :---- | :---- | :---- |
| 0 | Acceptance record | `docs/01-acceptance-record.md` | calculated | routed timing, board |
| 1 | Shell build (Vivado) | `docs/07-vivado-runbook.md` | PENDING | Vivado |
| 2 | Data protocol + splits | `docs/02-data-protocol.md`, `data/split_manifest.py`, `data/sampler.py` | calculated | real footage |
| 3 | GRU math + gate order | `model/integer_oracle/oracle.py`, `hls/gru_sequence/` | C simulation | cosim |
| 4 | Integer oracle | `model/integer_oracle/oracle.py` | C simulation | cosim |
| 5 | Worksheet + budget | `tools/worksheet.py`, `docs/06-memory-worksheet.md` | calculated | — |
| 5B | Cached replay contract | `model/integer_oracle/replay.py`, `tests/test_replay.py` | C simulation | cosim |
| 5C | Packet worksheet | `tests/test_packet_abi.py`, `docs/04-packet-abi.md` | C simulation | cosim |
| 6 | HLS kernels | `hls/gru_sequence/`, `hls/mnv2_features/` | C simulation | csynth, cosim |
| 6A | ILA / packet trace plan | `docs/04-packet-abi.md` | calculated | board |
| 6B | Sequencer RTL | `rtl/gru/gru_sequencer.sv` | elaboration | cosim |
| 7 | Cycle models | `bench/cycle_models.py`, `bench/gru_cycle_model.py` | calculated | cosim |
| 7A | Cycle model tests | `tests/test_cycle_models.py` | calculated | cosim |
| 8 | Vivado implementation | `docs/07-vivado-runbook.md` | PENDING | Vivado |
| 8A | Shell IP integration | `docs/07-vivado-runbook.md` | PENDING | Vivado |
| 9 | Board bring-up | `docs/07-vivado-runbook.md` | PENDING | KV260 |
| 9A | Live capture | `docs/07-vivado-runbook.md` | PENDING | board |
| 12B | Container validation | `runtime/model_container.py`, `tests/test_model_container.py` | C simulation | — |
| 12C | CSR consistency | `tests/test_csr.py`, `ip/schema/csr_map.json` | calculated | — |
| 14 | Release | `docs/08-release-checklist.md` | calculated | toolchain |

## Sandbox evidence summary

- **Executed here (C simulation):** integer oracle, GRU + conv kernels
  against golden vectors, packet ABI codec, model container
  pack/validate/corrupt/truncate, cached vs dense replay, gate-order
  witness, sentinel list, CSR generators, worksheet, event metrics,
  sampler, cycle models; re-verified after the Round-2 kernel edits
  (activation LUT ROM header, static-capacity GRU buffers, PIPELINE
  pragmas) - 59 pytest checks green.
- **Calculated here:** memory/device/traffic/budget worksheets, device
  budget, MAC accounting, beat counts, Poisson bound, split manifests,
  activation LUT ROM consistency (`tests/test_lut_header.py`).
- **Authored, elaboration-checked here (XSim on the toolchain host):**
  the four RTL testbenches in `rtl/tb/` (skid buffer, packet ingress, CSR
  block, GRU sequencer), the shell top `rtl/shell/mgr1_shell.sv` with the
  Phase-8A IP stub, `vivado/shell.tcl` and the XSim runner
  `vivado/run_xsim.sh`.  They parse and elaborate under pyslang
  (`tools/check_rtl.py`, 10 files); execution is Vivado-gated.
- **PENDING (toolchain/board):** XSim testbench execution, Vitis HLS
  csim/csynth/cosim/export, Vivado synthesis and routed timing, DMA
  loopback, board bring-up, live capture, training on real footage.

## Run ledger

`results/run_ledger.csv` records one row per execution run: configuration,
tool versions, evidence level, run ID.

## How to reproduce

```bash
python3 -m pytest tests/ -q          # all 59 checks
python3 tools/gen_csr.py             # regenerate CSR artifacts
python3 tools/gen_lut_header.py      # regenerate activation LUT ROM header
python3 tools/gen_docs.py            # regenerate contract + worksheet docs
cd hls/gru_sequence && g++ -std=c++17 -O2 -I../common \
    tb_gru.cpp gru_top.cpp ../common/activation_luts.cpp -o tb_gru \
 && ./tb_gru ../../vectors/golden/gru_window.vec
cd hls/mnv2_features && g++ -std=c++17 -O2 -I../common \
    tb_conv.cpp ../common/activation_luts.cpp -o tb_conv \
 && ./tb_conv ../../vectors/golden/conv_sentinels.vec
python3 tools/check_rtl.py           # pyslang elaboration check (RTL + TBs)

vivado/run_xsim.sh                   # XSim testbenches - Vivado host only
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

This host has no AMD toolchain; the Vivado/Vitis lines run on the
toolchain host (see results/run_ledger.csv R021).  The C-sim testbenches
also build with any C++17 toolchain: the Round-2 sandbox runs used
`zig c++ 0.17.1` where `g++` was unavailable.
