"""Tests for split manifests and duplication checks (roadmap Phase 2 exit)."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "data"))

import pytest

from split_manifest import (
    Clip,
    write_manifest,
    SplitManifest,
    build_split,
    duplication_check,
    group_key,
    validate_split,
)


def clips() -> list[Clip]:
    return [
        Clip("v1", "cam1", "src1", "street", (0.0, 30.0), 25.0, "fight",
             "internal", "g1"),
        Clip("v2", "cam1", "src1", "street", (0.0, 30.0), 25.0, "fight",
             "internal", "g1"),
        Clip("v3", "cam2", "src2", "lobby", (0.0, 30.0), 25.0, "normal",
             "internal", "g2"),
        Clip("v4", "cam2", "src1", "street", (60.0, 90.0), 25.0, "fight",
             "internal", "g1"),
        Clip("v5", "cam3", "src3", "park", (0.0, 30.0), 25.0, "normal",
             "public", "g3"),
    ]


def test_duplication_check():
    dupes = duplication_check(clips())
    assert dupes == ["v2 duplicates v1"]


def test_group_key():
    assert group_key(clips()[0]) == "g1"


def test_build_split_never_splits_group():
    split = build_split(clips())
    validate_split(split, clips())
    ids_by_group = {}
    for side in ("train", "val", "test"):
        for cid in split[side]:
            ids_by_group.setdefault(group_key(
                next(c for c in clips() if c.clip_id == cid)), []).append(cid)
    for g, ids in ids_by_group.items():
        sides = {side for side in ("train", "val", "test")
                 for cid in split[side] if group_key(
                     next(c for c in clips() if c.clip_id == cid)) == g}
        assert len(sides) == 1, f"group {g} split across sides"


def test_manifest_roundtrip(tmp_path):
    m = SplitManifest(clips=clips())
    path = tmp_path / "manifest.json"
    write_manifest(m, path)
    assert path.read_text() == m.to_json()
