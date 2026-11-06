// XSim testbench for rtl/axi/axis_skid_buffer.sv.
//
// Expected behavior (roadmap Section 7 / bench/cycle_models.py):
//   - Mode 0: combinational bypass; delivered stream equals the source stream.
//   - Mode 1: capacity 1; no acceptance edge while a beat is undelivered.
//   - Mode 2: capacity 2 (head = out register, tail = skid register);
//     strictly in-order, loss-free delivery; no acceptance edge while two
//     beats are undelivered; (data, keep, last) stable under a stalled sink,
//     independent of the upstream after it deasserts s_valid.
//
// Driving pattern: inputs change on negedge; handshakes are sampled on
// posedge (race-free AXI-Stream TB style).  Deterministic LCG stall
// patterns with fixed seeds - no classes, no random sequences - so this
// runs under XSim and also elaborates under pyslang (tools/check_rtl.py).
//
// Run on the Vivado host: vivado/xsim/run_xsim.sh
// Prints "TB PASS" and finishes silently; every violation increments
// tb_errors and prints a FAIL line.

`timescale 1ns / 1ps

module tb_axis_skid_buffer;

  localparam int Width    = 128;
  localparam int KeepW    = Width / 8;
  localparam int NumBeats = 64;

  logic aclk = 1'b0;
  logic aresetn = 1'b0;
  always #5 aclk = ~aclk;

  // Per-mode interface signal arrays; one DUT per mode.
  logic                          sv [0:2];
  logic [Width-1:0]              sd [0:2];
  logic [KeepW-1:0]              sk [0:2];
  logic                          sl [0:2];
  logic                          srq [0:2];
  logic                          mv [0:2];
  logic [Width-1:0]              md [0:2];
  logic [KeepW-1:0]              mk [0:2];
  logic                          ml [0:2];
  logic                          mrq [0:2];

  axis_skid_buffer #(.Width(Width), .Mode(0)) dut_m0 (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(sv[0]), .s_data(sd[0]), .s_keep(sk[0]), .s_last(sl[0]), .s_ready(srq[0]),
    .m_valid(mv[0]), .m_data(md[0]), .m_keep(mk[0]), .m_last(ml[0]), .m_ready(mrq[0])
  );
  axis_skid_buffer #(.Width(Width), .Mode(1)) dut_m1 (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(sv[1]), .s_data(sd[1]), .s_keep(sk[1]), .s_last(sl[1]), .s_ready(srq[1]),
    .m_valid(mv[1]), .m_data(md[1]), .m_keep(mk[1]), .m_last(ml[1]), .m_ready(mrq[1])
  );
  axis_skid_buffer #(.Width(Width), .Mode(2)) dut_m2 (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(sv[2]), .s_data(sd[2]), .s_keep(sk[2]), .s_last(sl[2]), .s_ready(srq[2]),
    .m_valid(mv[2]), .m_data(md[2]), .m_keep(mk[2]), .m_last(ml[2]), .m_ready(mrq[2])
  );

  integer tb_errors;

  // Deterministic LCG, fixed seed per run.
  integer prng_state;
  function automatic int unsigned next_prng();
    prng_state = (prng_state * 1664525 + 1013904223) & 32'h7FFFFFFF;
    next_prng  = prng_state >> 8;
  endfunction

  function automatic logic [Width-1:0] beat_data(input int i);
    logic [63:0] lo, hi;
    lo = (i + 1) * 64'd2654435761;
    hi = lo ^ 64'h9E37_79B9_7F4A_7C15;
    beat_data = {hi, lo};
    if (i % 7 == 0) beat_data[63:0] = 64'hDEAD_BEEF_C0DE_0000 + i;
  endfunction

  // Expected stream (identical for all modes).
  logic [Width-1:0] exp_data [0:NumBeats-1];
  logic [KeepW-1:0] exp_keep [0:NumBeats-1];
  logic             exp_last [0:NumBeats-1];

  // Stability under stall: what was held at the previous posedge, per mode.
  logic             held_active_q [0:2];
  logic [Width-1:0] held_data_q   [0:2];
  logic [KeepW-1:0] held_keep_q   [0:2];
  logic             held_last_q   [0:2];

  // One mode test: NumBeats beats, upstream gaps, sink backpressure bursts.
  task automatic run_one_mode(input int mode);
    int sent_i, delivered_i, gap, idle_sink, hold_cycles;
    logic fire_s, fire_m;

    sent_i      = 0;
    delivered_i = 0;
    idle_sink   = 0;
    prng_state  = 32'h5EED_0000 + mode * 7919;
    sv[mode]    = 1'b0;
    mrq[mode]   = 1'b0;

    while (!(sent_i == NumBeats && delivered_i == NumBeats)) begin
      // ---- negedge: prepare signals held stable over the next posedge.
      @(negedge aclk);

      if (sent_i < NumBeats && sv[mode] == 1'b0) begin
        gap = next_prng() % 3;
        repeat (gap) begin
          sv[mode] <= 1'b0;
          @(negedge aclk);
        end
        sd[mode] <= beat_data(sent_i);
        sk[mode] <= '1;
        sl[mode] <= (sent_i == NumBeats - 1);
        sv[mode] <= 1'b1;
      end

      if (idle_sink > 0) begin
        idle_sink = idle_sink - 1;
        mrq[mode] <= 1'b0;
      end else begin
        idle_sink = next_prng() % 3;
        mrq[mode] <= 1'b1;
      end

      // ---- posedge: sample handshakes (stable since the last negedge).
      @(posedge aclk);
      fire_s = sv[mode] && srq[mode];
      fire_m = mv[mode] && mrq[mode];

      // Stop rule: occupancy here is (sent_i - delivered_i) BEPORE updates.
      if (fire_s && mode == 2 && (sent_i - delivered_i) >= 2) begin
        $display("FAIL: mode 2 accepted a beat with two undelivered in the DUT (t=%0t)", $time);
        tb_errors = tb_errors + 1;
      end
      if (fire_s && mode == 1 && (sent_i - delivered_i) >= 1) begin
        $display("FAIL: mode 1 accepted a beat with one undelivered in the DUT (t=%0t)", $time);
        tb_errors = tb_errors + 1;
      end

      // Stability under stall: if the previous edge stalled a valid beat it
      // must still be presented, unchanged, now.
      if (held_active_q[mode]) begin
        if (!(mv[mode]) || md[mode] !== held_data_q[mode] ||
            mk[mode] !== held_keep_q[mode] || ml[mode] !== held_last_q[mode]) begin
          $display("FAIL: mode %0d payload changed or dropped under stall (t=%0t)", mode, $time);
          tb_errors = tb_errors + 1;
        end
        held_active_q[mode] = mv[mode] && !mrq[mode];
      end else if (mv[mode] && !mrq[mode]) begin
        held_active_q[mode] = 1'b1;
      end
      held_data_q[mode] = md[mode];
      held_keep_q[mode] = mk[mode];
      held_last_q[mode] = ml[mode];

      // Delivery check: in-order, loss-free, exact payload.
      if (fire_m) begin
        if (delivered_i >= sent_i) begin
          $display("FAIL: mode %0d delivered a beat never sent (t=%0t)", mode, $time);
          tb_errors = tb_errors + 1;
        end else if (md[mode] !== exp_data[delivered_i] ||
                     mk[mode] !== exp_keep[delivered_i] ||
                     ml[mode] !== exp_last[delivered_i]) begin
          $display("FAIL: mode %0d beat %0d content mismatch (t=%0t)", mode, delivered_i, $time);
          tb_errors = tb_errors + 1;
        end
        delivered_i = delivered_i + 1;
      end

      if (fire_s) begin
        sent_i  = sent_i + 1;
        sv[mode] <= 1'b0;  // deassert after the accepted edge
      end
    end

    sv[mode] <= 1'b0;
    mrq[mode] <= 1'b0;
    $display("mode %0d: %0d beats sent, %0d delivered", mode, sent_i, delivered_i);
  endtask

  initial begin
    tb_errors = 0;
    for (int i = 0; i < NumBeats; i++) begin
      exp_data[i] = beat_data(i);
      exp_keep[i] = '1;
      exp_last[i] = (i == NumBeats - 1);
    end
    for (int m = 0; m < 3; m++) held_active_q[m] = 1'b0;

    repeat (4) @(posedge aclk);
    aresetn = 1'b1;
    repeat (4) @(posedge aclk);

    run_one_mode(0);
    run_one_mode(1);
    run_one_mode(2);

    @(posedge aclk);
    if (tb_errors == 0) begin
      $display("TB PASS: axis_skid_buffer modes 0/1/2: %0d beats each, in-order, lossless, stable", NumBeats);
    end
    $finish;
  end

endmodule
