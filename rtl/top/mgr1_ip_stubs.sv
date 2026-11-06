// Per-op blackbox stubs for the hybrid wrapper build-out
// (rtl/top/mgr1_accel_top.sv / docs/09-accelerator-architecture.md 5).
//
// These exist ONLY so the top elaborates before the Vitis HLS 2024.2 export
// lands.  At Phase 8A the Vivado host replaces them with the exported IP
// wrappers (export_design -format ip_catalog).  Both stubs are zero-effect:
// never sink frames, never emit packets, no faults (legal idle on the shell).

`timescale 1ns / 1ps

`ifndef MGR1_SVH
`include "mgr1_defs.svh"
`endif

`ifndef MGR1_AXIS_W
  `define MGR1_AXIS_W 128
`endif

`ifndef MGR1_IP_STUBS_SV
  `define MGR1_IP_STUBS_SV

module mgr1_conv_ip #(
  parameter int unsigned NUM_COUNTERS = 8
) (
  input  logic        aclk,
  input  logic        aresetn,

  // Frame payload beats in (from the packet ingress).
  input  logic        frame_tvalid,
  output logic        frame_tready,
  input  logic [`MGR1_AXIS_W-1:0] frame_tdata,
  input  logic        frame_tlast,

  // Embedding packets out (packet ABI v1: 82 framed beats).
  output logic        embedding_tvalid,
  input  logic        embedding_tready,
  output logic [`MGR1_AXIS_W-1:0] embedding_tdata,
  output logic        embedding_tlast,

  // Datapath status toward the CSR snapshot area.
  output logic [31:0] model_gen,
  output logic [31:0] stream_epoch,
  output logic [NUM_COUNTERS-1:0][63:0] counters,
  output logic        fault_sticky,
  output logic [31:0] fault_cause
);

  assign frame_tready          = 1'b0;   // always backpressured - legal idle
  assign embedding_tvalid      = 1'b0;
  assign embedding_tdata       = '0;
  assign embedding_tlast       = 1'b0;
  assign model_gen             = 32'd0;
  assign stream_epoch          = 32'd0;
  always_comb begin
    for (int i = 0; i < NUM_COUNTERS; i++) counters[i] = 64'd0;
  end
  assign fault_sticky          = 1'b0;
  assign fault_cause           = 32'd0;
  wire _unused = frame_tdata[0] ^ aresetn ^ aclk;

endmodule

module mgr1_gru_ip #(
  parameter int unsigned NUM_COUNTERS = 8
) (
  input  logic        aclk,
  input  logic        aresetn,

  // Embedding packets in (from the conv IP).
  input  logic        embedding_tvalid,
  output logic        embedding_tready,
  input  logic [`MGR1_AXIS_W-1:0] embedding_tdata,
  input  logic        embedding_tlast,

  // Completion packets out (packet ABI v1: 3 framed beats).
  output logic        completion_tvalid,
  input  logic        completion_tready,
  output logic [`MGR1_AXIS_W-1:0] completion_tdata,
  output logic        completion_tlast,

  // Datapath status toward the CSR snapshot area.
  output logic [31:0] model_gen,
  output logic [31:0] stream_epoch,
  output logic [NUM_COUNTERS-1:0][63:0] counters,
  output logic        fault_sticky,
  output logic [31:0] fault_cause
);

  assign embedding_tready      = 1'b0;   // always backpressured - legal idle
  assign completion_tvalid     = 1'b0;
  assign completion_tdata      = '0;
  assign completion_tlast      = 1'b0;
  assign model_gen             = 32'd0;
  assign stream_epoch          = 32'd0;
  always_comb begin
    for (int i = 0; i < NUM_COUNTERS; i++) counters[i] = 64'd0;
  end
  assign fault_sticky          = 1'b0;
  assign fault_cause           = 32'd0;
  wire _unused = embedding_tdata[0] ^ aresetn ^ aclk;

endmodule

`endif  // MGR1_IP_STUBS_SV
