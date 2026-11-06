"""Tests for the generated activation LUT header (roadmap Phase 6 defect fix).

hls/common/activation_lut_contents.h is GENERATED from
model/integer_oracle/oracle.py by tools/gen_lut_header.py; regeneration must
be bit-identical and the frozen boundary witnesses must hold:
  sigmoid_q15(0) == 16384 (docs/03-integer-contract.md)."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "model" / "integer_oracle"))

import oracle  # noqa: E402

HEADER = ROOT / "hls" / "common" / "activation_lut_contents.h"
GEN = ROOT / "tools" / "gen_lut_header.py"


def gen() -> str:
    subprocess.run(
        [sys.executable, str(GEN)],
        check=True, capture_output=True,
    )
    return HEADER.read_text()


def test_generation_idempotent():
    before = HEADER.read_bytes()
    gen()
    assert HEADER.read_bytes() == before, "non-idempotent: activation_lut_contents.h"


def _table(name: str) -> list[int]:
    txt = HEADER.read_text()
    start = txt.index(f"{name}[65536] = {{") + len(f"{name}[65536] = {{")
    end = txt.index("};", start)
    body = txt[start:end]
    return [int(v.strip()) for v in body.split(",") if v.strip()]


def test_sigmoid_matches_oracle():
    table = _table("MGR1_SIGMOID_LUT")
    assert len(table) == 65536
    for i in range(-32768, 32768, 37):  # stride sample over the full domain
        assert table[i + 32768] == oracle.sigmoid_q15(i), i


def test_tanh_matches_oracle():
    table = _table("MGR1_TANH_LUT")
    assert len(table) == 65536
    for i in range(-32768, 32768, 37):
        assert table[i + 32768] == oracle.tanh_q15(i), i


def test_boundary_witnesses():
    table = _table("MGR1_SIGMOID_LUT")
    assert table[32768 + 0] == 16384  # sigmoid at zero
    assert table[32768 + 32767] == 32767
    assert table[0] >= 0
