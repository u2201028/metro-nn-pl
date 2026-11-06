# Acceptance record (roadmap Phase 0)

Project: MobileNetV2 + GRU fight-scoring IP on Kria KV260 (K26 / xck26-sfvc784-2LV-c).

## What is accepted in this repository

| Artifact | Path | Evidence level | Status |
| :---- | :---- | :---- | :---- |
| Integer oracle (Phase 4) | `model/integer_oracle/oracle.py` | C simulation | ACCEPTED |
| GRU sequence kernel | `hls/gru_sequence/` | C simulation | ACCEPTED |
| Conv kernels | `hls/mnv2_features/` | C simulation | ACCEPTED |
| Cycle models | `bench/cycle_models.py`, `bench/gru_cycle_model.py` | Calculated | ACCEPTED |
| Packet ABI v1 codec | `runtime/packet_abi.py` | C simulation | ACCEPTED |
| Model container v1 | `runtime/model_container.py` | C simulation | ACCEPTED |
| CSR map + generators | `ip/schema/csr_map.json`, `tools/gen_csr.py` | Generated | ACCEPTED |
| Worksheet | `tools/worksheet.py` | Calculated | ACCEPTED |
| Event metrics | `bench/event_metrics.py` | Calculated | ACCEPTED |
| Sampler | `data/sampler.py`, `data/split_manifest.py` | Calculated | ACCEPTED |

## Evidence levels used in this repository

- **Calculated** — derived by the checked-in calculators from the frozen
  contract; reproducible by running the tests.
- **C simulation** — compiled and executed in this sandbox with `g++`
  (`hls/gru_sequence/tb_gru.cpp`, `hls/mnv2_features/tb_conv.cpp`) against
  the golden vectors in `vectors/golden/`.
- **RTL co-simulation** — requires Vitis HLS `cosim_design`; the sources
  and testbenches are in place, execution is tool-gated.
- **Routed timing** — requires Vivado implementation on the K26 part.
- **Physical-board / live / field** — requires the KV260 board.

## Frozen numerical contract (summary)

| Tensor | Format | Scale | Rounding |
| :---- | :---- | :---- | :---- |
| Weights | INT8 symmetric | per-output-channel | n/a (exact) |
| Activations | INT8, zero point = real zero | per-tensor | exact |
| Accumulators | INT32 | n/a | exact |
| Gate inputs | Q7.10 INT16 | 2^-10 | round-half-to-even |
| Gate LUT outputs / in-flight hidden | Q1.15 INT16 | 2^-15 | table lookup |
| Committed hidden | Q7.8 INT8 | 2^-7 | round-half-to-even, saturate |

GRU gate order is the exported PyTorch order (reset, update, new):
`a = W_ih x + b_ih ; u = W_hh h + b_hh ; r = sigmoid(a_r + u_r) ;
z = sigmoid(a_z + u_z) ; n = tanh(a_n + r*u_n) ;
h = (1-z)*n + z*h_prev`.  The committed hidden state is the Q1.15 value
rounded half-to-even to Q7.8 and saturated; the next step re-expands it
with an exact `<< 8`.

## Boundary witnesses (executed, not transcribed)

| Boundary | Expression | Value |
| :---- | :---- | :---- |
| Requantization tie (positive) | `requantize(1000000, 18226, 21, 0)` | 127 |
| Requantization tie (negative) | `requantize(-1000001, 18226, 21, 0)` | -128 |
| Most-negative accumulator | `requantize(-2147483648, 18226, 21, 0)` | -128 |
| Sigmoid at zero | `sigmoid_q15(0)` | 16384 |

These values are recomputed from the oracle by `python3 tools/gen_docs.py`
into `docs/03-integer-contract.md`; they must be reproduced exactly by the
HLS C++ testbench and by the RTL scoreboard.

## Verification matrix status

| Roadmap requirement | Where | Status |
| :---- | :---- | :---- |
| Golden vectors for every operator | `vectors/golden/*.vec` | DONE (C sim) |
| Oracle ↔ HLS C++ ↔ RTL equality | `docs/03-integer-contract.md` | C sim DONE; RTL PENDING (Vivado) |
| Cached vs dense replay equality | `tests/test_replay.py` | DONE (C sim) |
| Gate-order witness | `gru_cell_int8` + `gate_order_witness` | DONE (C sim) |
| Sentinel list (Section 12) | `vectors/golden/conv_sentinels.vec` | DONE (C sim) |
| CSR map ↔ RTL decode consistency | `tests/test_csr.py` | DONE (schema ↔ generated) |
| Packet worksheet beat counts | `tests/test_packet_abi.py` | DONE (C sim) |
| Cycle models vs Section 7 trace | `tests/test_cycle_models.py` | DONE (calculated) |
| HLS csim/cosim/export | `hls/*/build.tcl` | PENDING (Vitis HLS) |
| Routed timing on K26 | `vivado/` | PENDING (Vivado) |
| DMA loopback on KV260 | `vivado/` runbook | PENDING (board) |
| Training / real footage | `data/`, `model/` | PENDING (GPU + footage) |
