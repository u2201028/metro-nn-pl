// XSim testbench for rtl/axi/axis_packet_ingress.sv.
//
// Expected behavior (docs/04-packet-abi.md, roadmap Section 11):
//   - Framed packets (header + payload) pass through byte-for-byte; healthy
//     streams produce exactly one pkt_accept pulse per packet, on its final
//     beat edge: Frame 9,410 beats, Embedding 82 beats, Completion 3 beats.
//   - The header is parsed little-endian: magic "MGR1" = bytes 0..3 =
//     data[31:0] = 32'h3152_474D; abi_major at byte 4 = data[39:32] must be 1;
//     kind at byte 5 = data[47:40] in {1,2,3}; flags bytes 6..7 =
//     data[63:48] must be 0; payload_len bytes 28..31 = header beat 2
//     data[127:96] must match the kind's fixed payload (150528 / 1280 / 16).
//   - Non-final beats carry all-lane TKEEP (0xFFFF); v1 payload lengths are
//     beat-multiples, so the final beat also carries 0xFFFF.
//   - Exactly one TLAST per packet, on the final beat.
//   - Faults are sticky with one reject pulse each: 1 illegal header beat 1
//     (bad magic / abi / kind / flags), 2 early TLAST (short packet),
//     3 over-length (declared end without TLAST), 4 payload_len inconsistent
//     with the kind (header beat 2 field), 5 illegal TKEEP.  The offending
//     beat is dropped; after a sticky fault s_ready stays low until reset.
//
// Driving pattern: the ingress drives inputs from tasks aligned to negedge;
// handshakes are sampled at posedge (stable since the negedge); registered
// pulses (pkt_accept/pkt_reject/fault_*) are sampled at the next negedge.
// Deterministic patterns only - XSim-compatible, and elaborates under
// pyslang via tools/check_rtl.py.
//
// Run on the Vivado host: vivado/xsim/run_xsim.sh
// Prints "TB PASS" on success; every violation prints a FAIL line.

