"""Tests for the deterministic frame sampler (roadmap Phase 2)."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "data"))

from sampler import WindowPlan, dropped_required_samples, sample_windows


def test_deterministic():
    a = sample_windows("clipA", 1000)
    b = sample_windows("clipA", 1000)
    assert a == b
    assert a[0].indices[0] == 0


def test_window_shape_and_stride():
    plans = sample_windows("c", 100, window=32, stride=1)
    assert len(plans) == 69
    assert all(len(p.indices) == 32 for p in plans)
    assert plans[1].start_frame == plans[0].start_frame + 1
    assert plans[0].indices == tuple(range(32))


def test_no_partial_windows():
    plans = sample_windows("c", 33, window=32, stride=1)
    assert len(plans) == 2
    plans = sample_windows("c", 31, window=32, stride=1)
    assert plans == []


def test_resample_from_source_fps():
    plans = sample_windows("c", 500, window=32, stride=1,
                           analysis_fps=25.0, source_fps=20.0)
    assert len(plans) > 0
    assert max(plans[-1].indices) < 500


def test_window_id_stable():
    p = sample_windows("c", 100)[0]
    assert p.window_id == sample_windows("c", 100)[0].window_id
    assert p.window_id.startswith("c_000000000_")


def test_dropped_required_samples():
    p = sample_windows("c", 100)[0]
    missing = dropped_required_samples(p, set(range(1, 100)))
    assert missing == [0]
    assert dropped_required_samples(p, set(range(100))) == []
