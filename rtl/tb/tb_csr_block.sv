// XSim testbench for rtl/shell/csr_block.sv.
//
// Expected behavior - the register map and rules from
// ip/schema/csr_map.json (roadmap Section 11):
//   1. WSTRB honored: only strobed bytes commit to writable registers;
//      COMMAND executes only with all four byte strobes.
//   2. Writes to read-only registers are ignored (value unchanged).
//   3. Write-address and write-data are decoupled: either may arrive first
//      and both must complete the write.
//   4. BVALID and RVALID are held until their handshake.
//   5. Sticky ERROR retains the FIRST fault until CLEAR_FAULT; a clear in
//      the same cycle as a new fault preserves the new event.
//   6. Command behavior: LOAD from IDLE/READY -> LOADING; COMMIT from
//      LOADING -> READY and bumps MODEL_GEN/STREAM_EPOCH; SNAPSHOT latches
//      all counters and bumps SNAP_SEQ; CLEAR_FAULT clears the sticky error.
//   7. W1C on IRQ_STATUS; with no sources asserted the value stays 0.
//   8. Unmapped read addresses return 0.
//
// Run on the Vivado host: vivado/xsim/run_xsim.sh
// Prints "TB PASS" on success; violations print FAIL lines and the TB
// $fatals at exit.