`timescale 1ns / 1ps

module tb_axis_packet_ingress;

  localparam int W = 128;
  localparam int KeepW = W / 8;
  localparam logic [KeepW-1:0] KEEP_FULL = '1;

  logic aclk = 1'b0;
  logic aresetn = 1'b0;
  always #5 aclk = ~aclk;

  logic             sv;
  logic [W-1:0]     sd;
  logic [KeepW-1:0] sk;
  logic             sl;
  logic             srq;
  logic             mv;
  logic [W-1:0]     md;
  logic [KeepW-1:0] mk;
  logic             ml;
  logic             mrq;

  logic        pkt_accept, pkt_reject, fault_sticky;
  logic [31:0] fault_cause;

  axis_packet_ingress #(.DataWidth(W)) dut (
    .aclk(aclk), .aresetn(aresetn),
    .s_valid(sv), .s_data(sd), .s_keep(sk), .s_last(sl), .s_ready(srq),
    .m_valid(mv), .m_data(md), .m_keep(mk), .m_last(ml), .m_ready(mrq),
    .pkt_accept(pkt_accept), .pkt_reject(pkt_reject),
    .fault_sticky(fault_sticky), .fault_cause(fault_cause)
  );

  integer tb_errors;
  int     obs_fwd_cnt;     // forwarded beats since the last revive
  int     beats_done;      // beats consumed by the current packet send

  integer prng_state;
  function automatic int unsigned next_prng();
    prng_state = (prng_state * 1664525 + 1013904223) & 32'h7FFFFFFF;
    next_prng  = prng_state >> 8;
  endfunction

  function automatic logic [W-1:0] beat_payload(input int idx);
    logic [63:0] lo, hi;
    lo = (idx + 1) * 64'd22695477;
    hi = lo ^ 64'h5DEE_CE66_0000_0001;
    return {hi, lo};
  endfunction

  function automatic logic [W-1:0] header_lo(input logic [7:0] kind);
    logic [W-1:0] b;
    b = '0;
    b[31:0]   = 32'h3152_474D;   // magic, little-endian bytes M G R 1
    b[39:32]  = 8'd1;            // abi_major
    b[47:40]  = kind;
    b[63:48]  = 16'd0;           // flags
    b[95:64]  = 32'd7;           // model_gen
    b[127:96] = 32'd11;          // epoch
    return b;
  endfunction

  function automatic logic [W-1:0] header_hi(
    input logic [63:0] seq, input logic [15:0] stream_id,
    input logic [15:0] format_id, input logic [31:0] payload_len
  );
    logic [W-1:0] b;
    b = '0;
    b[63:0]    = seq;
    b[71:64]   = stream_id[7:0];
    b[79:72]   = stream_id[15:8];
    b[87:80]   = format_id[7:0];
    b[95:88]   = format_id[15:8];
    b[103:96]  = payload_len[7:0];
    b[111:104] = payload_len[15:8];
    b[119:112] = payload_len[23:16];
    b[127:120] = payload_len[31:24];
    return b;
  endfunction

  // Send one beat; returns at the negedge where this beat's registered
  // pulses (if any) are live.  expect_fwd=0 for beats expected to be dropped
  // (faulting beats).
  task automatic send_beat(input logic [W-1:0] d, input logic [KeepW-1:0] k,
                           input logic l, input logic expect_fwd = 1'b1);
    @(negedge aclk);
    sd <= d;
    sk <= k;
    sl <= l;
    sv <= 1'b1;
    forever begin
      @(posedge aclk);
      if (sv && srq) begin
        // Beat transfers at this edge; verify forwarding now.
        if (!fault_sticky && expect_fwd) begin
          if (!(mv === 1'b1) || md !== sd || mk !== sk || ml !== sl) begin
            $display("FAIL: forwarded beat corrupted or dropped (mv=%0b t=%0t)", mv, $time);
            tb_errors = tb_errors + 1;
          end
          obs_fwd_cnt = obs_fwd_cnt + 1;
        end
        @(negedge aclk);
        beats_done = beats_done + 1;
        sv <= 1'b0;
        return;
      end
    end
  endtask

  // Occasional downstream stalls between beats (healthy-path traffic only).
  task automatic send_beat_bp(input logic [W-1:0] d, input logic [KeepW-1:0] k,
                              input logic l, input logic expect_fwd = 1'b1);
    int bp;
    send_beat(d, k, l, expect_fwd);
    bp = next_prng() % 3;
    repeat (bp) begin
      @(negedge aclk);
      mrq <= 1'b0;
      @(posedge aclk);
      @(negedge aclk);
      mrq <= 1'b1;
    end
  endtask

  task automatic revive();
    aresetn = 1'b0;
    sv <= 1'b0;
    repeat (4) @(posedge aclk);
    @(negedge aclk);
    aresetn = 1'b1;
    repeat (4) @(posedge aclk);
    @(negedge aclk);
    obs_fwd_cnt = 0;
    beats_done  = 0;
  endtask

  task automatic check_no_fault(string tag);
    if (fault_sticky !== 1'b0) begin
      $display("FAIL: %s faulted (cause=%0d)", tag, fault_cause);
      tb_errors = tb_errors + 1;
    end
  endtask

  initial begin
    tb_errors = 0;
    obs_fwd_cnt = 0;
    mrq = 1'b1;

    // 1) Healthy frame packet: 9,410 beats with backpressure bursts.
    revive();
    send_beat_bp(header_lo(8'd1), KEEP_FULL, 1'b0);
    send_beat_bp(header_hi(64'd1000, 16'd5, 16'd2, 32'd150528), KEEP_FULL, 1'b0);
    for (int i = 2; i < 9410; i++) begin
      send_beat_bp(beat_payload(i), KEEP_FULL, i == 9409);
    end
    if (!(pkt_accept === 1'b1) || fault_sticky !== 1'b0 || beats_done != 9410 ||
        obs_fwd_cnt != 9410) begin
      $display("FAIL: frame packet: accept=%0b sticky=%0b beats=%0d fwd=%0d",
               pkt_accept, fault_sticky, beats_done, obs_fwd_cnt);
      tb_errors = tb_errors + 1;
    end
    check_no_fault("frame packet");
    $display("frame packet done");

    // 2) Healthy embedding packet: 82 beats.
    revive();
    send_beat_bp(header_lo(8'd2), KEEP_FULL, 1'b0);
    send_beat_bp(header_hi(64'd2000, 16'd6, 16'd3, 32'd1280), KEEP_FULL, 1'b0);
    for (int i = 2; i < 82; i++) send_beat_bp(beat_payload(i), KEEP_FULL, i == 81);
    if (!(pkt_accept === 1'b1) || fault_sticky !== 1'b0 || beats_done != 82) begin
      $display("FAIL: embedding packet: accept=%0b sticky=%0b beats=%0d",
               pkt_accept, fault_sticky, beats_done);
      tb_errors = tb_errors + 1;
    end
    $display("embedding packet done");

    // 3) Healthy completion packet: 3 beats.
    revive();
    send_beat(header_lo(8'd3), KEEP_FULL, 1'b0);
    send_beat(header_hi(64'd3000, 16'd7, 16'd4, 32'd16), KEEP_FULL, 1'b0);
    send_beat(128'h2_0000_0001, KEEP_FULL, 1'b1);  // status VALID, logit, one sample
    if (!(pkt_accept === 1'b1) || fault_sticky !== 1'b0 || beats_done != 3) begin
      $display("FAIL: completion packet: accept=%0b sticky=%0b beats=%0d",
               pkt_accept, fault_sticky, beats_done);
      tb_errors = tb_errors + 1;
    end
    $display("completion packet done");

    // 4) Bad magic: reject pulse at the offending edge, cause 1, dropped
    //    beat, admission halted.
    revive();
    send_beat(header_lo(8'd1) & 64'hFFFF_FFFF_0000_0000 | 64'h0000_0000_DEAD_BEEF,
              KEEP_FULL, 1'b0, 1'b0);   // offending header beat: dropped on m
    if (!(pkt_accept === 1'b0 && pkt_reject === 1'b1 && fault_sticky === 1'b1 &&
          fault_cause === 32'd1)) begin
      $display("FAIL: bad magic: reject=%0b sticky=%0b cause=%0d accept=%0b",
               pkt_reject, fault_sticky, fault_cause, pkt_accept);
      tb_errors = tb_errors + 1;
    end
    @(posedge aclk);
    if (srq !== 1'b0) begin
      $display("FAIL: admission not halted after sticky fault");
      tb_errors = tb_errors + 1;
    end
    @(posedge aclk);
    if (srq !== 1'b0) begin
      $display("FAIL: admission resumed without reset");
      tb_errors = tb_errors + 1;
    end
    $display("bad magic case done");

    // 5) Early TLAST on a payload beat (short packet): cause 2.
    revive();
    send_beat(header_lo(8'd1), KEEP_FULL, 1'b0);
    send_beat(header_hi(64'd1, 16'd0, 16'd0, 32'd150528), KEEP_FULL, 1'b0);
    send_beat(beat_payload(2), KEEP_FULL, 1'b0);
    send_beat(beat_payload(3), KEEP_FULL, 1'b0);
    send_beat(beat_payload(4), KEEP_FULL, 1'b0);
    send_beat(beat_payload(5), KEEP_FULL, 1'b1, 1'b0);   // TLAST far too early
    if (!(pkt_reject === 1'b1 && fault_sticky === 1'b1 && fault_cause === 32'd2)) begin
      $display("FAIL: short packet: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    check_halted_gate();
    $display("short packet case done");

    // 6) Over-length: full 82-beat embedding without any TLAST: cause 3.
    revive();
    send_beat(header_lo(8'd2), KEEP_FULL, 1'b0);
    send_beat(header_hi(64'd1, 16'd0, 16'd0, 32'd1280), KEEP_FULL, 1'b0);
    for (int i = 2; i < 82; i++) send_beat(beat_payload(i), KEEP_FULL, 1'b0,
                                           i != 81);  // beat 81 is dropped
    // beat 81 (index 81, the 82nd) arrived without TLAST -> fault on that edge.
    if (!(pkt_reject === 1'b1 && fault_sticky === 1'b1 && fault_cause === 32'd3)) begin
      $display("FAIL: overlength: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    check_halted_gate();
    $display("overlength case done");

    // 7) Header beat 2 field faults under fresh resets.
    //    a) payload_len inconsistent with the kind: cause 4.
    revive();
    send_beat(header_lo(8'd2), KEEP_FULL, 1'b0);
    send_beat(header_hi(64'd1, 16'd0, 16'd0, 32'd150528), KEEP_FULL, 1'b0, 1'b0);
    if (!(pkt_reject === 1'b1 && fault_cause === 32'd4 && fault_sticky === 1'b1)) begin
      $display("FAIL: kind/len mismatch: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    //    b) abi_major = 2 on header beat 1: cause 1.
    revive();
    begin
      logic [W-1:0] b;
      b = header_lo(8'd1);
      b[39:32] = 8'd2;
      send_beat(b, KEEP_FULL, 1'b0, 1'b0);
    end
    if (!(pkt_reject === 1'b1 && fault_cause === 32'd1)) begin
      $display("FAIL: bad abi_major: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    //    c) flags != 0 on header beat 1: cause 1.
    revive();
    begin
      logic [W-1:0] b;
      b = header_lo(8'd1);
      b[63:48] = 16'h0001;
      send_beat(b, KEEP_FULL, 1'b0, 1'b0);
    end
    if (!(pkt_reject === 1'b1 && fault_cause === 32'd1)) begin
      $display("FAIL: bad flags: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    check_halted_gate();
    $display("header field cases done");

    // 8) Partial TKEEP on a non-final beat: cause 5.
    revive();
    send_beat(header_lo(8'd3), KEEP_FULL, 1'b0);
    send_beat(header_hi(64'd1, 16'd0, 16'd0, 32'd16), KEEP_FULL, 1'b0);
    send_beat(128'h2_0000_0001, 16'h0001, 1'b1, 1'b0);
    if (!(pkt_reject === 1'b1 && fault_cause === 32'd5 && fault_sticky === 1'b1)) begin
      $display("FAIL: bad tkeep: reject=%0b cause=%0d", pkt_reject, fault_cause);
      tb_errors = tb_errors + 1;
    end
    check_halted_gate();
    $display("bad tkeep case done");

    @(posedge aclk);
    if (tb_errors == 0) begin
      $display("TB PASS: axis_packet_ingress: healthy 9410/82/3 framed packets + 5 fault classes");
    end else begin
      $fatal(1, "TB FAILED with %0d error(s)", tb_errors);
    end
    $finish;
  end

  task automatic check_halted_gate();
    @(posedge aclk);
    if (srq !== 1'b0) begin
      $display("FAIL: admission not halted after sticky fault");
      tb_errors = tb_errors + 1;
    end
    @(posedge aclk);
    if (srq !== 1'b0) begin
      $display("FAIL: admission resumed without reset");
      tb_errors = tb_errors + 1;
    end
    sv <= 1'b0;
  endtask

endmodule
