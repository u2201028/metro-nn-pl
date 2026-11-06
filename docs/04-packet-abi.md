# Packet ABI v1 (roadmap Section 11)

## Transport

- 128-bit AXI4-Stream data, 16 bytes per beat (`BEAT_BYTES = 16`).
- Every packet begins with a 32-byte header (`HEADER_BYTES = 32`),
  i.e. exactly two beats of header.
- Byte-addressed, 32-bit aligned; little-endian fields.

## Header layout (32 bytes, two beats)

| Offset | Size | Field | Notes |
| :---- | :---- | :---- | :---- |
| 0 | 4 | magic | `MGR1` (0x4D, 0x47, 0x52, 0x31) |
| 4 | 1 | abi_major | 1 |
| 5 | 1 | kind | 1 frame, 2 embedding, 3 completion |
| 6 | 2 | flags | u16, must be 0 in v1 |
| 8 | 4 | model_gen | u32 model generation |
| 12 | 4 | epoch | u32 stream epoch |
| 16 | 8 | sequence | u64 sequence number |
| 24 | 2 | stream_id | u16 stream id |
| 26 | 2 | format_id | u16 payload format id |
| 28 | 4 | payload_len | u32 payload length in bytes |

## Packet kinds and payloads

| Kind | Payload | Beats (header + payload) |
| :---- | :---- | ----: |
| Frame | 224 x 224 x 3 = 150,528 B | 9,410 |
| Embedding | 1,280 B pooled features | 82 |
| Completion | 16 B status, logit, valid samples, cycle delta | 3 |

A raw loopback packet carries the frame payload without the
embedding/completion framing: 150,528 B = 9,408 beats.

## TKEEP

The final beat of every packet carries contiguous low-lane TKEEP; full
beats use 0xFFFF.  A partial final beat is legal only for small diagnostic
tensors.

## Completion payload

| Offset | Size | Field |
| :---- | :---- | :---- |
| 0 | 4 | status (u32: 1 warmup, 2 valid, 3 rejected) |
| 4 | 4 | logit (s32, meaningful only for VALID) |
| 8 | 4 | valid_samples (u32) |
| 12 | 4 | cycle_delta (u32 device cycles) |

## Stream rules

- One packet kind per stream; kinds are never interleaved.
- Every packet begins with the 32-byte header, exactly two beats.
- The completion packet terminates each submission.
- Status REJECTED packets carry no logit and no valid-sample count.
