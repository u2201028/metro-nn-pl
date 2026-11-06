// Elastic AXI4-Stream register with bypass, simple-register and skid-buffer
// modes (roadmap Section 7: elastic buffers, adversarial stalls and
// checkable invariants).
//
// Occupancy invariant: with q(c) = q(c-1) + w(c) - r(c), a trace that starts
// empty and enqueues on edges 0..5 while dequeuing on 2,3,6,7,8,9 reaches a
// post-edge occupancy of 1,2,2,2,3,4,3,2,1,0; a four-entry queue suffices and
// a three-entry queue must backpressure the sixth write.
//
// Skid rule: if up to two additional tokens can arrive after upstream stop is
// asserted, reserve two free places at this boundary or provide two
// independently accounted skid slots.  In a four-entry queue with two
// unavoidable arrivals, assert upstream stop by occupancy two under the
// selected timing convention.  Do not count the same elastic registers both
// as FIFO capacity and as separate free slots.

`ifndef MGR1_SVH
`include "mgr1_defs.svh"
`endif

module axis_skid_buffer #(
  parameter int Width = 128,
  // 0 = bypass (combinational pass-through when possible),
  // 1 = one output register (simple),
  // 2 = full skid buffer with a second slot
  parameter int Mode = 2
) (
  input  logic             aclk,
  input  logic             aresetn,

  input  logic             s_valid,
  input  logic [Width-1:0] s_data,
  input  logic [Width/8-1:0] s_keep,
  input  logic             s_last,
  output logic             s_ready,

  output logic             m_valid,
  output logic [Width-1:0] m_data,
  output logic [Width/8-1:0] m_keep,
  output logic             m_last,
  input  logic             m_ready
);

  // Upstream stop must be asserted by occupancy two when two unavoidable
  // arrivals can follow the stop edge.
  localparam int StopOccupancy = (Mode == 2) ? 2 : 1;

  logic [Width-1:0] out_data_q;
  logic             out_valid_q;
  logic [Width-1:0] skid_data_q;
  logic             skid_valid_q;

  logic blocked;
  assign blocked = m_valid && !m_ready;

  // The skid slot captures the incoming beat when the output register is
  // blocked or already occupied.
  wire capture = s_valid && s_ready && (blocked || out_valid_q);

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      out_valid_q <= 1'b0;
      skid_valid_q <= 1'b0;
      out_data_q  <= '0;
      skid_data_q <= '0;
    end else begin
      if (m_valid && m_ready) begin
        out_valid_q <= 1'b0;
      end else if (capture) begin
        out_data_q  <= s_data;
        out_valid_q <= 1'b1;
      end
      if (capture && out_valid_q) begin
        skid_data_q  <= out_data_q;
        skid_valid_q <= 1'b1;
      end else if (out_valid_q && m_valid && m_ready) begin
        skid_valid_q <= 1'b0;
      end
    end
  end

  // Forwarding: a newly accepted beat is visible combinationally when the
  // output register is empty (bypass mode) or registered otherwise.
  assign m_valid = out_valid_q || (Mode == 0 && s_valid && !blocked) || skid_valid_q;
  assign m_data  = out_valid_q ? out_data_q : s_data;
  assign m_keep  = s_keep;
  assign m_last  = s_last;

  assign s_ready = (Mode == 0) ? !blocked
                 : (Mode == 1) ? (!out_valid_q || (m_valid && m_ready))
                 : !skid_valid_q || (m_valid && m_ready);

`ifdef MGR1_SVA
  // Credit conservation: tokens are neither created nor destroyed.
  property p_credit;
    @(posedge aclk) disable iff (!aresetn)
      (s_valid && s_ready) - (m_valid && m_ready)
        == ($countones({out_valid_q, skid_valid_q})
            - $past($countones({out_valid_q, skid_valid_q})));
  endproperty
  a_credit: assert property (p_credit);

  // Payload stability under stall.
  property p_stable;
    @(posedge aclk) disable iff (!aresetn)
      (m_valid && !m_ready) |=> ($stable(m_data) && $stable(m_keep) && $stable(m_last));
  endproperty
  a_stable: assert property (p_stable);
`endif

endmodule
