`timescale 1ns / 1ps
// Packet ingress for ABI v1 (roadmap Section 11).
//
// Parses the 32-byte in-band header, checks the framing rules, and emits
// exactly one accepted/rejected status per packet:
//   - a transfer occurs on a rising edge when TVALID and TREADY are both high;
//   - every packet is HEADER_BYTES + payload bytes; the v1 kinds fix the
//     payload length per kind (Frame = 150528 B, Embedding = 1280 B,
//     Completion = 16 B);
//   - the header declares payload_len at byte offset 28 (little-endian),
//     which must match the kind's fixed length;
//   - non-final beats carry all-lane TKEEP (0xFFFF at DataWidth = 128); the
//     final beat carries contiguous low-lane TKEEP of payload_len % beat
//     bytes (all lanes when the payload divides evenly);
//   - exactly one TLAST per packet, on the final beat;
//   - header checks: magic "MGR1" in little-endian byte order, abi_major = 1,
//     kind in {1,2,3}, flags = 0 (v1);
//   - healthy beats are forwarded transparently; the offending beat of a
//     faulted packet is dropped and the fault is sticky.
//
// On lost framing, missing TLAST, or an illegal header, admission halts,
// a sticky fault is exposed, and the supervisor quiesces/resets and
// invalidates the epoch.
//
// Fault causes: 1 bad magic / header beat 1, 2 missing or early TLAST,
// 3 over-length packet, 4 illegal header field, 5 illegal TKEEP.

`ifndef MGR1_SVH
`include "mgr1_defs.svh"
`endif

