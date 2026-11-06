// Packet ingress for ABI v1 (roadmap Section 11).
//
// Parses the 32-byte in-band header, checks the framing rules, and emits
// one accepted/rejected status per packet:
//   - transfer occurs on a rising edge when TVALID and TREADY are both high;
//   - a partial final beat requires contiguous low-lane TKEEP;
//   - all lanes are valid on other beats; exactly one TLAST per packet;
//   - interleaving is constrained to whole packets for v1.
//
// On lost framing, missing TLAST, or an illegal header, admission halts,
// a sticky fault is exposed, and the supervisor quiesces/resets and
// invalidates the epoch.

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
  localparam int BeatsPerPacket = (HeaderBytes + BytesPerBeat - 1) / BytesPerBeat;

  logic [$clog2(BeatsPerPacket+1)-1:0] beat_cnt;
  logic in_packet;

  assign s_ready = m_ready && !fault_sticky;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      beat_cnt     <= '0;
      in_packet    <= 1'b0;
      fault_sticky <= 1'b0;
      fault_cause  <= 32'd0;
    end else begin
      pkt_accept  <= 1'b0;
      pkt_reject  <= 1'b0;
      if (s_valid && s_ready) begin
        if (beat_cnt == '0) begin
          if (s_data[31:0] != 32'h4D475231) begin  // 'MGR1'
            fault_sticky <= 1'b1;
            fault_cause  <= 32'd1;  // bad magic
            pkt_reject   <= 1'b1;
          end else begin
            in_packet  <= 1'b1;
            pkt_accept <= 1'b1;
          end
        end
        if (in_packet && s_last && beat_cnt != BeatsPerPacket-1) begin
          fault_sticky <= 1'b1;
          fault_cause  <= 32'd2;  // missing TLAST / short packet
          pkt_reject   <= 1'b1;
        end
        if (!s_last && beat_cnt == BeatsPerPacket-1) begin
          fault_sticky <= 1'b1;
          fault_cause  <= 32'd3;  // packet longer than declared
          pkt_reject   <= 1'b1;
        end
        beat_cnt <= in_packet ? (beat_cnt + 1) : '0;
      end
    end
  end

  assign m_valid = s_valid && !fault_sticky;
  assign m_data  = s_data;
  assign m_keep  = s_keep;
  assign m_last  = s_last;

`ifdef MGR1_SVA
  // Exactly one terminal status per accepted packet.
  property p_one_terminal;
    @(posedge aclk) disable iff (!aresetn)
      (pkt_accept || pkt_reject) |=> !(pkt_accept || pkt_reject);
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
