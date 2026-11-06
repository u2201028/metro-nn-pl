"""Versioned split manifests with duplication checks (roadmap Phase 2).

A split manifest pins, for one dataset version: the videos/clips assigned
to train/val/test, the group key used to keep related material on one side
of the split (original videos, related clips, cameras), the deduplication
hashes, and the provenance records required before footage may be used.
The manifest is the exit artifact of Phase 2; training must not start
until it validates.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

SCHEMA_VERSION = 1


@dataclass
class Clip:
    clip_id: str
    camera: str
    source: str
    scene: str
    time_span_s: tuple[float, float]
    fps: float
    label: str
    rights: str
    group: str
    sha256: str = ""


@dataclass
class SplitManifest:
    schema_version: int = 1
    clips: list[Clip] = field(default_factory=list)
    groups: dict[str, list[str]] = field(default_factory=dict)
    strata: dict[str, list[str]] = field(default_factory=dict)

    def to_json(self) -> str:
        return json.dumps(
            dict(
                schema_version=self.schema_version,
                clips=[vars(c) | {"time_span_s": list(c.time_span_s)}
                       for c in self.clips],
                groups=self.groups,
                strata=self.strata,
            ),
            indent=1,
        )


def duplication_check(clips: list[Clip]) -> list[str]:
    """Report duplicate (camera, source, time_span) keys before splitting."""
    seen: dict[tuple, str] = {}
    dupes = []
    for c in clips:
        key = (c.camera, c.source, c.time_span_s)
        if key in seen:
            dupes.append(f"{c.clip_id} duplicates {seen[key]}")
        else:
            seen[key] = c.clip_id
    return dupes


def group_key(c: Clip) -> str:
    """The group key that keeps related material on one side of a split."""
    return c.group


def build_split(
    clips: list[Clip],
    ratios: tuple[float, float, float] = (0.8, 0.1, 0.1),
) -> dict[str, list[str]]:
    """Group-aware train/val/test assignment (never splits a group)."""
    groups: dict[str, list[Clip]] = {}
    for c in clips:
        groups.setdefault(group_key(c), []).append(c)
    train, val, test = [], [], []
    n = sum(len(v) for v in groups.values())
    n_train = int(n * ratios[0])
    n_val = int(n * ratios[1])
    filled = 0
    for g in sorted(groups):
        members = sorted(groups[g], key=lambda c: c.clip_id)
        for c in members:
            if filled < n_train:
                train.append(c.clip_id)
            elif filled < n_train + n_val:
                val.append(c.clip_id)
            else:
                test.append(c.clip_id)
            filled += 1
    return dict(train=train, val=val, test=test)


def validate_split(split: dict[str, list[str]], clips: list[Clip]) -> None:
    """A split is valid when every clip appears exactly once and no group
    is split across sides."""
    all_ids = [c.clip_id for c in clips]
    assigned = split["train"] + split["val"] + split["test"]
    if sorted(assigned) != sorted(all_ids):
        raise ValueError("split does not cover every clip exactly once")
    by_id = {c.clip_id: c for c in clips}
    group_side: dict[str, str] = {}
    for side in ("train", "val", "test"):
        for cid in split[side]:
            g = group_key(by_id[cid])
            prev = group_side.setdefault(g, side)
            if prev != side:
                raise ValueError(
                    f"group {g} appears in both {prev} and {side}"
                )


def write_manifest(m: SplitManifest, path: Path) -> None:
    path.write_text(m.to_json())
