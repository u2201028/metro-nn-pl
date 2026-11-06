"""Tests for the Section 2/3/12 worksheet calculators.

The roadmap's published numbers must be reproduced exactly:
  - conv weights 2,189,760 B and 299,494,272 MACs per frame,
  - GRU weights 3 * 128 * 1408 = 540,672 B,
  - dense window 17,301,504 MACs vs cached 2,064,384 (8.38x),
  - device budget: 663,552 B BRAM, 2,359,296 B URAM, 1,248 DSPs.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import worksheet


def test_device_budget():
    b = worksheet.device_budget()
    assert b["bram36_bytes"] == 663552
    assert b["uram_bytes"] == 2359296
    assert b["total_onchip_bytes"] == 663552 + 2359296
    assert b["dsp_count"] == 1248
    assert b["lut_count"] == 117120


def test_conv_layer_totals():
    layers = worksheet.conv_layers()
    assert sum(l["weights"] for l in layers) == 2189760
    assert sum(l["macs"] for l in layers) == 299494272
    names = [l["name"] for l in layers]
    assert names[0] == "stem"
    assert "c16_0_depthwise" in names
    dw = next(l for l in layers if l["name"] == "c16_0_depthwise")
    proj = next(l for l in layers if l["name"] == "c16_0_project")
    assert dw["weights"] == 3 * 32 * 3 * 1
    assert proj["weights"] == 16 * 32


def test_gru_accounting():
    assert worksheet.gru_weights_bytes() == 3 * 128 * 1408
    assert worksheet.gru_dense_window_macs() == 17301504
    assert worksheet.gru_cached_window_macs() == 2064384
    dense = worksheet.gru_dense_window_macs()
    cached = worksheet.gru_cached_window_macs()
    assert abs(dense / cached - 8.38) < 0.01


def test_full_worksheet_runs():
    ws = worksheet.full_worksheet()
    assert ws["device"]["total_onchip_bytes"] == 663552 + 2359296
    text = worksheet.markdown_tables(ws)
    assert "2,189,760" in text or "2189760" in text.replace(",", "")
