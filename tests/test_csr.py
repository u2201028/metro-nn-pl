"""Tests for the CSR schema and its generated artifacts (roadmap Section 11).

The schema is the single source of truth: regenerating must be idempotent,
every generated artifact must agree with the schema, and register offsets
must be unique, word-aligned, and within the mapped window.
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

SCHEMA = ROOT / "ip" / "schema" / "csr_map.json"
GENERATED = [
    ROOT / "runtime" / "cpp" / "csr_defs.h",
    ROOT / "runtime" / "csr_defs.py",
    ROOT / "rtl" / "shell" / "csr_offsets.svh",
    ROOT / "docs" / "05-csr-map.md",
]


def load():
    return json.loads(SCHEMA.read_text())


def test_schema_structure():
    d = load()
    assert d["schema_version"] == 1
    assert d["access_width_bytes"] == 4
    assert len(d["registers"]) >= 10
    assert len(d["commands"]) == 8
    assert len(d["states"]) == 6


def test_offsets_unique_and_aligned():
    d = load()
    seen = set()
    for r in d["registers"]:
        off = int(r["offset"], 16)
        assert off % 4 == 0, r["name"]
        assert off not in seen, r["name"]
        seen.add(off)
        assert off <= 0xFF


def test_generation_idempotent():
    before = {p: p.read_bytes() for p in GENERATED if p.exists()}
    subprocess.run(
        ["python3", str(ROOT / "tools" / "gen_csr.py")],
        check=True, capture_output=True,
    )
    for p in GENERATED:
        assert p.exists(), f"missing generated artifact {p}"
        if p in before:
            assert p.read_bytes() == before[p], f"non-idempotent: {p}"


def test_artifacts_match_schema():
    d = load()
    py = (ROOT / "runtime" / "csr_defs.py").read_text()
    svh = (ROOT / "rtl" / "shell" / "csr_offsets.svh").read_text()
    hdr = (ROOT / "runtime" / "cpp" / "csr_defs.h").read_text()
    for r in d["registers"]:
        name = r["name"]
        assert f"'{name}': {r['offset']}," in py
        assert f"k{name}" in hdr
        assert f"OFF_{name}" in svh


def test_commands_and_states_encoded():
    d = load()
    py = (ROOT / "runtime" / "csr_defs.py").read_text()
    svh = (ROOT / "rtl" / "shell" / "csr_offsets.svh").read_text()
    for name, value in d["commands"].items():
        assert name in py and f"CMD_{name}" in svh
        assert f"{name} = {value}" in py
    for name, value in d["states"].items():
        assert f"ST_{name}" in svh
        assert f"{name} = {value}" in py
