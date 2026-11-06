# metro-nn-pl — MobileNetV2 + GRU fight-scoring IP (Kria KV260)

State of record: `EXECUTION_STATUS.md` (traceability matrix),
`docs/01-acceptance-record.md` (frozen numerical contract),
`docs/08-release-checklist.md` (release gates), `results/run_ledger.csv`
(one row per run).

## Layout

```
model/integer_oracle/   bit-accurate integer oracle (single source of truth)
hls/                    Vitis HLS kernels + golden-vector testbenches
  common/                 mgr1_types.h (frozen formats), activation LUT ROM
  gru_sequence/           gru_step + gru_score, build.tcl, tb_gru
  mnv2_features/          conv2d/depthwise kernels, build.tcl, tb_conv
rtl/                    synthesizable SystemVerilog (axi/, gru/, shell/) + rtl/tb/
runtime/                Packet ABI v1 codec, model container v1, CSR accessors, PYNQ notebook
data/                   split manifest + trainer sampler (docs/02-data-protocol.md)
bench/                  cycle models, event metrics
tools/                  generators (csr, docs, vectors, lut header) + check_rtl
vectors/golden/         MGR1VEC 1 sectioned text vectors (generated, committed)
vivado/                 shell.tcl (Phase 1), run_xsim.sh (XSim TB runner)
ip/schema/              csr_map.json - the CSR register-map schema
```

## Verify the baseline (no toolchain needed)

```bash
python3 -m pytest tests/ -q                     # all checks
cd hls/gru_sequence && g++ -std=c++17 -O2 -I../common \
    tb_gru.cpp gru_top.cpp ../common/activation_luts.cpp -o tb_gru \
    && ./tb_gru ../../vectors/golden/gru_window.vec
cd hls/mnv2_features && g++ -std=c++17 -O2 -I../common \
    tb_conv.cpp ../common/activation_luts.cpp -o tb_conv \
    && ./tb_conv ../../vectors/golden/conv_sentinels.vec
python3 tools/check_rtl.py                      # parse + elaboration (pyslang)
```

Generated artifacts are never hand-edited; regenerate instead:

```bash
python3 tools/gen_csr.py                        # CSR artifacts from ip/schema/csr_map.json
python3 tools/gen_lut_header.py                 # activation LUT ROM from the oracle
python3 tools/gen_docs.py                       # docs/03 + docs/06 from the oracle/worksheet
python3 tools/gen_vectors.py                    # vectors/golden/*.vec (seeded, deterministic)
```

## Toolchain-gated (Vivado / Vitis HLS / board)

```bash
cd hls/gru_sequence && vitis_hls -f build.tcl   # csim -> csynth -> cosim -> export
cd hls/mnv2_features && vitis_hls -f build.tcl
./vivado/run_xsim.sh                            # XSim: the four rtl/tb/ testbenches
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

Board bring-up (KV260 / PYNQ) and the hardware runbook:
`docs/07-vivado-runbook.md` and `runtime/pynq_bringup.ipynb`.

## Hard rules (short form)

`model/integer_oracle/oracle.py` is the single source of truth for numbers;
INT8 symmetric weights, INT8 activations (zero point = real zero), INT32
accumulators, gate inputs Q7.10 round-half-to-even, LUT outputs and in-flight
hidden Q1.15, committed hidden Q7.8 (`>>8`, round-half-to-even, saturate,
re-expand with exact `<<8`); GRU gate order is PyTorch (reset, update, new)
and the reset gate multiplies the candidate affine result including its
recurrent bias.  Any oracle change requires regenerated vectors + docs + a
green pytest before commit.
