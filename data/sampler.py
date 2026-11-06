"""Deterministic frame sampler (roadmap Phase 2, "Days 3-4").

Produces the exact frame indices each 32-frame analysis window samples from
a clip, reproducible from (clip_id, frame count, fps, seed) alone.  The
working point samples 32 frames per window at the analysis rate with
stride 1 between consecutive windows; windows never read beyond the clip.

The sampler is deliberately pure: no I/O, no clock dependence.  A queue
drop or re-decode reproduces the identical window from the same inputs,
which is what makes dropped-required-sample accounting auditable.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass


@dataclass(frozen=True)
class WindowPlan:
    clip_id: str
    start_frame: int
    indices: tuple[int, ...]

    @property
    def window_id(self) -> str:
        h = hashlib.sha256(
            f"{self.clip_id}:{self.start_frame}:{len(self.indices)}".encode()
        ).hexdigest()[:16]
        return f"{self.clip_id}_{self.start_frame:09d}_{h}"


def sample_windows(
    clip_id: str,
    n_frames: int,
    window: int = 32,
    stride: int = 1,
    analysis_fps: float = 25.0,
    source_fps: float | None = None,
) -> list[WindowPlan]:
    """Uniformly sampled windows over one clip.

    Frames are mapped from source rate to the analysis rate by nearest
    index resampling; with source_fps None (pre-decoded at the analysis
    rate) the mapping is the identity.  Consecutive windows advance by
    `stride` frames at the analysis rate.
    """
    if n_frames <= 0:
        return []
    if window <= 0 or stride <= 0:
        raise ValueError("window and stride must be positive")
    if source_fps is None or source_fps == analysis_fps:
        indices_for = lambda t: t  # noqa: E731
        n_analysis = n_frames
    else:
        if source_fps <= 0:
            raise ValueError("source_fps must be positive")
        n_analysis = int(n_frames * analysis_fps / source_fps)
        indices_for = lambda t: min(  # noqa: E731
            n_frames - 1, int(round(t * source_fps / analysis_fps))
        )
    plans = []
    start = 0
    while start + window <= n_analysis:
        idx = tuple(indices_for(start + t) for t in range(window))
        plans.append(WindowPlan(clip_id=clip_id, start_frame=start, indices=idx))
        start += stride
    return plans


def dropped_required_samples(
    plan: WindowPlan, available: set[int]
) -> list[int]:
    """Frame indices a window requires that the ingest did not deliver."""
    return [i for i in plan.indices if i not in available]
