"""Tests for the Section 3/10 cached-projection replay contract.

The cached schedule must reproduce the dense schedule bit-exactly on every
hidden state, including across ring wrap and after a reset, and the MAC
accounting must match the roadmap: 17,301,504 dense vs 2,064,384 cached
per 32-frame window (8.38x), about 4.8% of the model-wide total.
"""

import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "model"))
sys.path.insert(0, str(ROOT / "model" / "integer_oracle"))

from integer_oracle import GruWeights, affine_input, gru_cell_int8
from replay import (
    ReplayRing,
    cached_replay,
    dense_replay,
    make_ring,
    run_contract,
)


def make_weights(seed: int = 3) -> GruWeights:
    rng = random.Random(seed)
    return GruWeights(
        w_ih=[[rng.randint(-127, 127) for _ in range(1280)] for _ in range(384)],
        w_hh=[[rng.randint(-127, 127) for _ in range(128)] for _ in range(384)],
        b_ih=[rng.randint(-1000, 1000) for _ in range(384)],
        b_hh=[rng.randint(-1000, 1000) for _ in range(384)],
        mult_gx=18226, shift_gx=21, mult_gh=18226, shift_gh=21,
    )


def test_cached_matches_dense():
    w = make_weights()
    rng = random.Random(11)
    frames = [[rng.randint(-128, 127) for _ in range(1280)] for _ in range(32)]
    dense = dense_replay(frames, w, 32)
    ring = make_ring(frames, w)
    cached = cached_replay(ring, w, 32)
    assert dense == cached
    assert len(dense) == 32 and len(dense[0]) == 128


def test_ring_wrap():
    w = make_weights(4)
    rng = random.Random(5)
    frames = [[rng.randint(-128, 127) for _ in range(1280)] for _ in range(80)]
    ring = make_ring(frames, w)
    assert ring.count == 80
    latest = ring.latest(32)
    for i, a in enumerate(latest):
        assert a == affine_input(frames[48 + i], w)
    dense = dense_replay(frames, w, 32)
    assert cached_replay(ring, w, 32) == dense


def test_ring_reset():
    w = make_weights(6)
    rng = random.Random(7)
    frames = [[rng.randint(-128, 127) for _ in range(1280)] for _ in range(64)]
    ring = make_ring(frames[:32], w)
    ring = make_ring(frames[32:], w)  # reset: fresh ring
    dense = dense_replay(frames[32:], w, 32)
    assert cached_replay(ring, w, 32) == dense


def test_run_contract():
    w = make_weights(8)
    rng = random.Random(9)
    frames = [[rng.randint(-128, 127) for _ in range(1280)] for _ in range(32)]
    states = run_contract(frames, w, 32)
    assert len(states) == 32


def test_mac_accounting():
    I, H, T = 1280, 128, 32
    dense_per_window = 3 * H * (I + H) * T
    assert dense_per_window == 17301504
    # Sliding stride-1 window: one new input projection per window step,
    # recurrent side for all T frames.
    cached_per_window = 3 * H * I + 3 * H * H * T
    assert cached_per_window == 2064384
    ratio = dense_per_window / cached_per_window
    assert 8.3 < ratio < 8.5
    conv_macs = 299494272
    model_dense = conv_macs + dense_per_window
    saving = (dense_per_window - cached_per_window) / model_dense
    assert abs(saving - 0.048) < 0.001


def test_cached_uses_identical_intermediate():
    w = make_weights(10)
    rng = random.Random(11)
    x = [rng.randint(-128, 127) for _ in range(1280)]
    h_prev = [rng.randint(-100, 100) for _ in range(128)]
    a = affine_input(x, w)
    dense = gru_cell_int8(x, h_prev, w)
    cached = gru_cell_int8(None, h_prev, w, a=a)
    assert dense == cached
