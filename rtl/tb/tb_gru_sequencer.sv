// XSim testbench for rtl/gru/gru_sequencer.sv.
//
// Expected behavior - the schedule frozen in bench/cycle_models.py
// (GruCycleModel) and the roadmap Section 7 example:
//   - start pulse -> INJECT: 80 x 48 = 3,840 issue cycles, then 4 terminal
//     drain edges (PROJ_DRAIN) before the first replay step;
//   - each replay step: 8 x 48 = 384 issue cycles + STEP_OVERHEAD = 28
//     overhead cycles = 412 cycles; group_commit pulses once per committed
//     hidden vector (H/OUT_GROUP = 16 pulses per step, in the last 16
//     overhead cycles);
//   - full replay window: 32 x 412 = 13,184 cycles from the first replay
//     step to done;
//   - steady-state window (input projection + full replay): 3,840 + 4 +
//     13,184 = 17,028 busy cycles from the start edge; `done` pulses exactly
//     once, in the last busy cycle; busy returns low the cycle after;
//   - issues fire only with a READY sink; with a ready sink the totals are
//     exact; with stalls the ISSUE COUNTS are preserved (the schedule
//     stretches, it never issues extra or fewer);
//   - issue addressing: address = tile*48 + group with output group
//     u = 0..47 innermost, input tile k outermost;  address < 3840 always.
//
// Run on the Vivado host: vivado/xsim/run_xsim.sh
// Prints "TB PASS"; violations print FAIL lines and the TB $fatals.

