"""Tests for event metrics (roadmap Phase 2/7, quality gates)."""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bench"))

from event_metrics import (
    Alert,
    Event,
    evaluate,
    match_events,
    poisson_upper_rate_95,
)


def test_poisson_bound():
    assert abs(poisson_upper_rate_95(1.0) - 3.0) < 0.01
    assert abs(poisson_upper_rate_95(30.0) - 0.0999) < 0.001
    assert abs(poisson_upper_rate_95(3.0) - 1.0) < 0.01
    assert abs(poisson_upper_rate_95(1.0) - (-math.log(0.05))) < 1e-12


def test_perfect_detection():
    events = [Event("cam1", 10.0, 15.0)]
    alerts = [Alert("cam1", 11.0)]
    m = evaluate(events, alerts, tp_clips=1, fp_clips=0, fn_clips=0,
                 negative_hours=10.0)
    assert m.precision == 1.0
    assert m.recall == 1.0
    assert m.f1 == 1.0
    assert m.event_recall == 1.0
    assert m.false_alerts_per_hour == 0.0
    assert m.mean_delay_s == 1.0


def test_duplicate_alerts_suppressed():
    events = [Event("cam1", 10.0, 15.0)]
    alerts = [Alert("cam1", 11.0), Alert("cam1", 12.0), Alert("cam1", 13.0)]
    matched, unmatched = match_events(events, alerts)
    assert len(matched) == 1
    assert len(unmatched) == 2


def test_onset_tolerance():
    events = [Event("cam1", 10.0, 12.0)]
    inside = match_events(events, [Alert("cam1", 10.0 - 5.0)])
    outside = match_events(events, [Alert("cam1", 10.0 - 5.1)])
    assert len(inside[0]) == 1
    assert len(outside[0]) == 0


def test_camera_isolation():
    events = [Event("cam1", 10.0, 15.0)]
    matched, _ = match_events(events, [Alert("cam2", 11.0)])
    assert len(matched) == 0


def test_false_alert_rate():
    events = []
    alerts = [Alert("cam1", 1.0), Alert("cam1", 2.0), Alert("cam1", 3.0)]
    m = evaluate(events, alerts, tp_clips=0, fp_clips=3, fn_clips=0,
                 negative_hours=6.0)
    assert m.false_alerts_per_hour == 0.5
    assert m.precision == 0.0
