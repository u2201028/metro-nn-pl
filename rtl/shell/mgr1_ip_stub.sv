// Elaboration stub for the MGR1 HLS IP (roadmap Phase 8A boundary).
//
// This stub exists ONLY so the shell elaborates before the Vitis HLS export
// exists.  At Phase 8A the Vivado host replaces this file with the wrapper
// exported by Vitis HLS ( export_design -format ip_catalog ), which may
// expose additional source ports; the shell references only the packet-ABI
// faces listed below (frame in, embedding out, completion out, CSR read-back
// and status), all on aclk.  The stub drives its outputs to zero: no cycles,
// no packets, steady idle - a legal, non-interfering occupant of the shell.

`timescale 1ns / 1ps

`ifndef MGR1_SVH
`include "mgr1_defs.svh"
`endif

`ifndef MGR1_AXIS_W
  `define MGR1_AXIS_W 128
`endif

module mgr1_ip #(
  parameter int unsigned NUM_COUNTERS = 8
) (
  input  logic        aclk,
  input  logic        aresetn,

  // Frame in (ingress output): IP is the sink.
  input  logic        frame_tvalid,
  output logic        frame_tready,
  input  logic [`MGR1_AXIS_W-1:0] frame_tdata,
  input  logic [`MGR1_AXIS_W/8-1:0] frame_tkeep,
  input  logic        frame_tlast,

  // Embedding out: IP is the source.
  output logic        embedding_tvalid,
  input  logic        embedding_tready,
  output logic [`MGR1_AXIS_W-1:0] embedding_tdata,
  output logic [`MGR1_AXIS_W/8-1:0] embedding_tkeep,
  output logic        embedding_tlast,

  // Completion out: IP is the source.
  output logic        completion_tvalid,
  input  logic        completion_tready,
  output logic [`MGR1_AXIS_W-1:0] completion_tdata,
  output logic [`MGR1_AXIS_W/8-1:0] completion_tkeep,
  output logic        completion_tlast,

  // Status view toward the CSR.
  output logic [31:0] csr_rdata,
  output logic [31:0] model_gen,
  output logic [31:0] stream_epoch,
  output logic [63:0] counters [NUM_COUNTERS],
  output logic        fault_sticky,
  output logic [31:0] fault_cause
);

  // Stub behavior: never sinks frames, never emits packets, no faults.
  assign frame_tready          = 1'b0;   // always backpressured - legal idle
  assign embedding_tvalid      = 1'b0;
  assign embedding_tdata       = '0;
  assign embedding_tkeep       = '0;
  assign embedding_tlast       = 1'b0;
  assign completion_tvalid     = 1'b0;
  assign completion_tdata      = '0;
  assign completion_tkeep      = '0;
  assign completion_tlast      = 1'b0;
  assign csr_rdata             = 32'd0;
  assign model_gen             = 32'd0;
  assign stream_epoch          = 32'd0;
  always_comb begin
    for (int i = 0; i < NUM_COUNTERS; i++) counters[i] = 64'd0;
  end
  assign fault_sticky          = 1'b0;
  assign fault_cause           = 32'd0;

  // Unused inputs (consumed only by the exported IP at Phase 8A).
  wire _unused = frame_tkeep[0] ^ frame_tdata[0] ^ aresetn ^ aclk;

endmodule
