"""Packet ABI v1 (roadmap Section 11) - reference codec.

128-bit AXI4-Stream, little-endian scalar fields, byte lane 0 carries the
earliest serialized byte.  The first 32 bytes of every packet are an in-band
header:

    bytes 0-3   literal ASCII "MGR1"
    byte  4     ABI major version (1)
    byte  5     packet kind (1 frame, 2 embedding, 3 completion)
    bytes 6-7   flags (reserved, must be 0 in v1)
    bytes 8-11  model generation (u32)
    bytes 12-15 stream epoch (u32)
    bytes 16-23 sequence number (u64)
    bytes 24-25 stream ID (u16)
    bytes 26-27 format ID (u16)
    bytes 28-31 payload length (u32)

Transfer occurs on a rising edge when TVALID and TREADY are both high.  A
source must hold payload and qualifiers stable while stalled.  A partial
final beat requires a contiguous low-lane TKEEP; all lanes are valid on
other beats; exactly one TLAST per packet.  Interleaving is constrained to
whole packets for v1.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass

MAGIC = b"MGR1"
ABI_MAJOR = 1
HEADER_BYTES = 32
BEAT_BYTES = 16

KIND_FRAME = 1
KIND_EMBEDDING = 2
KIND_COMPLETION = 3

FLAG_NONE = 0

PAYLOAD_FRAME_BYTES = 224 * 224 * 3  # 150,528
PAYLOAD_EMBEDDING_BYTES = 1280
PAYLOAD_COMPLETION_BYTES = 16


class PacketError(ValueError):
    """Raised for any packet that must be rejected before writing state."""


@dataclass
class Header:
    kind: int
    flags: int
    model_gen: int
    epoch: int
    sequence: int
    stream_id: int
    format_id: int
    payload_len: int

    def pack(self) -> bytes:
        if len(MAGIC) != 4:
            raise PacketError("magic must be 4 bytes")
        if self.kind not in (KIND_FRAME, KIND_EMBEDDING, KIND_COMPLETION):
            raise PacketError(f"unknown packet kind {self.kind}")
        if self.flags & ~FLAG_NONE:
            raise PacketError(f"illegal flags {self.flags:#x}")
        if self.payload_len > 0xFFFFFFFF:
            raise PacketError("payload length overflows u32")
        return (
            MAGIC
            + bytes([ABI_MAJOR, self.kind])
            + struct.pack("<H", self.flags)
            + struct.pack("<I", self.model_gen)
            + struct.pack("<I", self.epoch)
            + struct.pack("<Q", self.sequence)
            + struct.pack("<H", self.stream_id)
            + struct.pack("<H", self.format_id)
            + struct.pack("<I", self.payload_len)
        )


def parse_header(buf: bytes | bytearray) -> Header:
    if len(buf) != HEADER_BYTES:
        raise PacketError(f"header must be {HEADER_BYTES} bytes, got {len(buf)}")
    if bytes(buf[0:4]) != MAGIC:
        raise PacketError("bad magic")
    if buf[4] != ABI_MAJOR:
        raise PacketError(f"unsupported ABI major {buf[4]}")
    kind = buf[5]
    if kind not in (KIND_FRAME, KIND_EMBEDDING, KIND_COMPLETION):
        raise PacketError(f"unknown packet kind {kind}")
    (flags,) = struct.unpack_from("<H", buf, 6)
    if flags != FLAG_NONE:
        raise PacketError(f"illegal flags {flags:#x}")
    model_gen, epoch = struct.unpack_from("<II", buf, 8)
    (sequence,) = struct.unpack_from("<Q", buf, 16)
    stream_id, format_id = struct.unpack_from("<HH", buf, 24)
    (payload_len,) = struct.unpack_from("<I", buf, 28)
    return Header(
        kind=kind,
        flags=flags,
        model_gen=model_gen,
        epoch=epoch,
        sequence=sequence,
        stream_id=stream_id,
        format_id=format_id,
        payload_len=payload_len,
    )


def beats_for(payload_len: int) -> int:
    """Number of 128-bit beats for payload + 32-byte header.

    All three normal baseline payloads divide evenly; a partial final beat
    is legal only for small diagnostic tensors and requires contiguous
    low-lane TKEEP on that beat.
    """
    total = HEADER_BYTES + payload_len
    full, rem = divmod(total, BEAT_BYTES)
    return full + (1 if rem else 0)


def tkeep_for(payload_len: int) -> int:
    """TKEEP of the final beat (16 lanes, bit 0 = byte lane 0)."""
    total = HEADER_BYTES + payload_len
    rem = total % BEAT_BYTES
    if rem == 0:
        return 0xFFFF
    return (1 << rem) - 1


def frame_packet(model_gen: int, epoch: int, sequence: int, stream_id: int,
                 format_id: int, payload: bytes) -> bytes:
    if len(payload) != PAYLOAD_FRAME_BYTES:
        raise PacketError(f"frame payload must be {PAYLOAD_FRAME_BYTES} bytes")
    return Header(1, 0, model_gen, epoch, sequence, stream_id, format_id,
                  len(payload)).pack() + payload


def embedding_packet(model_gen: int, epoch: int, sequence: int, stream_id: int,
                     format_id: int, payload: bytes) -> bytes:
    if len(payload) != PAYLOAD_EMBEDDING_BYTES:
        raise PacketError(f"embedding payload must be {PAYLOAD_EMBEDDING_BYTES} bytes")
    return Header(2, 0, model_gen, epoch, sequence, stream_id, format_id,
                  len(payload)).pack() + payload


def completion_packet(model_gen: int, epoch: int, sequence: int, stream_id: int,
                      status: int, logit: int, valid_samples: int,
                      cycle_delta: int) -> bytes:
    """16-byte completion payload: u32 status, s32 logit, u32 valid-sample
    count, u32 device-cycle delta.  The logit is meaningful only for VALID
    and its scale comes from the format ID."""
    payload = struct.pack("<IiII", status, logit, valid_samples, cycle_delta)
    return Header(3, 0, model_gen, epoch, sequence, stream_id, 0,
                  len(payload)).pack() + payload


# Completion status codes (Section 10 bring-up semantics).
STATUS_WARMUP = 1
STATUS_VALID = 2
STATUS_REJECTED = 3
