`timescale 1ns / 1ps
// External shell CSR block (roadmap Section 11 register worksheet).
//
// Implements the AXI4-Lite slave with the documented register map, the
// shadow-descriptor capture, the sticky error, W1C interrupt status and the
// eight 64-bit counter snapshot pairs.  Generated constants come from
// rtl/shell/csr_offsets.svh (generated from ip/schema/csr_map.json).
//
// Rules implemented here, from the schema's rules list:
//   - WSTRB is honored: only strobed bytes are committed to writable state;
//     COMMAND executes only when all four strobes are present;
//   - writes to read-only state are ignored;
//   - decoupled write-address / write-data capture, either may arrive first;
//   - BVALID/RVALID held until handshake;
//   - the sticky error retains the FIRST fault until acknowledged via
//     CLEAR_FAULT;
//   - a sticky-error clear in the same cycle as a new fault preserves the
//     new event.

`include "mgr1_defs.svh"
`include "csr_offsets.svh"

module csr_block #(
  parameter int unsigned NumCounters = 8
) (
  input  logic        aclk,
  input  logic        aresetn,

  // AXI4-Lite slave (write address / write data decoupled).
  input  logic        aw_valid,
  input  logic [31:0] aw_addr,
  output logic        aw_ready,
  input  logic        w_valid,
  input  logic [31:0] w_data,
  input  logic [3:0]  w_strb,
  output logic        w_ready,
  output logic        b_valid,
  output logic [1:0]  b_resp,
  input  logic        b_ready,

  input  logic        ar_valid,
  input  logic [31:0] ar_addr,
  output logic        ar_ready,
  output logic        r_valid,
  output logic [31:0] r_data,
  output logic [1:0]  r_resp,
  input  logic        r_ready,

  // Status and counters from the datapath.
  input  logic [2:0]  state_i,
  input  logic [31:0] error_cause_i,
  input  logic        error_valid_i,
  input  logic [31:0] model_gen_i,
  input  logic [31:0] stream_epoch_i,
  input  logic [63:0] counters_i [NumCounters]
);

  import mgr1_csr::*;

  logic [31:0] id_q, caps_q, limits_q;
  logic [2:0]  state_q;
  logic [31:0] error_q;
  logic [31:0] irq_status_q;
  logic [31:0] desc_lo_q, desc_hi_q, desc_len_q, arg_q;
  logic [31:0] model_gen_q, stream_epoch_q;
  logic [31:0] irq_mask_q;
  logic [31:0] snap_seq_q;
  logic [63:0] counter_snap_q [NumCounters];

  logic        aw_pending;
  logic [31:0] aw_addr_q;
  logic        w_pending;
  logic [31:0] w_data_q;
  logic [3:0]  w_strb_q;

  logic        cmd_fire;
  logic [31:0] cmd_word;
  // Combinational: a clear-fault command commits on this edge.
  logic        clear_cmd_fire;

  // Initial identity values; firmware may revise at integration time.
  initial begin
    id_q     = 32'h0001_4D47;
    caps_q   = 32'h0000_000F;
    limits_q = 32'd0;
  end

  // Per-byte write commit for a 32-bit register: only strobed bytes change.
  function automatic logic [31:0] apply_strb(
    input logic [31:0] old, input logic [31:0] wr, input logic [3:0] strb);
    logic [31:0] merged;
    merged = old;
    if (strb[0]) merged[7:0]   = wr[7:0];
    if (strb[1]) merged[15:8]  = wr[15:8];
    if (strb[2]) merged[23:16] = wr[23:16];
    if (strb[3]) merged[31:24] = wr[31:24];
    return merged;
  endfunction

  assign cmd_fire = aw_pending && w_pending;
  assign cmd_word = w_data_q;
  assign clear_cmd_fire = cmd_fire && aw_addr_q == OFF_COMMAND &&
                          w_strb_q == 4'b1111 && cmd_word[2:0] == CMD_CLEAR_FAULT;

  // Write handling: capture address and data independently, commit on both.
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      aw_pending <= 1'b0; aw_addr_q <= '0;
      w_pending  <= 1'b0; w_data_q <= '0; w_strb_q <= '0;
      b_valid    <= 1'b0; b_resp <= 2'b00;
      state_q    <= ST_IDLE;
      error_q    <= '0;
      irq_status_q <= '0;
      desc_lo_q  <= '0; desc_hi_q <= '0; desc_len_q <= '0; arg_q <= '0;
      model_gen_q <= '0; stream_epoch_q <= '0;
      irq_mask_q <= '0; snap_seq_q <= '0;
      for (int i = 0; i < NumCounters; i++) counter_snap_q[i] <= '0;
    end else begin
      if (aw_valid && !aw_pending) begin
        aw_pending <= 1'b1;
        aw_addr_q  <= aw_addr;
      end
      if (w_valid && !w_pending) begin
        w_pending <= 1'b1;
        w_data_q  <= w_data;
        w_strb_q  <= w_strb;
      end

      if (cmd_fire && (aw_addr_q == OFF_COMMAND ? (w_strb_q == 4'b1111) : 1'b1)) begin
        aw_pending <= 1'b0;
        w_pending  <= 1'b0;
        b_valid    <= 1'b1;
        b_resp     <= 2'b00;  // OKAY
        case (aw_addr_q)
          OFF_COMMAND: begin
            case (cmd_word[2:0])
              CMD_LOAD:    if (state_q == ST_IDLE || state_q == ST_READY)
                             state_q <= ST_LOADING;
              CMD_COMMIT:  if (state_q == ST_LOADING) begin
                             state_q      <= ST_READY;
                             model_gen_q  <= model_gen_q + 1;
                             stream_epoch_q <= stream_epoch_q + 1;
                           end
              CMD_SNAPSHOT: begin
                             for (int i = 0; i < NumCounters; i++)
                               counter_snap_q[i] <= counters_i[i];
                             snap_seq_q <= snap_seq_q + 1;
                           end
              CMD_CLEAR_FAULT: begin
                             // A sticky-error clear in the same cycle as a
                             // new fault preserves the new event (the
                             // sticky capture below re-arms on this edge).
                             if (!(error_valid_i && error_cause_i != '0))
                               error_q <= '0;
                           end
              default: ;
            endcase
          end
          OFF_DESC_LO:  desc_lo_q  <= apply_strb(desc_lo_q,  w_data_q, w_strb_q);
          OFF_DESC_HI:  desc_hi_q  <= apply_strb(desc_hi_q,  w_data_q, w_strb_q);
          OFF_DESC_LEN: desc_len_q <= apply_strb(desc_len_q, w_data_q, w_strb_q);
          OFF_ARG:      arg_q      <= apply_strb(arg_q,      w_data_q, w_strb_q);
          OFF_IRQ_MASK: irq_mask_q <= apply_strb(irq_mask_q, w_data_q, w_strb_q);
          OFF_IRQ_STATUS: begin
            // W1C: clear only the written-one bits of strobed bytes.
            for (int b = 0; b < 4; b++) begin
              if (w_strb_q[b])
                irq_status_q[b*8 +: 8] <= irq_status_q[b*8 +: 8] & ~w_data_q[b*8 +: 8];
            end
          end
          default: ;  // writes to read-only state are ignored
        endcase
      end else if (cmd_fire) begin
        // A partial-strobe COMMAND write consumes the handshake without
        // executing the command (schema rule: honor WSTRB).
        aw_pending <= 1'b0;
        w_pending  <= 1'b0;
        b_valid    <= 1'b1;
        b_resp     <= 2'b00;
      end else if (b_valid && b_ready) begin
        b_valid <= 1'b0;
      end

      // Sticky error capture: retains the FIRST cause until acknowledged,
      // but a clear in the same cycle as a new fault keeps the new cause.
      if (error_valid_i && error_cause_i != '0 &&
          (error_q == '0 || clear_cmd_fire))
        error_q <= error_cause_i;
      if (error_valid_i && error_cause_i != '0) state_q <= ST_FAULT;

      // Model/epoch visibility follows the datapath after commit.
      if (state_q == ST_READY) begin
        model_gen_q    <= model_gen_i;
        stream_epoch_q <= stream_epoch_i;
      end
    end
  end

  // Read handling.
  logic [31:0] rdata_mux;
  always_comb begin
    unique case (ar_addr)
      OFF_ID:          rdata_mux = id_q;
      OFF_ABI:         rdata_mux = 32'h0000_0001;
      OFF_CAPS:        rdata_mux = caps_q;
      OFF_LIMITS:      rdata_mux = limits_q;
      OFF_STATUS:      rdata_mux = {29'd0, state_q};
      OFF_ERROR:       rdata_mux = error_q;
      OFF_IRQ_STATUS:  rdata_mux = irq_status_q;
      OFF_DESC_LO:     rdata_mux = desc_lo_q;
      OFF_DESC_HI:     rdata_mux = desc_hi_q;
      OFF_DESC_LEN:    rdata_mux = desc_len_q;
      OFF_ARG:         rdata_mux = arg_q;
      OFF_MODEL_GEN:   rdata_mux = model_gen_q;
      OFF_STREAM_EPOCH:rdata_mux = stream_epoch_q;
      OFF_IRQ_MASK:    rdata_mux = irq_mask_q;
      OFF_SNAP_SEQ:    rdata_mux = snap_seq_q;
      default: begin
        // Counter snapshot pairs, low then high.
        rdata_mux = '0;
        for (int i = 0; i < NumCounters; i++) begin
          if (ar_addr == 32'h40 + i*8)     rdata_mux = counter_snap_q[i][31:0];
          if (ar_addr == 32'h40 + i*8 + 4) rdata_mux = counter_snap_q[i][63:32];
        end
      end
    endcase
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      ar_ready <= 1'b0;
      r_valid  <= 1'b0;
      r_data   <= '0;
      r_resp   <= 2'b00;
    end else begin
      ar_ready <= 1'b1;
      if (ar_valid && ar_ready) begin
        r_valid <= 1'b1;
        r_data  <= rdata_mux;
        r_resp  <= 2'b00;
      end else if (r_valid && r_ready) begin
        r_valid <= 1'b0;
      end
    end
  end

endmodule
