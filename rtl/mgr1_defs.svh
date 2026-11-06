// Shared definitions for the MGR1 project (roadmap Section 8: rtl/ owns
// synthesizable SystemVerilog, packages, SVA and CDC declarations).

`ifndef MGR1_SVH
`define MGR1_SVH

package mgr1_defs;

  localparam logic [31:0] MAGIC = 32'h4D47_5231;  // "MGR1"

  // Packet ABI v1 header layout (32 bytes, little-endian, byte 0 first).
  localparam int unsigned HDR_BYTES      = 32;
  localparam int unsigned BEAT_BYTES     = 16;
  localparam int unsigned FRAME_BYTES    = 150528;  // 224*224*3
  localparam int unsigned EMBED_BYTES    = 1280;
  localparam int unsigned COMPLETION_BYTES = 16;

  // Beats per packet for the three baseline transfers (Section 11).
  localparam int unsigned BEATS_RAW_LOOPBACK = 9408;  // 150528/16
  localparam int unsigned BEATS_FRAMED_FRAME = 9410;  // (150528+32)/16
  localparam int unsigned BEATS_EMBEDDING    = 82;    // (1280+32)/16
  localparam int unsigned BEATS_COMPLETION   = 3;     // (16+32)/16

  // Packet kinds.
  localparam logic [7:0] KIND_FRAME      = 8'd1;
  localparam logic [7:0] KIND_EMBEDDING  = 8'd2;
  localparam logic [7:0] KIND_COMPLETION = 8'd3;

  // Completion status codes (Section 10).
  localparam logic [31:0] STATUS_WARMUP   = 32'd1;
  localparam logic [31:0] STATUS_VALID    = 32'd2;
  localparam logic [31:0] STATUS_REJECTED = 32'd3;

endpackage

`endif