`timescale 1ns / 1ps

module tb_gru_sequencer;

  localparam int unsigned I          = 1280;
  localparam int unsigned H          = 128;
  localparam int unsigned T          = 32;
  localparam int unsigned IN_TILE    = 16;
  localparam int unsigned OUT_GROUP  = 8;
  localparam int unsigned STEP_OH    = 28;
  localparam int unsigned PROJ_DRAIN = 4;

  localparam int unsigned IN_TILES  = I / IN_TILE;       // 80
  localparam int unsigned OUT_G     = 3 * H / OUT_GROUP; // 48
  localparam int unsigned REC_TILES = H / IN_TILE;       // 8
  localparam int unsigned COMMITS   = H / OUT_GROUP;     // 16

  localparam int unsigned EXP_INJ_ISSUES   = IN_TILES * OUT_G;          // 3840
  localparam int unsigned EXP_STEP_ISSUES  = REC_TILES * OUT_G;         // 384
  localparam int unsigned EXP_STEP_CYCLES  = EXP_STEP_ISSUES + STEP_OH; // 412
  localparam int unsigned EXP_WINDOW       = T * EXP_STEP_CYCLES;       // 13184
  localparam int unsigned EXP_STEADY       = EXP_INJ_ISSUES + PROJ_DRAIN +
                                             EXP_WINDOW;                // 17028

  logic aclk = 1'b0;
  logic aresetn = 1'b0;
  always #5 aclk = ~aclk;

  logic        start;
  logic        busy;
  logic        done;

  logic [11:0] issue_addr;
  logic        issue_valid;
  logic        issue_ready;

  logic [1:0]  gate_sel;
  logic [5:0]  group_idx;
  logic [5:0]  step_idx;
  logic        group_commit;
  logic [15:0] error_status;

  gru_sequencer #(
    .I(I), .H(H), .T(T), .IN_TILE(IN_TILE), .OUT_GROUP(OUT_GROUP),
    .STEP_OVERHEAD(STEP_OH), .PROJ_DRAIN(PROJ_DRAIN)
  ) dut (
    .aclk(aclk), .aresetn(aresetn),
    .start(start), .busy(busy), .done(done),
    .issue_addr(issue_addr), .issue_valid(issue_valid), .issue_ready(issue_ready),
    .gate_sel(gate_sel), .group_idx(group_idx), .step_idx(step_idx),
    .group_commit(group_commit), .error_status(error_status)
  );

  integer tb_errors;

  integer busy_cycles, issue_cnt, commit_cnt, done_cnt;
  int seen_at_done_cycle;

  // Per-step issue counts: step 0 carries INJECT (3,840) + REPLAY (384);
  // steps 1..31 carry REPLAY only (384).
  int step_seen [0:T-1];

  // Deterministic LCG, fixed seed.
  integer prng_state;
  function automatic int unsigned next_prng();
    prng_state = (prng_state * 1664525 + 1013904223) & 32'h7FFFFFFF;
    next_prng  = prng_state >> 8;
  endfunction

  // Monitor: counted on every posedge while busy.
  always @(posedge aclk) begin
    if (aresetn && busy) begin
      busy_cycles = busy_cycles + 1;
      if (issue_valid && issue_ready) issue_cnt = issue_cnt + 1;
      if (group_commit) commit_cnt = commit_cnt + 1;
      if (done) begin
        done_cnt = done_cnt + 1;
        seen_at_done_cycle = busy_cycles;
      end
      if (issue_valid && issue_ready) begin
        if (issue_addr >= IN_TILES * OUT_G) begin
          $display("FAIL: issue_addr out of range: %0d", issue_addr);
          tb_errors = tb_errors + 1;
        end
        if (step_idx < T) step_seen[step_idx] = step_seen[step_idx] + 1;
      end
    end
  end

  task automatic run_window(input int with_stalls);
    int stall_cycles;
    busy_cycles = 0;
    issue_cnt = 0;
    commit_cnt = 0;
    done_cnt = 0;
    seen_at_done_cycle = -1;
    for (int i = 0; i < T; i++) step_seen[i] = 0;
    prng_state = 32'hC0FF_EE01;

    @(negedge aclk);
    start = 1'b1;
    @(negedge aclk);
    start = 1'b0;
    while (busy) begin
      @(posedge aclk);
      if (with_stalls != 0 && (next_prng() % 7) == 0) begin
        issue_ready <= 1'b0;   // sink stalls for a few cycles
        stall_cycles = 1 + next_prng() % 4;
        repeat (stall_cycles) @(posedge aclk);
        issue_ready <= 1'b1;
      end
    end
    @(posedge aclk);
  endtask

  task automatic check_totals(input string tag, input int min_cycles);
    if (busy_cycles != EXP_STEADY && min_cycles == 0) begin
      $display("FAIL: %s busy cycles %0d expected %0d", tag, busy_cycles, EXP_STEADY);
      tb_errors = tb_errors + 1;
    end
    if (issue_cnt != EXP_INJ_ISSUES + T * EXP_STEP_ISSUES) begin
      $display("FAIL: %s issue count %0d expected %0d", tag, issue_cnt,
               EXP_INJ_ISSUES + T * EXP_STEP_ISSUES);
      tb_errors = tb_errors + 1;
    end
    if (commit_cnt != T * COMMITS) begin
      $display("FAIL: %s commit pulses %0d expected %0d", tag, commit_cnt, T * COMMITS);
      tb_errors = tb_errors + 1;
    end
    if (done_cnt != 1) begin
      $display("FAIL: %s done pulses %0d (want exactly 1)", tag, done_cnt);
      tb_errors = tb_errors + 1;
    end
    if (step_seen[0] != EXP_INJ_ISSUES + EXP_STEP_ISSUES) begin
      $display("FAIL: %s step 0 issues %0d expected %0d (projection + first replay)",
               tag, step_seen[0], EXP_INJ_ISSUES + EXP_STEP_ISSUES);
      tb_errors = tb_errors + 1;
    end
    for (int s = 1; s < T; s++) begin
      if (step_seen[s] != EXP_STEP_ISSUES) begin
        $display("FAIL: %s step %0d issues %0d expected %0d", tag, s,
                 step_seen[s], EXP_STEP_ISSUES);
        tb_errors = tb_errors + 1;
        break;
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    start       = 1'b0;
    issue_ready = 1'b1;
    for (int i = 0; i < T; i++) step_seen[i] = 0;

    repeat (4) @(posedge aclk);
    aresetn = 1'b1;
    repeat (4) @(posedge aclk);

    // Run 1: ready sink throughout - exact totals.
    run_window(0);
    check_totals("ready-sink", 0);
    if (seen_at_done_cycle != EXP_STEADY) begin
      $display("FAIL: done at busy cycle %0d (want %0d)", seen_at_done_cycle, EXP_STEADY);
      tb_errors = tb_errors + 1;
    end

    // Run 2: stalled sink - issue counts preserved, schedule stretches.
    run_window(1);
    check_totals("stalled", 1);
    if (busy_cycles <= EXP_STEADY) begin
      $display("FAIL: stalled run completed in %0d cycles (want > %0d)",
               busy_cycles, EXP_STEADY);
      tb_errors = tb_errors + 1;
    end

    @(posedge aclk);
    if (tb_errors == 0) begin
      $display("TB PASS: gru_sequencer: %0d steady cycles, %0d issues, %0d commits, done once; stalled run preserved issue counts",
               EXP_STEADY, EXP_INJ_ISSUES + T * EXP_STEP_ISSUES, T * COMMITS);
    end else begin
      $fatal(1, "TB FAILED with %0d error(s)", tb_errors);
    end
    $finish;
  end

endmodule