`timescale 1ns / 1ps

module tb_csr_block;

  localparam int unsigned NumCounters = 8;

  logic aclk = 1'b0;
  logic aresetn = 1'b0;
  always #5 aclk = ~aclk;

  logic        aw_valid;
  logic [31:0] aw_addr;
  logic        aw_ready;
  logic        w_valid;
  logic [31:0] w_data;
  logic [3:0]  w_strb;
  logic        w_ready;
  logic        b_valid;
  logic [1:0]  b_resp;
  logic        b_ready;

  logic        ar_valid;
  logic [31:0] ar_addr;
  logic        ar_ready;
  logic        r_valid;
  logic [31:0] r_data;
  logic [1:0]  r_resp;
  logic        r_ready;

  logic [2:0]  state_i;
  logic [31:0] error_cause_i;
  logic        error_valid_i;
  logic [31:0] model_gen_i;
  logic [31:0] stream_epoch_i;
  logic [63:0] counters_i [NumCounters];

  csr_block #(.NumCounters(NumCounters)) dut (
    .aclk(aclk), .aresetn(aresetn),
    .aw_valid(aw_valid), .aw_addr(aw_addr), .aw_ready(aw_ready),
    .w_valid(w_valid), .w_data(w_data), .w_strb(w_strb), .w_ready(w_ready),
    .b_valid(b_valid), .b_resp(b_resp), .b_ready(b_ready),
    .ar_valid(ar_valid), .ar_addr(ar_addr), .ar_ready(ar_ready),
    .r_valid(r_valid), .r_data(r_data), .r_resp(r_resp), .r_ready(r_ready),
    .state_i(state_i), .error_cause_i(error_cause_i), .error_valid_i(error_valid_i),
    .model_gen_i(model_gen_i), .stream_epoch_i(stream_epoch_i),
    .counters_i(counters_i)
  );

  integer tb_errors;

  import mgr1_csr::*;

  function automatic logic [63:0] cb_val(input int unsigned i);
    return (64'h1000_0000_0000 + 64'(i) * 64'h1_0101_0101_0101);
  endfunction

  // AXI4-Lite write (decoupled AW/W; order selectable).
  task automatic axi_write(input logic [31:0] addr, input logic [31:0] data,
                           input logic [3:0] strb = 4'b1111,
                           input int order = 0);  // 0 AW first, 1 W first, 2 same edge
    if (order == 0) begin
      aw_valid = 1'b1; aw_addr = addr;
      @(posedge aclk);
      while (!aw_ready) @(posedge aclk);
      aw_valid = 1'b0;
      // A gap between the channels is legal and must be tolerated.
      repeat (2) @(posedge aclk);
      w_valid = 1'b1; w_data = data; w_strb = strb;
      @(posedge aclk);
      while (!w_ready) @(posedge aclk);
      w_valid = 1'b0;
    end else if (order == 1) begin
      w_valid = 1'b1; w_data = data; w_strb = strb;
      @(posedge aclk);
      while (!w_ready) @(posedge aclk);
      w_valid = 1'b0;
      repeat (2) @(posedge aclk);
      aw_valid = 1'b1; aw_addr = addr;
      @(posedge aclk);
      while (!aw_ready) @(posedge aclk);
      aw_valid = 1'b0;
    end else begin
      aw_valid = 1'b1; aw_addr = addr;
      w_valid = 1'b1; w_data = data; w_strb = strb;
      @(posedge aclk);
      while (!(aw_ready && w_ready)) begin
        if (!aw_ready && aw_valid) @(posedge aclk);
        else if (aw_ready && !w_ready) @(posedge aclk);
        else @(posedge aclk);
      end
      aw_valid = 1'b0;
      w_valid = 1'b0;
    end
    // B response.
    b_ready = 1'b1;
    @(posedge aclk);
    while (!b_valid) @(posedge aclk);
    // Read response payload sampled at the handshake edge; a single extra
    // cycle of latency is legal while b_valid holds.
    while (!(b_valid && b_ready)) @(posedge aclk);
    if (b_resp !== 2'b00) begin
      $display("FAIL: BRESP=%0b for write to %0h", b_resp, addr);
      tb_errors = tb_errors + 1;
    end
    @(negedge aclk);
    b_ready = 1'b0;
    @(negedge aclk);
  endtask

  task automatic axi_read(input logic [31:0] addr, input logic [31:0] expect_data,
                          input string tag);
    ar_valid = 1'b1;
    ar_addr = addr;
    @(posedge aclk);
    while (!ar_ready) @(posedge aclk);
    ar_valid = 1'b0;
    r_ready = 1'b1;
    while (!(r_valid && r_ready)) @(posedge aclk);
    if (r_data !== expect_data) begin
      $display("FAIL: read %0s (0x%0h): got 0x%08h expected 0x%08h",
               tag, addr, r_data, expect_data);
      tb_errors = tb_errors + 1;
    end
    if (r_resp !== 2'b00) begin
      $display("FAIL: RRESP=%0b on %0s", r_resp, tag);
      tb_errors = tb_errors + 1;
    end
    @(posedge aclk);
    r_ready = 1'b0;
    @(negedge aclk);
  endtask

  // BVALID must hold while no b_ready.
  task automatic axi_write_hold_bvalid(input logic [31:0] addr,
                                       input logic [31:0] data);
    aw_valid = 1'b1; aw_addr = addr;
    w_valid = 1'b1; w_data = data; w_strb = 4'b1111;
    b_ready = 1'b0;
    @(posedge aclk);
    while (!(aw_ready && w_ready)) @(posedge aclk);
    aw_valid = 1'b0;
    w_valid = 1'b0;
    // BVALID must rise and hold through several non-ready cycles.
    repeat (4) @(posedge aclk);
    if (b_valid !== 1'b1) begin
      $display("FAIL: BVALID not held (addr %0h)", addr);
      tb_errors = tb_errors + 1;
    end
    b_ready = 1'b1;
    @(posedge aclk);
    while (!b_valid) @(posedge aclk);   // still visible this cycle
    while (!(b_valid && b_ready)) @(posedge aclk);
    b_ready = 1'b0;
    @(posedge aclk);
  endtask

  initial begin
    tb_errors = 0;
    state_i = 3'd0;
    error_cause_i = 32'd0;
    error_valid_i = 1'b0;
    model_gen_i = 32'd5;
    stream_epoch_i = 32'd2;
    for (int i = 0; i < NumCounters; i++) counters_i[i] = cb_val(i);
    b_ready = 1'b0;
    r_ready = 1'b0;
    aw_valid = 1'b0; w_valid = 1'b0; ar_valid = 1'b0;

    repeat (4) @(posedge aclk);
    aresetn = 1'b1;
    repeat (4) @(posedge aclk);

    // ---- Defaults and RO registers -------------------------------------
    axi_read(OFF_ID,     32'h0001_4D47, "ID");
    axi_read(OFF_ABI,    32'h0000_0001, "ABI");
    axi_read(OFF_CAPS,   32'h0000_000F, "CAPS");
    axi_read(OFF_LIMITS, 32'h0000_0000, "LIMITS");
    axi_read(OFF_STATUS, 32'h0000_0000, "STATUS.idle");
    axi_read(OFF_ERROR,  32'h0000_0000, "ERROR.clear");

    // ---- Writes to RO state are ignored (rule 2) ------------------------
    axi_write(OFF_STATUS, 32'h0000_0005);
    axi_write(OFF_ERROR,  32'h0000_0055);
    axi_write(OFF_ID,     32'hFFFF_FFFF);
    axi_write(OFF_MODEL_GEN, 32'h0000_0007);
    axi_read(OFF_STATUS, 32'h0000_0000, "STATUS.after-RO-write");
    axi_read(OFF_ERROR,  32'h0000_0000, "ERROR.after-RO-write");

    // ---- RW shadows + WSTRB honoring (rules 1) --------------------------
    axi_write(OFF_DESC_LO, 32'hA5A5_5A5A);
    axi_write(OFF_DESC_HI, 32'h5A5A_A5A5);
    axi_write(OFF_DESC_LEN, 32'd4096);
    axi_write(OFF_ARG,     32'd33);
    axi_read(OFF_DESC_LO,  32'hA5A5_5A5A, "DESC_LO");
    axi_read(OFF_DESC_HI,  32'h5A5A_A5A5, "DESC_HI");
    axi_read(OFF_DESC_LEN, 32'd4096, "DESC_LEN");
    axi_read(OFF_ARG,      32'd33, "ARG");
    // Partial strobe: only bytes 0..1 commit (bytes 2..3 keep their old 0).
    axi_write(OFF_ARG, 32'h1234_0000, 4'b0011);
    axi_read(OFF_ARG, 32'h0000_0000, "ARG.partial");
    // W-first decoupled ordering (rule 3).
    axi_write(OFF_DESC_LEN, 32'd8192, 4'b1111, 1);
    axi_read(OFF_DESC_LEN, 32'd8192, "DESC_LEN.w-first");
    // Same-edge AW and W.
    axi_write(OFF_DESC_HI, 32'h7777_8888, 4'b1111, 2);
    axi_read(OFF_DESC_HI, 32'h7777_8888, "DESC_HI.same-edge");

    // ---- BVALID held until handshake (rule 4) ---------------------------
    axi_write_hold_bvalid(OFF_ARG, 32'd99);
    axi_read(OFF_ARG, 32'd99, "ARG.after-hold");

    // ---- Commands (rule 6) ----------------------------------------------
    axi_write(OFF_COMMAND, 32'd1);  // LOAD: IDLE -> LOADING
    axi_read(OFF_STATUS, 32'h0000_0001, "STATUS.loading");
    axi_write(OFF_COMMAND, 32'd2);  // COMMIT: LOADING -> READY
    axi_read(OFF_STATUS, 32'h0000_0002, "STATUS.ready");
    // Post-commit visibility: the datapath owns these views in READY.
    axi_read(OFF_MODEL_GEN, 32'd5, "MODEL_GEN.post-commit");
    axi_read(OFF_STREAM_EPOCH, 32'd2, "STREAM_EPOCH.post-commit");
    // Illegal: COMMIT in READY must do nothing (no transition).
    axi_write(OFF_COMMAND, 32'd2);
    axi_read(OFF_STATUS, 32'h0000_0002, "STATUS.still-ready");
    // Partial strobes do not execute the command (rule 1).
    axi_write(OFF_COMMAND, 32'd1, 4'b0011);
    axi_read(OFF_STATUS, 32'h0000_0002, "STATUS.partial-strobe-cmd");
    // LOAD again from READY.
    axi_write(OFF_COMMAND, 32'd1);
    axi_read(OFF_STATUS, 32'h0000_0001, "STATUS.loading-again");

    // ---- Snapshot (SNAP_SEQ + counter pairs) ------------------------------
    axi_write(OFF_COMMAND, 32'd4);
    axi_read(OFF_SNAP_SEQ, 32'd1, "SNAP_SEQ.after-1");
    for (int i = 0; i < NumCounters; i++) begin
      axi_read(32'h40 + i*8,     cb_val(i)[31:0], "CNT.lo");
      axi_read(32'h40 + i*8 + 4, cb_val(i)[63:32], "CNT.hi");
    end
    axi_write(OFF_COMMAND, 32'd4);
    axi_read(OFF_SNAP_SEQ, 32'd2, "SNAP_SEQ.after-2");

    // ---- Unmapped read returns zero (rule 8) ------------------------------
    axi_read(32'h0000_0090, 32'h0000_0000, "unmapped");

    // ---- IRQ W1C with no sources stays 0 (rule 7) -------------------------
    axi_write(OFF_IRQ_STATUS, 32'hFFFF_FFFF);
    axi_read(OFF_IRQ_STATUS, 32'h0000_0000, "IRQ_STATUS.w1c-nosrc");
    axi_write(OFF_IRQ_MASK, 32'h0000_00AB);
    axi_read(OFF_IRQ_MASK, 32'h0000_00AB, "IRQ_MASK");

    // ---- Sticky error: first retained; clear; same-cycle new fault (rule 5)
    // Fault A.
    @(negedge aclk);
    error_cause_i = 32'd55;
    error_valid_i = 1'b1;
    @(posedge aclk);
    error_valid_i = 1'b0;
    @(negedge aclk);
    axi_read(OFF_ERROR, 32'd55, "ERROR.first");
    axi_read(OFF_STATUS, 32'h0000_0004, "STATUS.fault");
    // Fault B must not overwrite the first.
    @(negedge aclk);
    error_cause_i = 32'd66;
    error_valid_i = 1'b1;
    @(posedge aclk);
    error_valid_i = 1'b0;
    @(negedge aclk);
    axi_read(OFF_ERROR, 32'd55, "ERROR.retained-first");
    // CLEAR_FAULT without a new fault clears it.
    axi_write(OFF_COMMAND, 32'd5);
    axi_read(OFF_ERROR, 32'h0000_0000, "ERROR.cleared");
    // CLEAR_FAULT in the same cycle as a new fault preserves the new event.
    @(negedge aclk);
    error_cause_i = 32'd77;
    error_valid_i = 1'b1;
    aw_valid = 1'b1; aw_addr = OFF_COMMAND;
    w_valid = 1'b1; w_data = 32'd5; w_strb = 4'b1111;
    @(posedge aclk);
    error_valid_i = 1'b0;
    aw_valid = 1'b0;
    w_valid = 1'b0;
    @(negedge aclk);
    axi_read(OFF_ERROR, 32'd77, "ERROR.clear+new.fault-preserved");

    @(posedge aclk);
    if (tb_errors == 0) begin
      $display("TB PASS: csr_block: map, WSTRB, RO-ignore, decoupled AW/W, BVALID hold, commands, snapshot, sticky first-fault + same-cycle rule");
    end else begin
      $fatal(1, "TB FAILED with %0d error(s)", tb_errors);
    end
    $finish;
  end

endmodule
