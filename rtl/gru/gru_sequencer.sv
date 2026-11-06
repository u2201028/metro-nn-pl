`timescale 1ns / 1ps
// GRU temporal sequencer control (roadmap Phase 6B).
//
// Implements the dense temporal transaction schedule for H=128, I=1280,
// T=32 with an illustrative shared P=8, Q=16 affine engine.  Row order is
// [r, z, n] after exporter normalization.  The three gates span 384 rows or
// 48 output groups.  The input-channel tile k is issued outermost and the
// output group u=0..47 innermost; a partial sum for the same output group
// is revisited after 48 issues.  On the last recurrent input tile the
// affine bias is added once and each output-group result is written into
// its gate bank.
//
// After the fresh input projection (IN_TILES x OUT_G = 3,840 issues) the
// schedule allows DRAIN_CYCLES = 4 terminal-drain edges before the first
// replay step reuses the newly filled ring slot.  Each replay step is
// REC_TILES x OUT_G = 384 issues followed by STEP_OVERHEAD = 28 cycles of
// gate arithmetic and commit; during those cycles group_commit pulses once
// per committed hidden vector (H/OUT_GROUP = 16 pulses), and the next
// timestep begins only after the last of them.  Old h and new h occupy
// separate banks until an entire step commits.
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
  parameter int unsigned STEP_OVERHEAD = 28,
  parameter int unsigned PROJ_DRAIN = 4   // terminal-drain edges after INJECT
) (
  input  logic aclk,
  input  logic aresetn,

  input  logic        start,          // pulse: begin one window replay
  output logic        busy,
  output logic        done,           // final hidden state committed (1-cycle pulse)

  output logic [11:0] issue_addr,     // weight address (48k+u per bank b)
  output logic        issue_valid,
  input  logic        issue_ready,

  output logic [1:0]  gate_sel,       // 0..2 = r,z,n
  output logic [5:0]  group_idx,      // 0..47 (issue phase)
  output logic [5:0]  step_idx,       // 0..31
  output logic        group_commit,   // one pulse per committed hidden vector
  output logic [15:0] error_status
);

  localparam int unsigned IN_TILES  = I / IN_TILE;       // 80
  localparam int unsigned OUT_G     = 3 * H / OUT_GROUP; // 48
  localparam int unsigned REC_TILES = H / IN_TILE;       // 8
  localparam int unsigned COMMITS   = H / OUT_GROUP;     // 16 hidden vectors

  typedef enum logic [2:0] {IDLE, INJECT, PROJ_DRAIN_S, REPLAY, DRAIN} state_t;
  state_t state;

  logic [5:0]  step_q;
  logic [5:0]  group_q;
  logic [11:0] tile_q;
  logic [4:0]  drain_q;
  logic        in_input_phase;

  assign busy   = (state != IDLE);
  assign done   = (state == DRAIN) && (step_q == T - 1) &&
                  (drain_q == STEP_OVERHEAD - 1);
  assign issue_valid = (state == INJECT) || (state == REPLAY);
  assign issue_addr  = tile_q * OUT_G + group_q;
  assign gate_sel    = group_q / (H / OUT_GROUP);
  assign group_idx   = group_q;
  assign step_idx    = step_q;
  // One pulse per committed hidden vector: the last COMMIT cycles of the
  // STEP_OVERHEAD overhead window.
  assign group_commit = (state == DRAIN) &&
                        (drain_q >= STEP_OVERHEAD - COMMITS);
  assign error_status = 16'd0;  // reserved; faults are surfaced by the CSR

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state          <= IDLE;
      step_q         <= '0;
      group_q        <= '0;
      tile_q         <= '0;
      drain_q        <= '0;
      in_input_phase <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state          <= INJECT;
            step_q         <= '0;
            group_q        <= '0;
            tile_q         <= '0;
            drain_q        <= '0;
            in_input_phase <= 1'b1;
          end
        end

        INJECT: begin
          // Input projection: IN_TILES x OUT_G issues with a ready sink.
          if (issue_ready) begin
            if (group_q == OUT_G - 1) begin
              group_q <= '0;
              if (tile_q == IN_TILES - 1) begin
                tile_q <= '0;
                state  <= PROJ_DRAIN_S;
              end else begin
                tile_q <= tile_q + 1;
              end
            end else begin
              group_q <= group_q + 1;
            end
          end
        end

        PROJ_DRAIN_S: begin
          // DRAIN_CYCLES terminal-drain edges before the ring slot is reused.
          if (drain_q == PROJ_DRAIN - 1) begin
            drain_q        <= '0;
            in_input_phase <= 1'b0;
            state          <= REPLAY;
          end else begin
            drain_q <= drain_q + 1;
          end
        end

        REPLAY: begin
          // Recurrent projection: REC_TILES x OUT_G issues per step; on the
          // last one the affine engine moves on to gate evaluation.
          if (issue_ready) begin
            if (group_q == OUT_G - 1) begin
              group_q <= '0;
              if (tile_q == REC_TILES - 1) begin
                tile_q  <= '0;
                drain_q <= '0;
                state   <= DRAIN;
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
          if (drain_q == STEP_OVERHEAD - 1) begin
            group_q <= '0;
            step_q  <= step_q + 1;
            if (step_q == T - 1) begin
              state <= IDLE;
            end else begin
              state <= REPLAY;
            end
          end else begin
            drain_q <= drain_q + 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
