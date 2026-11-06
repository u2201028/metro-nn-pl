# MGR1 wiki — scratch to finish on the MobileNetV2 + GRU accelerator

Learning path (read in order; every guide links the code it describes):

1. [01-integer-contract-primer](01-integer-contract-primer.md) — why INT8 +
   Q7.10 + Q1.15, round-half-to-even, saturation, and how the Python oracle
   stays the single source of truth.
2. [02-rtl-fabric-walkthrough](02-rtl-fabric-walkthrough.md) — packet
   ingress, skid buffers, CSR block: the SystemVerilog fabric, gate by gate.
3. [03-dataflow-engine-design](03-dataflow-engine-design.md) — row tokens,
   line buffers, and how the 52-node graph becomes one long pipeline.
4. [04-toolchain-2024.2-runbook-notes](04-toolchain-2024.2-runbook-notes.md)
   — the Vivado/Vitis HLS 2024.2 build from csim to bitstream.
5. [05-pynq-runtime](05-pynq-runtime.md) — PYNQ 3.1.0 runtime, DMA, packet
   ABI, the event watch.

The one rule everything else hangs on: `model/integer_oracle/oracle.py` is
the single source of truth for numbers. Every kernel, testbench, and vector
file must reproduce it bit-exactly, or the build is wrong — no exceptions,
no rounding debates, no "close enough".
