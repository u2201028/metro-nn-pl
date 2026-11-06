"""Tests for the Section 7 elastic-buffer invariants.

Roadmap claims under test:
  - For the example trace (enqueue on edges 0..5, dequeue on 2,3,6,7,8,9),
    a four-entry queue suffices.
  - A three-entry queue must backpressure the sixth write.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bench"))

from cycle_models import SkidBuffer, occupancy_trace, credit_conserved


def test_section7_occupancy_trace():
    enq = [True] * 6 + [False] * 4
    deq = [False, False, True, True, False, False, True, True, True, True]
    t = occupancy_trace(enq, deq)
    assert t == [1, 2, 2, 2, 3, 4, 3, 2, 1, 0]


def test_four_entry_queue_suffices():
    enq = [True] * 6 + [False] * 4
    deq = [False, False, True, True, False, False, True, True, True, True]
    sb = SkidBuffer(capacity=4)
    for w, r in zip(enq, deq):
        sb.step(w, r)
    assert max(sb.occupancy_trace) <= 4


def test_three_entry_backpressures_sixth_write():
    enq = [True] * 6 + [False] * 4
    deq = [False, False, True, True, False, False, True, True, True, True]
    sb = SkidBuffer(capacity=3, mode=1)
    writes = 0
    for w, r in zip(enq, deq):
        if w and sb.s_ready:
            writes += 1
            sb.step(w, r)
        elif r:
            sb.step(w, r)
    assert writes == 5, f"expected the sixth write to be backpressured, got {writes}"


def test_credit_conservation():
    enq = [True] * 6 + [False] * 4
    deq = [False, False, True, True, False, False, True, True, True, True]
    assert credit_conserved(enq, deq)


def test_skid_mode_reserves_two_places():
    enq = [True] * 6 + [False] * 4
    deq = [False, False, True, True, False, False, True, True, True, True]
    sb = SkidBuffer(capacity=4, mode=2)
    for w, r in zip(enq, deq):
        sb.step(w, r)
    assert sb.occupancy_trace[-1] == 0
