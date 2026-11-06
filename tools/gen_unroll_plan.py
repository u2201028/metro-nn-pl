#!/usr/bin/env python3
"""Generate docs/09a-unroll-plan.md from the frozen graph (worksheet.py).

Deterministic per-layer latency-first unroll plan: pixels-in-flight per
engine, bounded so no single engine claims more than ~20% of the 1,248
DSP48E2s (2 INT8 MACs per DSP per cycle = 2,496 MAC/cycle budget).
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from worksheet import conv_layers  # noqa: E402

DSP_BUDGET = 2496  # 1248 DSP48E2 x 2 packed INT8 MACs


def unroll(L: dict) -> int:
    per_pixel = L["k"] * L["k"] * L["cin"]
    u = max(1, DSP_BUDGET // per_pixel)
    return min(u, 8)  # latency-first cap: leave the array to neighbours


def main() -> int:
    layers = conv_layers()
    lines = [
        "# 9a. Per-layer unroll plan (latency-first, generated)",
        "",
        "Source of truth: `tools/worksheet.py conv_layers()` + the DSP budget",
        f"({DSP_BUDGET} packed INT8 MACs/cycle). Pixels-in-flight U caps each",
        "engine near 20% of the array so several engines co-reside; the",
        "row-token dataflow of docs/09 section 3 consumes this table.",
        "",
        "| node | cin | cout | kxk | s | U | MACs/cycle at U |",
        "| :---- | ----: | ----: | ----: | ----: | ----: | ----: |",
    ]
    for L in layers:
        u = unroll(L)
        per_pixel = L["k"] * L["k"] * L["cin"]
        lines.append(
            f"| {L['name']} | {L['cin']} | {L['cout']} | {L['k']}x{L['k']} "
            f"| {L['stride']} | {u} | {u * per_pixel:,} |"
        )
    lines += [
        "",
        "Regenerate: `python3 tools/gen_unroll_plan.py` (never hand-edit).",
        "",
    ]
    (ROOT / "docs" / "09a-unroll-plan.md").write_text("\n".join(lines))
    print(f"wrote docs/09a-unroll-plan.md ({len(layers)} nodes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
