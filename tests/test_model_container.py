"""Tests for the Phase 7 model container: pack, parse, corruption, truncation."""

import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "runtime"))

import pytest

from model_container import (
    HEADER_SIZE,
    ContainerError,
    ModelContainer,
    Section,
    build_container,
    manifest,
    model_hash,
)


def test_roundtrip():
    blob = build_container(b"A" * 100, b"B" * 200, {"input_scale": 1 / 128})
    mc_sections = Section(kind="cnn", align=16, data=b"A" * 100)
    parsed = ModelContainer().validate(blob)
    kinds = [s.kind for s in parsed]
    assert kinds == ["cnn", "gru"]
    assert parsed[0].data == b"A" * 100
    assert parsed[1].data == b"B" * 200
    assert parsed[0].offset % 16 == 0


def test_alignment_respected():
    blob = build_container(b"x" * 3, b"y" * 5, {})
    sections = ModelContainer().validate(blob)
    for s in sections:
        assert s.offset % s.align == 0


def test_manifest_and_hash():
    blob = build_container(b"a", b"b", {})
    m = manifest(blob)
    assert m["magic"] == "MGR1MDL1"
    assert m["version"] == 1
    assert m["sections"] == 2
    assert m["sha256"] == model_hash(blob)


def test_truncated_blob_rejected():
    blob = build_container(b"A" * 100, b"B" * 200, {})
    with pytest.raises(ContainerError):
        ModelContainer().validate(blob[:-1])
    with pytest.raises(ContainerError):
        ModelContainer().validate(blob[:10])


def test_corrupted_body_rejected():
    blob = build_container(b"A" * 100, b"B" * 200, {})
    corrupt = bytearray(blob)
    corrupt[-1] ^= 0xFF
    with pytest.raises(ContainerError):
        ModelContainer().validate(bytes(corrupt))


def test_corrupted_magic_rejected():
    blob = build_container(b"A", b"B", {})
    bad = b"XXXXXXXX" + blob[8:]
    with pytest.raises(ContainerError):
        ModelContainer().validate(bad)


def test_bad_version_rejected():
    blob = build_container(b"A", b"B", {})
    bad = bytearray(blob)
    bad[8] = 2
    with pytest.raises(ContainerError):
        ModelContainer().validate(bytes(bad))


def test_out_of_bounds_section_rejected():
    mc = ModelContainer()
    mc.sections = [Section(kind="cnn", align=16, data=b"z" * 16)]
    blob = bytearray(mc.pack())
    struct.pack_into("<I", blob, HEADER_SIZE + 12, 0xFFFFFFF0)
    with pytest.raises(ContainerError):
        ModelContainer().validate(bytes(blob))
