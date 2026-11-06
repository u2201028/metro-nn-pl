"""Generated from ip/schema/csr_map.json - do not edit by hand."""

ABI_MAJOR = 1

class State:
    IDLE = 0
    LOADING = 1
    READY = 2
    BUSY = 3
    FAULT = 4
    RECOVERING = 5

class Command:
    NOOP = 0
    LOAD = 1
    COMMIT = 2
    SUBMIT = 3
    SNAPSHOT = 4
    CLEAR_FAULT = 5
    RESET_SCOPE_CORE = 6
    RESET_SCOPE_MODEL = 7

OFFSETS = {
    'ID': 0x00,
    'ABI': 0x04,
    'CAPS': 0x08,
    'LIMITS': 0x0C,
    'COMMAND': 0x10,
    'STATUS': 0x14,
    'ERROR': 0x18,
    'IRQ_STATUS': 0x1C,
    'DESC_LO': 0x20,
    'DESC_HI': 0x24,
    'DESC_LEN': 0x28,
    'ARG': 0x2C,
    'MODEL_GEN': 0x30,
    'STREAM_EPOCH': 0x34,
    'IRQ_MASK': 0x38,
    'SNAP_SEQ': 0x3C,
    'CNT_ACCEPTED': 0x40,
    'CNT_COMPLETED': 0x48,
    'CNT_ABORTED': 0x50,
    'CNT_REJECTED': 0x58,
    'CNT_BUSY_CYC': 0x60,
    'CNT_STALL_CYC': 0x68,
    'CNT_DDR_RD': 0x70,
    'CNT_DDR_WR': 0x78,
}
