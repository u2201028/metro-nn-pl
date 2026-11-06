"""Section 3 / Section 10: cached input-projection replay vs dense replay.

The optimization: compute the three input-side affine projections once when
a new frame arrives, store them in a 32-slot INT32 ring (48 KiB), and replay
only the recurrent side per window.  The contract requires exact equality of
every hidden state, on ring wrap and after reset, against the dense replay.
"""

from __future__ import annotations

import copy

from integer_oracle import (
    GruWeights,
    affine_input,
    gru_cell_int8,
)


class ReplayRing:
    """32-slot ring of cached INT32 input projections."""

    def __init__(self, slots: int = 32, proj_len: int = 384):
        self.slots = slots
        self.ring: list[list[int] | None] = [None] * slots
        self.count = 0  # committed frames (slot index wraps, count does not)
        self.proj_len = proj_len

    def commit(self, a: list[int]) -> int:
        assert len(a) == self.proj_len
        slot = self.count % self.slots
        self.ring[slot] = list(a)
        self.count += 1
        return slot

    def latest(self, k: int) -> list[list[int]]:
        """The k most recent cached projections, oldest first."""
        assert self.count >= k, "ring does not hold k committed frames"
        return [self.ring[i % self.slots] for i in range(self.count - k, self.count)]


def dense_replay(frames: list[list[int]], w: GruWeights, k: int = 32) -> list[list[int]]:
    """Dense schedule: recompute every input projection from the frames."""
    h = [0] * (len(w.w_hh) // 3)
    states = []
    for f in frames[-k:]:
        h = gru_cell_int8(f, h, w)
        states.append(h[:])
    return states


def cached_replay(ring: ReplayRing, w: GruWeights, k: int = 32) -> list[list[int]]:
    """Optimized schedule: reuse the cached projections verbatim."""
    h = [0] * (len(w.w_hh) // 3)
    states = []
    for a in ring.latest(k):
        h = gru_cell_int8(None, h, w, a=a)
        states.append(h[:])
    return states


def make_ring(frames: list[list[int]], w: GruWeights, slots: int = 32) -> ReplayRing:
    ring = ReplayRing(slots=slots, proj_len=len(w.w_ih))
    for f in frames:
        ring.commit(affine_input(f, w))
    return ring


def run_contract(frames: list[list[int]], w: GruWeights, k: int = 32):
    """Full contract: ring contents equal fresh projections, and the cached
    schedule reproduces the dense schedule exactly on every hidden state."""
    ring = make_ring(frames, w)
    for i, f in enumerate(frames):
        assert ring.ring[i % ring.slots] == affine_input(f, w)
    dense = dense_replay(frames, w, k)
    cached = cached_replay(ring, w, k)
    assert dense == cached, "cached replay diverged from dense replay"
    assert len(dense) == k
    return dense


def gate_order_witness(w: GruWeights, x, h) -> bool:
    """Witness that the reset gate multiplies the candidate affine result
    including its recurrent bias: perturbing b_hh of the candidate section
    must be able to change the output when r < 1."""
    w2 = copy.deepcopy(w)
    w2.b_hh[2 * len(h)] += 4096
    h_perturbed = gru_cell_int8(x, h, w2)
    h_base = gru_cell_int8(x, h, w)
    return h_perturbed != h_base
