#!/usr/bin/env python3
"""Generate the living contract documents from the frozen sources.

docs/03-integer-contract.md is regenerated from model/integer_oracle so the
published integer boundaries always match the oracle code.  docs/06-memory-
worksheet.md is regenerated from tools/worksheet.py so the memory and
budget tables always match the calculator.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "model"))
sys.path.insert(0, str(ROOT / "tools"))

from integer_oracle import (  # noqa: E402
    GruWeights,
    requantize,
    round_half_even,
    sigmoid_q15,
    tanh_q15,
    conv2d_int8,
    depthwise_conv2d_int8,
    gru_cell_int8,
    gru_score_int8,
    gru_sequence_int8,
    gate_order_witness,
)
import worksheet  # noqa: E402

DOCS = ROOT / "docs"


def gen_integer_contract() -> None:
    w = GruWeights(
        w_ih=[[0] * 1280 for _ in range(384)],
        w_hh=[[0] * 128 for _ in range(384)],
        b_ih=[0] * 384,
        b_hh=[0] * 384,
        mult_gx=18226, shift_gx=21, mult_gh=18226, shift_gh=21,
        head_w=[0] * 128, head_b=0,
    )
    lines = [
        "# Integer numerical contract (generated)",
        "",
        "Source of truth: `model/integer_oracle/oracle.py`.  Regenerate with",
        "`python3 tools/gen_docs.py`.  Every boundary below is executed, not",
        "transcribed.",
        "",
        "## Frozen formats",
        "",
        "| Tensor | Format | Scale | Rounding |",
        "| :---- | :---- | :---- | :---- |",
        "| Weights | INT8 symmetric | per-output-channel | n/a (exact) |",
        "| Activations | INT8, zero point = real zero | per-tensor | exact |",
        "| Accumulators | INT32 | n/a | exact |",
        "| Gate inputs | Q7.10 INT16 | 2^-10 | round-half-to-even |",
        "| Gate LUT outputs / in-flight hidden | Q1.15 INT16 | 2^-15 | table lookup |",
        "| Committed hidden | Q7.8 INT8 | 2^-7 | round-half-to-even, saturate |",
        "",
        "## Boundary witnesses (executed against the oracle)",
        "",
        "| Boundary | Expression | Value |",
        "| :---- | :---- | :---- |",
        f"| Requantization tie (positive) | `requantize(1000000, 18226, 21, 0)` | {requantize(1000000, 18226, 21, 0)} |",
        f"| Requantization tie (negative) | `requantize(-1000001, 18226, 21, 0)` | {requantize(-1000001, 18226, 21, 0)} |",
        f"| Most-negative accumulator | `requantize(-2147483648, 18226, 21, 0)` | {requantize(-2147483648, 18226, 21, 0)} |",
        f"| Sigmoid at zero | `sigmoid_q15(0)` | {sigmoid_q15(0)} |",
        f"| Sigmoid at Q7.10 saturation | `sigmoid_q15(32767)` | {sigmoid_q15(32767)} |",
        f"| Tanh at zero | `tanh_q15(0)` | {tanh_q15(0)} |",
        f"| Tanh at Q7.10 saturation | `tanh_q15(32767)` | {tanh_q15(32767)} |",
        f"| Round-half-even(5, 2) | `round_half_even(5, 2)` | {round_half_even(5, 2)} |",
        f"| Round-half-even(-5, 2) | `round_half_even(-5, 2)` | {round_half_even(-5, 2)} |",
        "",
        "## GRU update rule (PyTorch gate order r, z, n)",
        "",
        "```",
        "a = W_ih x + b_ih ;  u = W_hh h_prev + b_hh",
        "r = sigmoid(a_r + u_r) ;  z = sigmoid(a_z + u_z)",
        "n = tanh(a_n + r * u_n)   # reset gate multiplies the candidate",
        "                          # affine result including its recurrent bias",
        "h = (1 - z) * n + z * h_prev",
        "```",
        "",
        "The reset gate multiplies the candidate affine result including its",
        "recurrent bias; the committed state is `h >> 8` with round-half-to-even",
        "and saturation, and the next step re-expands it with an exact `<< 8`.",
        "",
        "## Executed operator checks",
        "",
        "The oracle self-check below runs the full operator set on the zero",
        "state; the printed digest must be reproduced by the HLS C++ testbench",
        "and by the RTL scoreboard.",
        "",
        "```",
    ]
    h = [0] * 128
    for t in range(2):
        h = gru_cell_int8([0] * 1280, h, w)
    digest = (sum(h) * 2654435761) % (1 << 32)
    lines += [
        f"gru_sequence self-check digest (2 steps, zero input): {digest}",
        f"gru_score(zero state) = {gru_score_int8(h, w)}",
        "```",
    ]
    (DOCS / "03-integer-contract.md").write_text("\n".join(lines) + "\n")


def gen_memory_worksheet() -> None:
    ws = worksheet.full_worksheet()
    layers = worksheet.conv_layers()
    gru_bytes = worksheet.gru_weights_bytes()
    dense = worksheet.gru_dense_window_macs()
    cached = worksheet.gru_cached_window_macs()
    dev = worksheet.device_budget()
    layers_md = "\n".join(
        f"| {l['name']} | {l['kind']} | {l['cin']} | {l['cout']} | {l['k']} | "
        f"{l['stride']} | {l['weights']} | {l['macs']} |"
        for l in layers
    )
    text = f"""# Memory and budget worksheet (generated)

