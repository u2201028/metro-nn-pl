// Generated from ip/schema/csr_map.json - do not edit by hand.
`ifndef MGR1_CSR_OFFSETS_SVH
`define MGR1_CSR_OFFSETS_SVH

package mgr1_csr;

  localparam logic [31:0] OFF_ID            = 32'h0000_0000;
  localparam logic [31:0] OFF_ABI           = 32'h0000_0004;
  localparam logic [31:0] OFF_CAPS          = 32'h0000_0008;
  localparam logic [31:0] OFF_LIMITS        = 32'h0000_000C;
  localparam logic [31:0] OFF_COMMAND       = 32'h0000_0010;
  localparam logic [31:0] OFF_STATUS        = 32'h0000_0014;
  localparam logic [31:0] OFF_ERROR         = 32'h0000_0018;
  localparam logic [31:0] OFF_IRQ_STATUS    = 32'h0000_001C;
  localparam logic [31:0] OFF_DESC_LO       = 32'h0000_0020;
  localparam logic [31:0] OFF_DESC_HI       = 32'h0000_0024;
  localparam logic [31:0] OFF_DESC_LEN      = 32'h0000_0028;
  localparam logic [31:0] OFF_ARG           = 32'h0000_002C;
  localparam logic [31:0] OFF_MODEL_GEN     = 32'h0000_0030;
  localparam logic [31:0] OFF_STREAM_EPOCH  = 32'h0000_0034;
  localparam logic [31:0] OFF_IRQ_MASK      = 32'h0000_0038;
  localparam logic [31:0] OFF_SNAP_SEQ      = 32'h0000_003C;
  localparam logic [31:0] OFF_CNT_ACCEPTED  = 32'h0000_0040;
  localparam logic [31:0] OFF_CNT_COMPLETED = 32'h0000_0048;
  localparam logic [31:0] OFF_CNT_ABORTED   = 32'h0000_0050;
  localparam logic [31:0] OFF_CNT_REJECTED  = 32'h0000_0058;
  localparam logic [31:0] OFF_CNT_BUSY_CYC  = 32'h0000_0060;
  localparam logic [31:0] OFF_CNT_STALL_CYC = 32'h0000_0068;
  localparam logic [31:0] OFF_CNT_DDR_RD    = 32'h0000_0070;
  localparam logic [31:0] OFF_CNT_DDR_WR    = 32'h0000_0078;

  // States
  localparam logic [2:0] ST_IDLE = 3'd0;
  localparam logic [2:0] ST_LOADING = 3'd1;
  localparam logic [2:0] ST_READY = 3'd2;
  localparam logic [2:0] ST_BUSY = 3'd3;
  localparam logic [2:0] ST_FAULT = 3'd4;
  localparam logic [2:0] ST_RECOVERING = 3'd5;

  // Commands
  localparam logic [2:0] CMD_NOOP = 3'd0;
  localparam logic [2:0] CMD_LOAD = 3'd1;
  localparam logic [2:0] CMD_COMMIT = 3'd2;
  localparam logic [2:0] CMD_SUBMIT = 3'd3;
  localparam logic [2:0] CMD_SNAPSHOT = 3'd4;
  localparam logic [2:0] CMD_CLEAR_FAULT = 3'd5;
  localparam logic [2:0] CMD_RESET_SCOPE_CORE = 3'd6;
  localparam logic [2:0] CMD_RESET_SCOPE_MODEL = 3'd7;

endpackage

`endif
