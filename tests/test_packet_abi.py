"""Tests for the Packet ABI v1 codec (roadmap Section 11).

Reproduces the packet worksheet exactly: 9,408 raw-loopback beats,
9,410 framed frame beats, 82 embedding beats, 3 completion beats, 4 beats
for a 17-byte diagnostic payload with final-beat TKEEP 0x0001, and every
header validation rejection path.
"""

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "runtime"))

import packet_abi as abi


def test_packet_worksheet_beat_counts():
    assert abi.PAYLOAD_FRAME_BYTES == 150528
    assert abi.PAYLOAD_FRAME_BYTES // 16 == 9408
    assert abi.beats_for(abi.PAYLOAD_FRAME_BYTES) == 9410
    assert abi.beats_for(abi.PAYLOAD_EMBEDDING_BYTES) == 82
    assert abi.beats_for(abi.PAYLOAD_COMPLETION_BYTES) == 3
    assert abi.beats_for(17) == 4


def test_tkeep():
    assert abi.tkeep_for(abi.PAYLOAD_FRAME_BYTES) == 0xFFFF
    assert abi.tkeep_for(abi.PAYLOAD_EMBEDDING_BYTES) == 0xFFFF
    assert abi.tkeep_for(abi.PAYLOAD_COMPLETION_BYTES) == 0xFFFF
    assert abi.tkeep_for(17) == 0x0001
    assert abi.tkeep_for(1) == 0x0001
    assert abi.tkeep_for(16) == 0xFFFF


def test_header_roundtrip():
    h = abi.Header(kind=abi.KIND_FRAME, flags=0, model_gen=3, epoch=42,
                   sequence=2**63, stream_id=7, format_id=1,
                   payload_len=abi.PAYLOAD_FRAME_BYTES)
    buf = h.pack()
    assert len(buf) == 32
    assert buf[:4] == b"MGR1"
    got = abi.parse_header(buf)
    assert got == h


def test_completion_payload_layout():
    pkt = abi.completion_packet(1, 2, 3, 4, abi.STATUS_VALID, -12345, 32, 99)
    payload = pkt[32:]
    assert len(payload) == 16
    status, logit, samples, cycles = struct.unpack("<IiII", payload)
    assert (status, logit, samples, cycles) == (2, -12345, 32, 99)
    assert abi.parse_header(pkt[:32]).kind == abi.KIND_COMPLETION


def test_reject_bad_magic():
    h = abi.Header(1, 0, 1, 1, 1, 1, 1, 16).pack()
    bad = b"XXXX" + h[4:]
    try:
        abi.parse_header(bad)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_reject_wrong_major():
    h = abi.Header(1, 0, 1, 1, 1, 1, 1, 16).pack()
    bad = h[:4] + bytes([2]) + h[5:]
    try:
        abi.parse_header(bad)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_reject_illegal_flags():
    h = abi.Header(1, 0, 1, 1, 1, 1, 1, 16).pack()
    bad = h[:6] + struct.pack("<H", 0x0002) + h[8:]
    try:
        abi.parse_header(bad)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_reject_unknown_kind():
    h = abi.Header(1, 0, 1, 1, 1, 1, 1, 16).pack()
    bad = h[:5] + bytes([7]) + h[6:]
    try:
        abi.parse_header(bad)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_reject_wrong_header_size():
    try:
        abi.parse_header(b"\x00" * 31)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_reject_wrong_payload_size():
    try:
        abi.frame_packet(1, 1, 1, 1, 1, b"\x00" * 100)
        raise AssertionError("expected PacketError")
    except abi.PacketError:
        pass


def test_framed_frame_packet():
    payload = bytes(range(256)) * (abi.PAYLOAD_FRAME_BYTES // 256)
    pkt = abi.frame_packet(1, 2, 3, 4, 1, payload)
    assert len(pkt) == 32 + abi.PAYLOAD_FRAME_BYTES
    assert len(pkt) % 16 == 0
    assert (len(pkt) + 0) // 16 == 9410
    h = abi.parse_header(pkt[:32])
    assert h.payload_len == abi.PAYLOAD_FRAME_BYTES