module axis_packet_ingress #(
  parameter int DataWidth = 128,
  parameter int HeaderBytes = 32
) (
  input  logic        aclk,
  input  logic        aresetn,

  input  logic        s_valid,
  input  logic [DataWidth-1:0] s_data,
  input  logic [DataWidth/8-1:0] s_keep,
  input  logic        s_last,
  output logic        s_ready,

  output logic        m_valid,
  output logic [DataWidth-1:0] m_data,
  output logic [DataWidth/8-1:0] m_keep,
  output logic        m_last,
  input  logic        m_ready,

  output logic        pkt_accept,
  output logic        pkt_reject,
  output logic        fault_sticky,
  output logic [31:0] fault_cause
);

  localparam int BytesPerBeat = DataWidth / 8;
  localparam logic [31:0] MAGIC_LE = 32'h3152_474D;  // byte 0 'M', 1 'G', 2 'R', 3 '1'
  localparam logic [DataWidth/8-1:0] KEEP_FULL = '1;
  // Longest v1 payload: 150,528 B -> 9,408 payload beats + 2 header beats.
  localparam int MaxBeats = (HeaderBytes + 150528 + BytesPerBeat - 1) / BytesPerBeat;
  localparam int CntW = $clog2(MaxBeats);

  logic [CntW-1:0] beat_cnt;
  logic [CntW-1:0] expected_beats;
  logic [31:0]     payload_len_q;
  logic [7:0]      s_kind_q;

  assign s_ready = m_ready && !fault_sticky;

  function automatic logic [31:0] kind_payload_len(input logic [7:0] kind);
    case (kind)
      8'd1: kind_payload_len = 32'd150528;
      8'd2: kind_payload_len = 32'd1280;
      8'd3: kind_payload_len = 32'd16;
      default: kind_payload_len = 32'hFFFF_FFFF;
    endcase
  endfunction

  // Expected TKEEP of the final beat: contiguous low lanes of
  // payload_len % BytesPerBeat bytes; all lanes when it divides evenly.
  function automatic logic [DataWidth/8-1:0] final_keep(input logic [31:0] pay_len);
    logic [DataWidth/8-1:0] one;
    logic [31:0] lines;
    one = '0;
    one[0] = 1'b1;
    lines = pay_len % BytesPerBeat;
    if (lines == 0) final_keep = KEEP_FULL;
    else            final_keep = (one << lines) - 1;
  endfunction

  // Per-beat header expected-value computation (header beats only).
  logic [CntW-1:0] exp_beats_now;
  logic [31:0]     exp_len_now;
  logic            hdr_bad;

  always_comb begin
    hdr_bad       = 1'b0;
    exp_beats_now = expected_beats;
    exp_len_now   = payload_len_q;
    if (beat_cnt == '0) begin
      // Header beat 1: bytes 0..15.
      if (s_data[31:0] != MAGIC_LE)                        hdr_bad = 1'b1;
      if (s_data[39:32] != 8'd1)                           hdr_bad = 1'b1;  // abi_major
      if (s_data[47:40] == 8'd0 || s_data[47:40] > 8'd3)   hdr_bad = 1'b1;  // kind
      if (s_data[63:48] != 16'd0)                          hdr_bad = 1'b1;  // flags
      exp_len_now   = kind_payload_len(s_data[47:40]);
      exp_beats_now = CntW'((HeaderBytes + exp_len_now + BytesPerBeat - 1) / BytesPerBeat);
    end else if (beat_cnt == CntW'(1)) begin
      // Header beat 2: bytes 16..31; the declared payload length sits in
      // bytes 28..31 = within-beat bytes 12..15 = s_data[127:96]
      // (little-endian) at DataWidth 128.
      exp_len_now   = s_data[127:96];
      exp_beats_now = CntW'((HeaderBytes + exp_len_now + BytesPerBeat - 1) / BytesPerBeat);
      if (exp_len_now != kind_payload_len(s_kind_q)) hdr_bad = 1'b1;
    end
  end

  // One clocked check per accepted beat.  Header beats are 0 and 1; payload
  // beats are 2..expected_beats-1.
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      beat_cnt       <= '0;
      fault_sticky   <= 1'b0;
      fault_cause    <= 32'd0;
      expected_beats <= '0;
      payload_len_q  <= 32'd0;
      s_kind_q       <= 8'd0;
    end else begin
      pkt_accept <= 1'b0;
      pkt_reject <= 1'b0;
      if (s_valid && s_ready) begin
        if (beat_cnt == '0) begin
          if (hdr_bad) begin
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd1;
            pkt_reject   <= 1'b1;
          end else begin
            s_kind_q <= s_data[47:40];
            beat_cnt <= CntW'(1);
          end
        end else if (beat_cnt == CntW'(1)) begin
          if (hdr_bad) begin
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd4;
            pkt_reject   <= 1'b1;
          end else begin
            payload_len_q  <= s_data[127:96];
            expected_beats <= exp_beats_now;
            beat_cnt       <= CntW'(2);
          end
        end else begin
          if (s_last && beat_cnt != exp_beats_now - 1) begin
            // TLAST before the end of the packet.
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd2;
            pkt_reject   <= 1'b1;
          end else if (!s_last && beat_cnt == exp_beats_now - 1) begin
            // End of the declared packet without TLAST.
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd3;
            pkt_reject   <= 1'b1;
          end else if (beat_cnt != exp_beats_now - 1 && s_keep != KEEP_FULL) begin
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd5;
            pkt_reject   <= 1'b1;
          end else if (s_last && s_keep != final_keep(payload_len_q)) begin
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd5;
            pkt_reject   <= 1'b1;
          end else if (s_last) begin
            pkt_accept <= 1'b1;
            beat_cnt   <= '0;
          end else begin
            beat_cnt <= beat_cnt + CntW'(1);
          end
        end
      end
    end
  end

  // Healthy beats pass through; the first offending beat is dropped; after a
  // sticky fault admission halts (s_ready low) and nothing is forwarded.
  logic frame_bad;
  always_comb begin
    frame_bad = 1'b0;
    if (beat_cnt == '0 && hdr_bad) frame_bad = 1'b1;                       // header beat 1
    if (beat_cnt == CntW'(1) && hdr_bad) frame_bad = 1'b1;                 // header beat 2
    if (beat_cnt < CntW'(2) && s_keep != KEEP_FULL) frame_bad = 1'b1;      // header beats full
    if (beat_cnt >= CntW'(2) && beat_cnt != expected_beats - 1 &&
        s_keep != KEEP_FULL) frame_bad = 1'b1;                             // body beats full
    if (beat_cnt >= CntW'(2) && s_last && beat_cnt != expected_beats - 1) frame_bad = 1'b1;
    if (beat_cnt >= CntW'(2) && !s_last && beat_cnt == expected_beats - 1) frame_bad = 1'b1;
    if (beat_cnt >= CntW'(2) && s_last && beat_cnt == expected_beats - 1 &&
        s_keep != final_keep(payload_len_q)) frame_bad = 1'b1;             // final beat keep
  end
  assign m_valid = s_valid && !fault_sticky && !frame_bad;
  assign m_data  = s_data;
  assign m_keep  = s_keep;
  assign m_last  = s_last;

`ifdef MGR1_SVA
  // A healthy packet produces no terminal status while beats still flow:
  // the single accept/reject pulse terminates its own packet.
  property p_one_terminal;
    @(posedge aclk) disable iff (!aresetn)
      (pkt_accept || pkt_reject) |=> !(s_valid && s_ready);
  endproperty
  a_one_terminal: assert property (p_one_terminal);

  // Payload stability under stall.
  property p_stable;
    @(posedge aclk) disable iff (!aresetn)
      (m_valid && !m_ready) |=> ($stable(m_data) && $stable(m_keep) && $stable(m_last));
  endproperty
  a_stable: assert property (p_stable);
`endif

endmodule
