"""Cycle-accurate Python models of the elastic-buffer RTL.

Mirrors rtl/axi/axis_skid_buffer.sv and rtl/axi/axis_packet_ingress.sv so
the Section 7 occupancy example is checkable without a simulator.

Occupancy invariant under test (roadmap Section 7): a trace that starts
empty and enqueues on edges 0..5 while dequeuing on 2,3,6,7,8,9 reaches a
post-edge occupancy of 1,2,2,2,3,4,3,2,1,0.  A four-entry queue suffices; a
three-entry queue must backpressure the sixth write.

Occupancy rule: occ(c) = occ(c-1) + w(c) - r(c), where r pops only if the
queue is non-empty; both handshakes count at their own edge.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class SkidBuffer:
    """Cycle model of the skid-buffer RTL.

    Stops upstream at occupancy two when two unavoidable arrivals can
    follow the stop edge; a four-entry queue then never drops a token.
    """

    capacity: int = 4
    mode: int = 2  # 0 bypass, 1 simple register, 2 skid
    occ: int = 0
    occupancy_trace: list[int] = field(default_factory=list)

    @property
    def s_ready(self) -> bool:
        if self.mode == 0:
            return True
        if self.mode == 1:
            return self.occ < self.capacity
        # Skid mode: reserve two free places for unavoidable arrivals.
        return self.occ + 2 <= self.capacity

    def step(self, w: bool, r: bool) -> int:
        """Advance one edge: w = write handshake, r = read handshake."""
        if w:
            self.occ += 1
        if r and self.occ > 0:
            self.occ -= 1
        self.occupancy_trace.append(self.occ)
        return self.occ


def occupancy_trace(enq: list[bool], deq: list[bool], capacity: int = 4) -> list[int]:
    """Post-edge occupancy for the Section 7 example.

    Enqueue on edges 0..5, dequeue on 2,3,6,7,8,9.
    """
    occ = 0
    trace = []
    for w, r in zip(enq, deq):
        if w:
            occ += 1
        if r and occ > 0:
            occ -= 1
        trace.append(occ)
    return trace


def stop_occupancy(capacity: int = 4, arrivals: int = 2) -> int:
    """Occupancy at which upstream stop must be asserted."""
    return capacity - arrivals


def credit_conserved(enq: list[bool], deq: list[bool]) -> bool:
    """Tokens in == tokens out == tokens resident at the end."""
    occ = 0
    for w, r in zip(enq, deq):
        occ += int(w)
        if r and occ > 0:
            occ -= 1
    return occ == sum(enq) - sum(deq)
