# External shell CSR map

Generated from `ip/schema/csr_map.json`. Byte-addressed, 32-bit aligned.

| Offset(s) | Access | Field | Behavior software must verify |
| :---- | :---- | :---- | :---- |
| 0x00 | RO | ID | IP identifier; low 16 bits magic 0x4D47 ('MG'), high 16 bits revision. |
| 0x04 | RO | ABI | Packet ABI major in [7:0], minor in [15:8]. |
| 0x08 | RO | CAPS | Capability bitfield: bit0 streaming input, bit1 DMA input, bit2 model reload, bit3 multi-stream. |
| 0x0C | RO | LIMITS | Compact profile/limit descriptor index into an immutable capability record. |
| 0x10 | WO | COMMAND | Write one full command word. States: idle, loading, ready, busy, fault. Illegal transitions are rejected. |
| 0x14 | RO | STATUS | Current state plus busy/valid flags. |
| 0x18 | RO | ERROR | Sticky cause; retains the first fault until acknowledged via CLEAR_FAULT. |
| 0x1C | W1C | IRQ_STATUS | Write-one-to-clear. IRQ clear removes only consumed sources. |
| 0x20 | RW | DESC_LO | Descriptor address low 32 bits; shadow, captured atomically on command. |
| 0x24 | RW | DESC_HI | Descriptor address high 32 bits; shadow. |
| 0x28 | RW | DESC_LEN | Descriptor length in bytes; shadow. |
| 0x2C | RW | ARG | Command argument word; shadow. |
| 0x30 | RO | MODEL_GEN | Committed model generation; confirmation of commit/configuration. |
| 0x34 | RO | STREAM_EPOCH | Selected stream epoch from the accepted configuration. |
| 0x38 | RW | IRQ_MASK | Interrupt enable mask. |
| 0x3C | RO | SNAP_SEQ | Snapshot sequence; a snapshot command latches counters and advances this. |
| 0x40 | RO | CNT_ACCEPTED | 64-bit counter, low word at 0x40, high at 0x44. |
| 0x48 | RO | CNT_COMPLETED | 64-bit counter, low then high. |
| 0x50 | RO | CNT_ABORTED | 64-bit counter, low then high. |
| 0x58 | RO | CNT_REJECTED | 64-bit counter, low then high. |
| 0x60 | RO | CNT_BUSY_CYC | 64-bit counter, low then high. |
| 0x68 | RO | CNT_STALL_CYC | 64-bit counter, low then high. |
| 0x70 | RO | CNT_DDR_RD | 64-bit counter, low then high. |
| 0x78 | RO | CNT_DDR_WR | 64-bit counter, low then high. |

## Commands

- `NOOP` = 0
- `LOAD` = 1
- `COMMIT` = 2
- `SUBMIT` = 3
- `SNAPSHOT` = 4
- `CLEAR_FAULT` = 5
- `RESET_SCOPE_CORE` = 6
- `RESET_SCOPE_MODEL` = 7

## Rules

- Honor WSTRB for writable bytes.
- Writes to read-only state are ignored and leave read-only state unchanged.
- Decouple AXI-Lite write-address and write-data capture so either may arrive first.
- Hold BVALID/RVALID until handshake.
- A sticky-error clear arriving in the same cycle as a new fault must preserve the new event.
