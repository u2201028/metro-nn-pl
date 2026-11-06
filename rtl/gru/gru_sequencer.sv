// GRU temporal sequencer control (roadmap Phase 6B).
//
// Implements the dense temporal transaction schedule for H=128, I=1280,
// T=32 with an illustrative shared P=8, Q=16 affine engine.  Row order is
// [r, z, n] after exporter normalization.  The three gates span 384 rows or
// 48 output groups.  The input-channel tile k is issued outermost and the
// output group u=0..47 innermost; a partial sum for the same output group
// is revisited after 48 issues.  On the last input tile the affine bias is
// added once and each output-group result is written into its gate bank.
//
// Cycle budget reproduced by bench/cycle_models.py (GruCycleModel):
//   - input projection: 80 x 48 = 3,840 issues, plus 4 drain edges;
//   - one replay step: 8 x 48 = 384 issues + 28 overhead = 412 cycles;
//   - 32 steps: 13,184 cycles; steady-state update: 17,028 cycles.

`include "mgr1_defs.svh"

module gru_sequencer #(
  parameter int unsigned I = 1280,       // embedding dimension
  parameter int unsigned H = 128,        // hidden size
  parameter int unsigned T = 32,         // frames per window
  parameter int unsigned IN_TILE = 16,   // input channels per issue
  parameter int unsigned OUT_GROUP = 8,  // hidden channels per group
  parameter int unsigned STEP_OVERHEAD = 28
) (
  input  logic aclk,
  input  logic aresetn,

  input  logic        start,          // pulse: begin one window replay
  output logic        busy,
  output logic        done,           // pulse: final hidden state committed

  output logic [11:0] issue_addr,     // weight address (48k+u per bank b)
  output logic        issue_valid,
  input  logic        issue_ready,

  output logic [1:0]  gate_sel,       // 0..2 = r,z,n
  output logic [5:0]  group_idx,      // 0..47
  output logic [5:0]  step_idx,       // 0..31
  output logic        group_commit,   // one clock per committed group
  output logic [15:0] error_status
);

  localparam int unsigned IN_TILES  = I / IN_TILE;       // 80
  localparam int unsigned OUT_G     = 3 * H / OUT_GROUP; // 48
  localparam int unsigned REC_TILES = H / IN_TILE;       // 8

  typedef enum logic [1:0] {IDLE, INJECT, REPLAY, DRAIN} state_t;
  state_t state;

  logic [5:0]  step_q;
  logic [5:0]  group_q;
  logic [11:0] tile_q;
  logic        in_input_phase;

  assign busy   = (state != IDLE);
  assign done   = (state == DRAIN) && (step_q == T - 1) && (group_q == OUT_G - 1);
  assign issue_valid = (state == INJECT) || (state == REPLAY);
  assign issue_addr  = in_input_phase
      ? (tile_q * OUT_G + group_q)
      : (tile_q * OUT_G + group_q);
  assign gate_sel  = group_q / (H / OUT_GROUP);
  assign group_idx = group_q;
  assign step_idx  = step_q;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state          <= IDLE;
      step_q         <= '0;
      group_q        <= '0;
      tile_q         <= '0;
      in_input_phase <= 1'b1;
      group_commit   <= 1'b0;
      error_status   <= 16'd0;
    end else begin
      group_commit <= 1'b0;
      case (state)
        IDLE: begin
          if (start) begin
            state          <= INJECT;
            step_q         <= '0;
            group_q        <= '0;
            tile_q         <= '0;
            in_input_phase <= 1'b1;
          end
        end

        INJECT: begin
          // Input projection: IN_TILES x OUT_G issues.
          if (issue_ready) begin
            if (group_q == OUT_G - 1) begin
              group_q <= '0;
              if (tile_q == IN_TILES - 1) begin
                tile_q         <= '0;
                in_input_phase <= 1'b0;
                state          <= REPLAY;
              end else begin
                tile_q <= tile_q + 1;
              end
            end else begin
              group_q <= group_q + 1;
            end
          end
        end

        REPLAY: begin
          // Recurrent projection: REC_TILES x OUT_G issues per step,
          // then STEP_OVERHEAD cycles of gate arithmetic and commit.
          if (issue_ready) begin
            if (group_q == OUT_G - 1) begin
              group_q <= '0;
              if (tile_q == REC_TILES - 1) begin
                tile_q <= '0;
                state  <= DRAIN;
              end else begin
                tile_q <= tile_q + 1;
              end
            end else begin
              group_q <= group_q + 1;
            end
          end
        end

        DRAIN: begin
          // STEP_OVERHEAD cycles: gate evaluation, hidden commit.
          if (group_q == OUT_G - 1) begin
            group_commit <= 1'b1;
            group_q      <= '0;
            step_q       <= step_q + 1;
            if (step_q == T - 1) begin
              state <= IDLE;
            end else begin
              state <= REPLAY;
            end
          end else begin
            group_q <= group_q + 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
