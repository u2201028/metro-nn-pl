// Generated from ip/schema/csr_map.json - do not edit by hand.
#pragma once
#include <cstdint>

namespace mgr1 {

constexpr uint32_t kRegId = 0x4D475231;  // 'MGR1'
constexpr uint8_t kAbiMajor = 1;

enum class State : uint8_t {
  IDLE = 0,
  LOADING = 1,
  READY = 2,
  BUSY = 3,
  FAULT = 4,
  RECOVERING = 5,
};

enum class Command : uint8_t {
  NOOP = 0,
  LOAD = 1,
  COMMIT = 2,
  SUBMIT = 3,
  SNAPSHOT = 4,
  CLEAR_FAULT = 5,
  RESET_SCOPE_CORE = 6,
  RESET_SCOPE_MODEL = 7,
};

// Register offsets (byte-addressed, 32-bit aligned).
constexpr uint32_t kID = 0x00;
constexpr uint32_t kABI = 0x04;
constexpr uint32_t kCAPS = 0x08;
constexpr uint32_t kLIMITS = 0x0C;
constexpr uint32_t kCOMMAND = 0x10;
constexpr uint32_t kSTATUS = 0x14;
constexpr uint32_t kERROR = 0x18;
constexpr uint32_t kIRQ_STATUS = 0x1C;
constexpr uint32_t kDESC_LO = 0x20;
constexpr uint32_t kDESC_HI = 0x24;
constexpr uint32_t kDESC_LEN = 0x28;
constexpr uint32_t kARG = 0x2C;
constexpr uint32_t kMODEL_GEN = 0x30;
constexpr uint32_t kSTREAM_EPOCH = 0x34;
constexpr uint32_t kIRQ_MASK = 0x38;
constexpr uint32_t kSNAP_SEQ = 0x3C;
constexpr uint32_t kCNT_ACCEPTED = 0x40;
constexpr uint32_t kCNT_COMPLETED = 0x48;
constexpr uint32_t kCNT_ABORTED = 0x50;
constexpr uint32_t kCNT_REJECTED = 0x58;
constexpr uint32_t kCNT_BUSY_CYC = 0x60;
constexpr uint32_t kCNT_STALL_CYC = 0x68;
constexpr uint32_t kCNT_DDR_RD = 0x70;
constexpr uint32_t kCNT_DDR_WR = 0x78;

static_assert(kID == 0x00, "ID at 0x00");
static_assert(kCNT_DDR_WR == 0x78, "last counter at 0x78");

}  // namespace mgr1
