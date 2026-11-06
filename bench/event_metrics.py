"""Event and clip-level metrics for the MGR1 detector (roadmap Phase 2/7,
Sections "Data and evaluation protocol" and "Quality gates").

Metrics, all computed from matched lists:
  - clip-level precision, recall, F1,
  - event recall with onset tolerance and duplicate suppression,
  - false alerts per negative camera-hour,
  - the one-sided 95% Poisson upper bound on the false-alert rate with zero
    observed alerts: -ln(0.05) / hours,
  - mean event delay (alert time minus event onset).

Matching rules are fixed before the final run (roadmap line 214): an alert
matches an event if it falls inside the event window expanded by the onset
tolerance; each event consumes at most one alert (greedy, chronological);
duplicate alerts inside one matched event are suppressed, not double
counted.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field


@dataclass
class Event:
    """A ground-truth incident: [start_s, end_s] on one camera."""

    camera: str
    start_s: float
    end_s: float


@dataclass
class Alert:
    """One detector alert: a timestamp on one camera."""

    camera: str
    t_s: float


@dataclass
class EventMetrics:
    tp_clips: int = 0
    fp_clips: int = 0
    fn_clips: int = 0
    events_total: int = 0
    events_detected: int = 0
    false_alerts: int = 0
    negative_hours: float = 0.0
    delays_s: list[float] = field(default_factory=list)

    @property
    def precision(self) -> float | None:
        d = self.tp_clips + self.fp_clips
        return self.tp_clips / d if d else None

    @property
    def recall(self) -> float | None:
        d = self.tp_clips + self.fn_clips
        return self.tp_clips / d if d else None

    @property
    def f1(self) -> float | None:
        p, r = self.precision, self.recall
        if p is None or r is None or p + r == 0:
            return None
        return 2 * p * r / (p + r)

    @property
    def event_recall(self) -> float | None:
        return self.events_detected / self.events_total if self.events_total else None

    @property
    def false_alerts_per_hour(self) -> float | None:
        return self.false_alerts / self.negative_hours if self.negative_hours else None

    @property
    def mean_delay_s(self) -> float | None:
        return sum(self.delays_s) / len(self.delays_s) if self.delays_s else None


def poisson_upper_rate_95(hours: float) -> float:
    """One-sided 95% upper bound on the false-alert rate given zero alerts.

    Under a stationary Poisson model: rate_95 = -ln(0.05) / hours.
    """
    if hours <= 0:
        raise ValueError("hours must be positive")
    return -math.log(0.05) / hours


def match_events(
    events: list[Event],
    alerts: list[Alert],
    onset_tolerance_s: float = 5.0,
) -> tuple[dict[int, int], list[int]]:
    """Greedy chronological matching of alerts to events.

    Returns (event_index -> alert_index, unmatched_alert_indices).  An alert
    matches an event on the same camera when
    event.start_s - tol <= alert.t_s <= event.end_s + tol.
    """
    by_time = sorted(range(len(alerts)), key=lambda i: alerts[i].t_s)
    matched: dict[int, int] = {}
    unmatched: list[int] = []
    used: set[int] = set()
    for ai in by_time:
        a = alerts[ai]
        best = None
        for ei, e in enumerate(events):
            if e.camera != a.camera or ei in matched.values():
                continue
            if e.start_s - onset_tolerance_s <= a.t_s <= e.end_s + onset_tolerance_s:
                best = ei
                break
        if best is None or best in used:
            unmatched.append(ai)
        else:
            matched[best] = ai
            used.add(best)
    return matched, unmatched


def evaluate(
    events: list[Event],
    alerts: list[Alert],
    tp_clips: int,
    fp_clips: int,
    fn_clips: int,
    negative_hours: float,
    onset_tolerance_s: float = 5.0,
) -> EventMetrics:
    """Full metric bundle from clip-level confusion counts plus events."""
    matched, unmatched = match_events(events, alerts, onset_tolerance_s)
    m = EventMetrics(
        tp_clips=tp_clips,
        fp_clips=fp_clips,
        fn_clips=fn_clips,
        events_total=len(events),
        events_detected=len(matched),
        false_alerts=len(unmatched),
        negative_hours=negative_hours,
    )
    for ei, ai in sorted(matched.items()):
        delay = alerts[ai].t_s - events[ei].start_s
        m.delays_s.append(max(0.0, delay))
    return m
