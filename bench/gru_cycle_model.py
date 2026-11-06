"""GRU temporal transaction cycle model (roadmap Phase 6B).

Mirrors rtl/gru/gru_sequencer.sv.  Assumptions (documented in the roadmap):
resident weights, a ready sink, one issue per cycle, an illustrative shared
P=8, Q=16 affine engine, and STEP_OVERHEAD cycles of gate arithmetic and
commit per timestep.  This is a local scheduling example, not a routed
latency result and not an end-to-end inference time.

Reference values from the roadmap:
  - input projection: 80 x 48 = 3,840 issues, plus 4 terminal-drain edges;
  - one replay step: 8 x 48 = 384 issues + 28 overhead = 412 cycles;
  - 32 steps: 32 x 412 = 13,184 cycles;
  - steady-state update: 13,184 + 3,840 + 4 = 17,028 cycles
    = 113.52 us at an assumed 150 MHz.
"""

from __future__ import annotations

from dataclasses import dataclass

I = 1280
H = 128
T = 32
IN_TILE = 16
OUT_GROUP = 8
STEP_OVERHEAD = 28
DRAIN_CYCLES = 4

IN_TILES = I // IN_TILE      # 80
OUT_G = 3 * H // OUT_GROUP   # 48
REC_TILES = H // IN_TILE     # 8


@dataclass
class GruCycleModel:
    issues: int = 0
    cycles: int = 0
    stalls: int = 0

    def input_projection(self) -> int:
        """Fresh input projection: IN_TILES x OUT_G issues plus drain."""
        issues = IN_TILES * OUT_G
        self.issues += issues
        self.cycles += issues + DRAIN_CYCLES
        return issues + DRAIN_CYCLES

    def replay_step(self) -> int:
        """One recurrent step: REC_TILES x OUT_G issues plus overhead."""
        issues = REC_TILES * OUT_G
        self.issues += issues
        self.cycles += issues + STEP_OVERHEAD
        return issues + STEP_OVERHEAD

    def steady_update(self) -> int:
        """One new frame + full 32-step replay."""
        self.cycles = 0
        self.issues = 0
        self.input_projection()
        for _ in range(T):
            self.replay_step()
        return self.cycles


def reference_values() -> dict:
    dense_step = REC_TILES * OUT_G + STEP_OVERHEAD
    return dict(
        input_projection_issues=IN_TILES * OUT_G,
        input_projection_cycles=IN_TILES * OUT_G + DRAIN_CYCLES,
        step_cycles=dense_step,
        window_cycles=T * dense_step,
        steady_update_cycles=T * dense_step + IN_TILES * OUT_G + DRAIN_CYCLES,
        us_at_150mhz=(T * dense_step + IN_TILES * OUT_G + DRAIN_CYCLES) / 150e3,
    )
