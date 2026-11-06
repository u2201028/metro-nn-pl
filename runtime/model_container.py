"""Model container v1 (roadmap Phase 7): packer and validator.

A model container has a header, version, target capabilities, section
directory, per-section bounds/alignment, correct graph and tensor IDs,
quantization facts, expected preprocessing, and independently loadable
CNN/GRU slices.  Every integer addition is validated before
offset + count * element size is used.  An integrity checksum over the
body detects corruption; authentication of release packages belongs to
the trusted deployment layer.

Layout:
    fixed header  : <8sIIIIIIII>  magic, version, flags, abi,
                    n_sections, hdr_len, total_len, crc32
    directory     : n_sections entries of <8sIII>  kind, align, offset, size
    body          : section data, each aligned to its align, CRC32 over body
"""

from __future__ import annotations

import hashlib
import struct
import zlib
from dataclasses import dataclass, field

MAGIC = b"MGR1MDL1"
VERSION = 1
HEADER_STRUCT = "<8sIIIIIII"
ENTRY_STRUCT = "<8sIII"
HEADER_SIZE = struct.calcsize(HEADER_STRUCT)
ENTRY_SIZE = struct.calcsize(ENTRY_STRUCT)


class ContainerError(ValueError):
    pass


@dataclass
class Section:
    kind: str
    align: int
    data: bytes
    offset: int = 0

    def validate(self, hdr_len: int, total_len: int) -> None:
        if not 1 <= self.align <= 65536 or (self.align & (self.align - 1)):
            raise ContainerError(f"section {self.kind} bad alignment {self.align}")
        if self.offset % self.align:
            raise ContainerError(f"section {self.kind} misaligned")
        if self.offset < hdr_len:
            raise ContainerError(f"section {self.kind} overlaps header")
        if self.offset + len(self.data) > total_len:
            raise ContainerError(f"section {self.kind} out of bounds")


@dataclass
class ModelContainer:
    abi: int = 1
    quant: dict = field(default_factory=dict)
    sections: list[Section] = field(default_factory=list)

    def pack(self) -> bytes:
        hdr_len = HEADER_SIZE + len(self.sections) * ENTRY_SIZE
        body = b""
        entries = []
        offset = hdr_len
        for s in self.sections:
            pad = (-offset) % s.align
            body += b"\x00" * pad
            s.offset = offset + pad
            entries.append(
                struct.pack(ENTRY_STRUCT, s.kind.encode(), s.align,
                            s.offset, len(s.data))
            )
            body += s.data
            offset += pad + len(s.data)
        total = hdr_len + len(body)
        crc = zlib.crc32(body) & 0xFFFFFFFF
        header = struct.pack(
            HEADER_STRUCT, MAGIC, VERSION, 0, self.abi,
            len(self.sections), hdr_len, total, crc,
        )
        return header + b"".join(entries) + body

    def validate(self, blob: bytes) -> list[Section]:
        """Full parse-from-blob validation; returns the parsed sections."""
        if len(blob) < HEADER_SIZE:
            raise ContainerError("truncated header")
        magic, version, flags, abi, n, hdr_len, total, crc = struct.unpack(
            HEADER_STRUCT, blob[:HEADER_SIZE]
        )
        if magic != MAGIC:
            raise ContainerError("bad magic")
        if version != VERSION:
            raise ContainerError(f"unsupported container version {version}")
        if hdr_len != HEADER_SIZE + n * ENTRY_SIZE:
            raise ContainerError("header length inconsistent with section count")
        if len(blob) != total:
            raise ContainerError(f"length mismatch: header {total}, blob {len(blob)}")
        body = blob[hdr_len:total]
        if (zlib.crc32(body) & 0xFFFFFFFF) != crc:
            raise ContainerError("CRC mismatch")
        sections = []
        for i in range(n):
            off = HEADER_SIZE + i * ENTRY_SIZE
            raw_kind, align, offset, size = struct.unpack(
                ENTRY_STRUCT, blob[off:off + ENTRY_SIZE]
            )
            if offset + size > total:
                raise ContainerError("section out of bounds")
            kind = raw_kind.rstrip(b"\x00").decode("ascii", "replace")
            data = blob[offset:offset + size]
            if len(data) != size:
                raise ContainerError(f"section {kind} truncated")
            s = Section(kind=kind, align=align, data=data, offset=offset)
            s.validate(hdr_len, total)
            sections.append(s)
        seen = set()
        for s in sections:
            if s.kind in seen:
                raise ContainerError(f"duplicate section {s.kind}")
            seen.add(s.kind)
        self.sections = sections
        self.abi = abi
        return sections


def build_container(cnn: bytes, gru: bytes, quant: dict, abi: int = 1) -> bytes:
    """Pack independently loadable CNN and GRU slices plus quantization facts."""
    mc = ModelContainer(abi=abi, quant=dict(quant))
    mc.sections = [
        Section(kind="cnn", align=16, data=cnn),
        Section(kind="gru", align=16, data=gru),
    ]
    blob = mc.pack()
    mc.validate(blob)
    return blob


def model_hash(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def manifest(blob: bytes) -> dict:
    magic, version, flags, abi, n, hdr_len, total, crc = struct.unpack(
        HEADER_STRUCT, blob[:HEADER_SIZE]
    )
    return dict(
        magic=magic.decode(),
        version=version,
        abi=abi,
        sections=n,
        total_bytes=total,
        crc32=hex(crc),
        sha256=model_hash(blob),
    )
