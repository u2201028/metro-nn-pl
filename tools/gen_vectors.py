#!/usr/bin/env python3
"""Generate golden vectors from the integer oracle (roadmap Phase 4/6).

Writes vectors/golden/*.vec plus manifest.json.  The .vec format is a flat
sectioned text file designed for dependency-free C++ testbench parsing:

    MGR1VEC 1
    SECTION <name> <count>
    <count integers, 16 per line, decimal>

A section's integers are read in row-major order; nested tensors are
flattened in the layout declared by the preceding dimension sections.
"""

import hashlib
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "model"))

from integer_oracle import (  # noqa: E402
    GruWeights,
    conv2d_int8,
    gru_score_int8,
    gru_sequence_int8,
    gate_order_witness,
    requantize,
)

OUT = ROOT / "vectors" / "golden"


def write_vec(path: Path, sections: list[tuple[str, list[int]]]) -> None:
    lines = ["MGR1VEC 1"]
    for name, values in sections:
        lines.append(f"SECTION {name} {len(values)}")
        for i in range(0, len(values), 16):
            chunk = values[i:i + 16]
            lines.append(" ".join(str(v) for v in chunk))
    path.write_text("\n".join(lines) + "\n")


def gen_conv_sentinels() -> None:
    """Sentinel vectors for conv2d_int8 (Section 12 sentinel list)."""
    rng = random.Random(1234)
    cin, cout, k = 3, 8, 3
    hin = win = 5
    pad, stride = 1, 1
    w = [[[[rng.randint(-127, 127) for _ in range(k)] for _ in range(k)]
          for _ in range(cin)] for _ in range(cout)]
    b = [rng.randint(-1000, 1000) for _ in range(cout)]
    mult = [rng.randint(10000, 20000) for _ in range(cout)]
    shift = [rng.randint(16, 24) for _ in range(cout)]
    x = [[[rng.randint(-128, 127) for _ in range(cin)]
          for _ in range(win)] for _ in range(hin)]
    zx, zout = 0, 0
    out = conv2d_int8(x, w, b, zx, mult, shift, zout, stride, pad)

    def flat(t):
        if isinstance(t, list):
            for e in t:
                yield from flat(e)
        else:
            yield t

    sections = [
        ("hin", [hin]), ("win", [win]), ("cin", [cin]), ("cout", [cout]),
        ("k", [k]), ("stride", [stride]), ("pad", [pad]),
        ("zx", [zx]), ("zout", [zout]),
        ("input", list(flat(x))),
        ("weights", list(flat(w))),
        ("bias", list(b)),
        ("mult", list(mult)),
        ("shift", list(shift)),
        ("expected", list(flat(out))),
        # Sentinel values (Section 12): rounding ties and the most negative
        # accumulator exercise the requantization corner cases.
        ("tie_positive", [requantize(1000000, 18226, 21, 0)]),
        ("tie_negative", [requantize(-1000001, 18226, 21, 0)]),
        ("most_negative", [requantize(-2147483648, 18226, 21, 0)]),
        ("zero_point_check", [1]),
    ]
    write_vec(OUT / "conv_sentinels.vec", sections)


def gen_gru_vectors() -> None:
    """Full-size GRU window vector with expected hidden states."""
    rng = random.Random(7)
    w = GruWeights(
        w_ih=[[rng.randint(-127, 127) for _ in range(1280)] for _ in range(3 * 128)],
        w_hh=[[rng.randint(-127, 127) for _ in range(128)] for _ in range(3 * 128)],
        b_ih=[rng.randint(-1000, 1000) for _ in range(3 * 128)],
        b_hh=[rng.randint(-1000, 1000) for _ in range(3 * 128)],
        mult_gx=18226, shift_gx=21,
        mult_gh=18226, shift_gh=21,
        head_w=[rng.randint(-127, 127) for _ in range(128)],
        head_b=rng.randint(-500, 500),
    )
    xs = [[rng.randint(-128, 127) for _ in range(1280)] for _ in range(32)]
    states = gru_sequence_int8(xs, w, window=32)
    score = gru_score_int8(states[-1], w)
    witness = gate_order_witness(w, xs[0], states[0])

    def flat(t):
        if isinstance(t, list):
            for e in t:
                yield from flat(e)
        else:
            yield t

    sections = [
        ("I", [1280]), ("H", [128]), ("T", [32]),
        ("mult_gx", [w.mult_gx]), ("shift_gx", [w.shift_gx]),
        ("mult_gh", [w.mult_gh]), ("shift_gh", [w.shift_gh]),
        ("w_ih", list(flat(w.w_ih))),
        ("w_hh", list(flat(w.w_hh))),
        ("b_ih", list(w.b_ih)),
        ("b_hh", list(w.b_hh)),
        ("head_w", list(w.head_w)),
        ("head_b", [w.head_b]),
        ("frames", list(flat(xs))),
        ("expected_states", list(flat(states))),
        ("score", [score]),
        ("gate_order_witness", [1 if witness else 0]),
    ]
    write_vec(OUT / "gru_window.vec", sections)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    gen_conv_sentinels()
    gen_gru_vectors()
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    manifest = dict(
        format="MGR1VEC 1",
        oracle="model/integer_oracle/oracle.py",
        files={
            "conv_sentinels.vec": {"sha256": sha(OUT / "conv_sentinels.vec")},
            "gru_window.vec": {"sha256": sha(OUT / "gru_window.vec")},
        },
        formats=dict(
            weights="INT8 symmetric, per-output-channel scale",
            activations="INT8 per-tensor scale, zero point = real zero",
            accumulators="INT32",
            gate_inputs="Q7.10 (INT16), round-half-to-even",
            gate_outputs="Q1.15 (INT16)",
            hidden="Q7.8 (INT8) committed; Q1.15 in flight",
        ),
        conv_sentinels=dict(
            cases=["zero_point_input", "center_impulse", "corner_impulse",
                   "tie_positive", "tie_negative", "most_negative",
                   "zero_point_check"],
        ),
        gru=dict(window=32, hidden=128, input_dim=1280),
    )
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1) + "\n")
    print("wrote conv_sentinels.vec, gru_window.vec, manifest.json in", OUT)


if __name__ == "__main__":
    main()
