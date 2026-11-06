`timescale 1ns / 1ps
// Elastic AXI4-Stream register with bypass, simple-register and skid-buffer
// modes (roadmap Section 7: elastic buffers, adversarial stalls and
// checkable invariants).
//
// Expected behavior (checked by rtl/tb/tb_axis_skid_buffer.sv):
//   - Mode 0: pure combinational bypass, zero occupancy.
//   - Mode 1: one output register; capacity 1; upstream stop at occupancy 1.
//   - Mode 2: full skid buffer; capacity 2 (head = out register, tail =
//     skid register); beats leave strictly in arrival order; upstream stop
//     at occupancy 2 so up to two in-flight beats are always absorbed.
//   - In all modes the outgoing (valid, data, keep, last) tuple is stable
//     while m_valid && !m_ready, independent of what the upstream does
//     after deasserting s_valid.
//
// Skid rule: if up to two additional tokens can arrive after upstream stop is
// asserted, reserve two free places at this boundary or provide two
// independently accounted skid slots.  The two reserved places here are the
// head and tail registers themselves; upstream stop asserts by occupancy two
// and payloads in flight are never dropped or reordered.

`ifndef MGR1_SVH
`include "mgr1_defs.svh"
`endif

module axis_skid_buffer #(
  parameter int Width = 128,
  // 0 = bypass (combinational pass-through),
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

  localparam int KeepW = Width / 8;

  generate
    if (Mode == 0) begin : g_bypass
      // Pure bypass: no occupancy, no registers.
      assign s_ready = m_ready;
      assign m_valid = s_valid;
      assign m_data  = s_data;
      assign m_keep  = s_keep;
      assign m_last  = s_last;
    end else begin : g_slot
      // Slots: head is presented first; the tail only fills while the head
      // holds a stalled beat, so (head, tail) = (0,1) is unreachable and the
      // head always carries the older of the two stored beats.
      logic [Width-1:0]   head_data_q;
      logic [KeepW-1:0]   head_keep_q;
      logic               head_last_q;
      logic               head_valid_q;
      logic [Width-1:0]   tail_data_q;
      logic [KeepW-1:0]   tail_keep_q;
      logic               tail_last_q;
      logic               tail_valid_q;

      if (Mode == 1) begin : g_simple
        assign s_ready = !head_valid_q || m_ready;
      end else begin : g_skid
        // Upstream stop at occupancy two: both places occupied.
        assign s_ready = !(head_valid_q && tail_valid_q);
      end

      wire pop  = (head_valid_q || tail_valid_q) && m_ready;
      wire push = s_valid && s_ready;

      always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
          head_valid_q <= 1'b0;
          tail_valid_q <= 1'b0;
          head_data_q  <= '0;
          head_keep_q  <= '0;
          head_last_q  <= 1'b0;
          tail_data_q  <= '0;
          tail_keep_q  <= '0;
          tail_last_q  <= 1'b0;
        end else begin
          if (Mode == 1) begin
            // One output register.  pop and push cannot both be zero-combined
            // with a push while the register is full because s_ready gates it.
            if (s_valid && (s_ready)) begin
              head_data_q  <= s_data;
              head_keep_q  <= s_keep;
              head_last_q  <= s_last;
              head_valid_q <= 1'b1;
            end else if (head_valid_q && m_ready) begin
              head_valid_q <= 1'b0;
            end
          end else begin
            if (head_valid_q && tail_valid_q) begin
              if (pop) begin
                // Head (older beat) leaves; tail promotes; no push is possible
                // in this state because s_ready is 0.
                head_data_q  <= tail_data_q;
                head_keep_q  <= tail_keep_q;
                head_last_q  <= tail_last_q;
                tail_valid_q <= 1'b0;
              end
            end else if (head_valid_q) begin
              if (pop) begin
                if (push) begin
                  head_data_q  <= s_data;
                  head_keep_q  <= s_keep;
                  head_last_q  <= s_last;
                end else begin
                  head_valid_q <= 1'b0;
                end
              end else if (push) begin
                // Stalled head plus an arrival: capture into the skid slot.
                tail_data_q <= s_data;
                tail_keep_q <= s_keep;
                tail_last_q <= s_last;
                tail_valid_q <= 1'b1;
              end
            end else if (push) begin
              head_data_q  <= s_data;
              head_keep_q  <= s_keep;
              head_last_q  <= s_last;
              head_valid_q <= 1'b1;
            end
          end
        end
      end

      assign m_valid = head_valid_q || (Mode == 2 ? tail_valid_q : 1'b0);
      assign m_data  = head_valid_q ? head_data_q : tail_data_q;
      assign m_keep  = head_valid_q ? head_keep_q : tail_keep_q;
      assign m_last  = head_valid_q ? head_last_q : tail_last_q;
    end
  endgenerate

`ifdef MGR1_SVA
  generate
    if (Mode != 0) begin : g_sva
      // Credit conservation: tokens are neither created nor destroyed.
      property p_credit;
        @(posedge aclk) disable iff (!aresetn)
          (int'(g_slot.head_valid_q) + int'(g_slot.tail_valid_q))
            - int'($past(g_slot.head_valid_q) + $past(g_slot.tail_valid_q))
          == (s_valid && s_ready) - (m_valid && m_ready);
      endproperty
      a_credit: assert property (p_credit);

      // Payload stability under stall.
      property p_stable;
        @(posedge aclk) disable iff (!aresetn)
          (m_valid && !m_ready) |=> ($stable(m_data) && $stable(m_keep) && $stable(m_last));
      endproperty
      a_stable: assert property (p_stable);

      // Lost-or-duplicated detection depends on the scoreboard, not the SVA:
      // rtl/tb/tb_axis_skid_buffer.sv checks delivery order and content.
    end
  endgenerate
`endif

endmodule
