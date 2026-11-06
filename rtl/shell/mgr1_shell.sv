// MGR1 top-level shell (roadmap Phase 1 / 8A).
//
// Instantiates the three synthesizable shell components on a single aclk
// domain:
//   - csr_block: the AXI4-Lite register file (ip/schema/csr_map.json).
//   - axis_packet_ingress: in-band header/framing parser for the 128-bit
//     AXIS packet beats (docs/04-packet-abi.md).
//   - axis_skid_buffer: elastic register slice on the egress.
// The MGR1 HLS IP (gru_step / conv2d_int8, exported by Vitis HLS) binds at
// roadmap Phase 8A; until then it is declared by the elaboration stub
// rtl/shell/mgr1_ip_stub.sv.  The stub must be REPLACED by the exported IP
// wrapper on the Vivado host (vivado/shell.tcl handles the search path).
//
// Port set (packet ABI v1):
//   frame:       150,528 B = 9,410 beats (payload) + 2 header beats
//   embedding:     1,280 B =    82 beats
//   completion:       16 B =     3 beats

`timescale 1ns / 1ps

`include "mgr1_defs.svh"
`include "csr_offsets.svh"

`ifndef MGR1_AXIS_W
  `define MGR1_AXIS_W 128
`endif

module mgr1_shell #(
  parameter int unsigned NUM_COUNTERS = 8
) (
  input  logic        aclk,
  input  logic        aresetn,

  // AXI4-Lite slave (CSR).
  input  logic        s_axi_awvalid,
  input  logic [31:0] s_axi_awaddr,
  output logic        s_axi_awready,
  input  logic        s_axi_wvalid,
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  output logic        s_axi_wready,
  output logic        s_axi_bvalid,
  output logic [1:0]  s_axi_bresp,
  input  logic        s_axi_bready,
  input  logic        s_axi_arvalid,
  input  logic [31:0] s_axi_araddr,
  output logic        s_axi_arready,
  output logic        s_axi_rvalid,
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  input  logic        s_axi_rready,

  // Frame ingress (AXI-Stream, 128-bit beats).
  input  logic        s_axis_tvalid,
  input  logic [`MGR1_AXIS_W-1:0] s_axis_tdata,
  input  logic [`MGR1_AXIS_W/8-1:0] s_axis_tkeep,
  input  logic        s_axis_tlast,
  output logic        s_axis_tready,

  // Embedding egress (AXI-Stream, skid-buffered).
  output logic        m_embedding_tvalid,
  output logic [`MGR1_AXIS_W-1:0] m_embedding_tdata,
  output logic [`MGR1_AXIS_W/8-1:0] m_embedding_tkeep,
  output logic        m_embedding_tlast,
  input  logic        m_embedding_tready,

  // Completion egress (AXI-Stream).
  output logic        m_completion_tvalid,
  output logic [`MGR1_AXIS_W-1:0] m_completion_tdata,
  output logic [`MGR1_AXIS_W/8-1:0] m_completion_tkeep,
  output logic        m_completion_tlast,
  input  logic        m_completion_tready,

  // Sticky fault out (drives a status LED / ILA).
  output logic        fault_valid,
  output logic [31:0] fault_cause
);

  // ---------------- internal wires --------------------------------------
  // Ingress handshake and fault side effects.
  logic               pkt_accept, pkt_reject;
  logic               ingress_fault_sticky;
  logic [31:0]        ingress_fault_cause;

  // Parsed-frame beat stream (ingress output).
  logic                                 m_frame_tvalid, m_frame_tready;
  logic [`MGR1_AXIS_W-1:0]              m_frame_tdata;
  logic [`MGR1_AXIS_W/8-1:0]            m_frame_tkeep;
  logic                                 m_frame_tlast;

  // IP embedding/completion sources (drained by the skid buffers).
  logic                                 emb_s_valid, emb_s_ready;
  logic [`MGR1_AXIS_W-1:0]              emb_tdata;
  logic [`MGR1_AXIS_W/8-1:0]            emb_tkeep;
  logic                                 emb_tlast;
  logic                                 cmp_s_valid, cmp_s_ready;
  logic [`MGR1_AXIS_W-1:0]              cmp_tdata;
  logic [`MGR1_AXIS_W/8-1:0]            cmp_tkeep;
  logic                                 cmp_tlast;

  // IP CSR side.
  logic [31:0] fb_csr_rdata;
  logic [31:0] fb_model_gen;
  logic [31:0] fb_stream_epoch;
  logic        ip_fault_sticky;
  logic [31:0] ip_fault_cause;

  // ---------------- CSR block ---------------------------------------------
  logic [63:0] counters_fb [NUM_COUNTERS];

  csr_block #(.NumCounters(NUM_COUNTERS)) u_csr (
    .aclk(aclk), .aresetn(aresetn),
    .aw_valid(s_axi_awvalid), .aw_addr(s_axi_awaddr), .aw_ready(s_axi_awready),
    .w_valid(s_axi_wvalid), .w_data(s_axi_wdata), .w_strb(s_axi_wstrb), .w_ready(s_axi_wready),
    .b_valid(s_axi_bvalid), .b_resp(s_axi_bresp), .b_ready(s_axi_bready),
    .ar_valid(s_axi_arvalid), .ar_addr(s_axi_araddr), .ar_ready(s_axi_arready),
    .r_valid(s_axi_rvalid), .r_data(s_axi_rdata), .r_resp(s_axi_rresp), .r_ready(s_axi_rready),
    .state_i(3'd0),
    .error_cause_i(ingress_fault_sticky ? ingress_fault_cause : ip_fault_cause),
    .error_valid_i(ingress_fault_sticky || ip_fault_sticky),
    .model_gen_i(fb_model_gen), .stream_epoch_i(fb_stream_epoch),
    .counters_i(counters_fb)
  );

  // ---------------- packet ingress -----------------------------------------
  axis_packet_ingress #(.DataWidth(`MGR1_AXIS_W)) u_ingress (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(s_axis_tvalid), .s_data(s_axis_tdata), .s_keep(s_axis_tkeep),
    .s_last(s_axis_tlast), .s_ready(s_axis_tready),
    .m_valid(m_frame_tvalid), .m_data(m_frame_tdata), .m_keep(m_frame_tkeep),
    .m_last(m_frame_tlast), .m_ready(m_frame_tready),
    .pkt_accept(pkt_accept), .pkt_reject(pkt_reject),
    .fault_sticky(ingress_fault_sticky), .fault_cause(ingress_fault_cause)
  );

  // ---------------- egress skid buffers -------------------------------------
  axis_skid_buffer #(.Width(`MGR1_AXIS_W), .Mode(2)) u_emb_skid (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(emb_s_valid), .s_data(emb_tdata), .s_keep(emb_tkeep), .s_last(emb_tlast),
    .s_ready(emb_s_ready),
    .m_valid(m_embedding_tvalid), .m_data(m_embedding_tdata),
    .m_keep(m_embedding_tkeep), .m_last(m_embedding_tlast),
    .m_ready(m_embedding_tready)
  );

  axis_skid_buffer #(.Width(`MGR1_AXIS_W), .Mode(2)) u_completion_skid (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(cmp_s_valid), .s_data(cmp_tdata), .s_keep(cmp_tkeep), .s_last(cmp_tlast),
    .s_ready(cmp_s_ready),
    .m_valid(m_completion_tvalid), .m_data(m_completion_tdata),
    .m_keep(m_completion_tkeep), .m_last(m_completion_tlast),
    .m_ready(m_completion_tready)
  );

  // ---------------- MGR1 IP binding (Phase 8A) ------------------------------
  mgr1_ip u_mgr1_ip (
    .aclk(aclk), .aresetn(aresetn),
    .frame_tvalid(m_frame_tvalid), .frame_tready(m_frame_tready),
    .frame_tdata(m_frame_tdata), .frame_tkeep(m_frame_tkeep),
    .frame_tlast(m_frame_tlast),
    .embedding_tvalid(emb_s_valid), .embedding_tready(emb_s_ready),
    .embedding_tdata(emb_tdata), .embedding_tkeep(emb_tkeep),
    .embedding_tlast(emb_tlast),
    .completion_tvalid(cmp_s_valid), .completion_tready(cmp_s_ready),
    .completion_tdata(cmp_tdata), .completion_tkeep(cmp_tkeep),
    .completion_tlast(cmp_tlast),
    .csr_rdata(fb_csr_rdata),
    .model_gen(fb_model_gen), .stream_epoch(fb_stream_epoch),
    .counters(counters_fb),
    .fault_sticky(ip_fault_sticky), .fault_cause(ip_fault_cause)
  );

  // ---------------- fault aggregation ---------------------------------------
  assign fault_valid = ip_fault_sticky || ingress_fault_sticky || pkt_reject;

  always_comb begin
    if (ip_fault_sticky)          fault_cause = ip_fault_cause;
    else if (ingress_fault_sticky) fault_cause = ingress_fault_cause;
    else                          fault_cause = 32'd0;
  end

  // IP CSR read-back port is wired when the exported IP lands (Phase 8A);
  // fb_csr_rdata stays zero until then (documented at the stub).

`ifdef MGR1_SVA
  // A beat accepted by the ingress must not be silent on faulted frames:
  // every ingress beat edge produces either a forwarded beat or a reject.
  property p_beat_edges;
    @(posedge aclk) disable iff (!aresetn)
      (s_axis_tvalid && s_axis_tready) |-> (m_frame_tvalid ? 1'b1 :
                                             pkt_reject || pkt_accept);
  endproperty
  a_beat_edges: assert property (p_beat_edges);
`endif

endmodule