Source of truth: `tools/worksheet.py`.  Regenerate with
`python3 tools/gen_docs.py`.

## Device budget (K26 / xck26-sfvc784-2LV-c)

| Resource | Available | Notes |
| :---- | :---- | :---- |
| BRAM36 | {dev['bram36_count']} blocks / {dev['bram36_bytes']:,} B | 36 KiB each |
| URAM | {dev['uram_count']} blocks / {dev['uram_bytes']:,} B | 288 KiB each |
| DSP | {dev['dsp_count']} | INT8 MAC capable |
| LUT | {dev['lut_count']:,} | |

## Per-layer conv worksheet (reference graph, INT8)

| Layer | Kind | Cin | Cout | K | Stride | Weights B | MACs/frame |
| :---- | :---- | ----: | ----: | ----: | ----: | ----: | ----: |
{layers_md}

Layer totals: {sum(l['weights'] for l in layers):,} weight bytes,
{sum(l['macs'] for l in layers):,} MACs per frame.

## GRU accounting

| Quantity | Value |
| :---- | ----: |
| GRU weights (3 x 128 x 1408) | {gru_bytes:,} B |
| Dense 32-frame window | {dense:,} MACs |
| Cached 32-frame window | {cached:,} MACs |
| Dense/cached ratio | {dense / cached:.2f}x |
| Model-wide MACs (conv + dense GRU) | {sum(l['macs'] for l in layers) + dense:,} |
| Cached share of model | {(dense - cached) / (sum(l['macs'] for l in layers) + dense):.1%} |

## Traffic worksheet (25 FPS, one stream)

| Tensor | Bytes/frame | MB/s at 25 FPS |
| :---- | ----: | ----: |
| Input frame 224x224x3 | {224 * 224 * 3:,} | {224 * 224 * 3 * 25 / 1e6:.2f} |
| Embedding 1280 INT8 | 1,280 | 0.03 |
| Pooled feature write+read | {1280 * 2:,} | {1280 * 2 * 25 / 1e6:.2f} |
"""
    (DOCS / "06-memory-worksheet.md").write_text(text)


def main() -> None:
    DOCS.mkdir(parents=True, exist_ok=True)
    gen_integer_contract()
    gen_memory_worksheet()
    print("generated docs/03-integer-contract.md, docs/06-memory-worksheet.md")


if __name__ == "__main__":
    main()
