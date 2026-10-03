`timescale 1ns/1ps

module tb_regression;

  logic clk;
  logic resetn;

  always #5 clk = ~clk;

  apb_if vif (.pclk(clk), .presetn(resetn));

  apb_peripheral #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .FIFO_DEPTH(16)
  ) dut (
    .pclk    (vif.pclk),
    .presetn (vif.presetn),
    .paddr   (vif.paddr),
    .psel    (vif.psel),
    .penable (vif.penable),
    .pwrite  (vif.pwrite),
    .pwdata  (vif.pwdata),
    .prdata  (vif.prdata),
    .pready  (vif.pready),
    .pslverr (vif.pslverr),
    .irq     (vif.irq)
  );

  task apb_write(input [31:0] addr, input [31:0] data, output logic err);
    @(posedge clk);
    vif.paddr   <= addr;
    vif.pwdata  <= data;
    vif.pwrite  <= 1'b1;
    vif.psel    <= 1'b1;
    vif.penable <= 1'b0;

    @(posedge clk);
    vif.penable <= 1'b1;

    @(posedge clk);
    while (!vif.pready) @(posedge clk);
    err = vif.pslverr;
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.pwrite  <= 1'b0;
  endtask

  task apb_read(input [31:0] addr, output [31:0] data, output logic err);
    @(posedge clk);
    vif.paddr   <= addr;
    vif.pwrite  <= 1'b0;
    vif.psel    <= 1'b1;
    vif.penable <= 1'b0;

    @(posedge clk);
    vif.penable <= 1'b1;

    @(posedge clk);
    while (!vif.pready) @(posedge clk);
    data = vif.prdata;
    err  = vif.pslverr;
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
  endtask

  task do_reset();
    vif.psel    = 0;
    vif.penable = 0;
    vif.pwrite  = 0;
    vif.paddr   = 0;
    vif.pwdata  = 0;
    resetn      = 0;
    #25;
    resetn      = 1;
    @(posedge clk);
  endtask

  initial begin
    string test_name;
    int    seed;
    logic [31:0] rdata;
    logic        err;
    bit          test_failed = 0;

    clk = 0;

    if (!$value$plusargs("TESTNAME=%s", test_name)) begin
      test_name = "test_reset";
    end

    if (!$value$plusargs("SEED=%d", seed)) begin
      seed = 1;
    end

    $display("[REGRESSION HARNESS] Running TESTNAME=%s with SEED=%0d", test_name, seed);
    do_reset();

    if (test_name == "test_reset") begin
      apb_read(32'h04, rdata, err);
      if (rdata[0] !== 1'b1 || err !== 1'b0) test_failed = 1;
      apb_read(32'h0C, rdata, err);
      if (rdata[4:0] !== 5'd0 || err !== 1'b0) test_failed = 1;
      apb_read(32'h18, rdata, err);
      if (rdata[4:0] !== 5'd8 || err !== 1'b0) test_failed = 1;
    end

    else if (test_name == "test_register_write") begin
      apb_write(32'h00, 32'h0000_0005, err);
      apb_read(32'h00, rdata, err);
      if (rdata[2:0] !== 3'b101 || err !== 1'b0) test_failed = 1;

      apb_write(32'h18, 32'h0000_000C, err);
      apb_read(32'h18, rdata, err);
      if (rdata[4:0] !== 5'd12 || err !== 1'b0) test_failed = 1;

      apb_write(32'h10, 32'h0000_000F, err);
      apb_read(32'h10, rdata, err);
      if (rdata[3:0] !== 4'b1111 || err !== 1'b0) test_failed = 1;
    end

    else if (test_name == "test_register_read") begin
      apb_read(32'h04, rdata, err);
      if (rdata[0] !== 1'b1 || err !== 1'b0) test_failed = 1;

      apb_write(32'h04, 32'hFFFF_FFFF, err);
      apb_read(32'h04, rdata, err);
      if (rdata[0] !== 1'b1 || err !== 1'b0) test_failed = 1;
    end

    else if (test_name == "test_fifo_basic") begin
      apb_write(32'h00, 32'h0000_0001, err);
      apb_write(32'h08, 32'h1122_3344, err);
      if (err !== 1'b0) test_failed = 1;
      apb_read(32'h08, rdata, err);
      if (rdata !== 32'h1122_3344 || err !== 1'b0) test_failed = 1;
    end

    else if (test_name == "test_fifo_full") begin
      apb_write(32'h00, 32'h0000_0001, err);
      for (int i = 0; i < 16; i++) begin
        apb_write(32'h08, 32'h1000 + i, err);
        if (err !== 1'b0) test_failed = 1;
      end
      apb_read(32'h0C, rdata, err);
      if (rdata[4:0] !== 5'd16) test_failed = 1;
      apb_read(32'h04, rdata, err);
      if (rdata[1] !== 1'b1) test_failed = 1;
    end

    else if (test_name == "test_fifo_empty") begin
      apb_write(32'h00, 32'h0000_0001, err);
      apb_write(32'h08, 32'hA5A5_A5A5, err);
      apb_read(32'h08, rdata, err);
      apb_read(32'h0C, rdata, err);
      if (rdata[4:0] !== 5'd0) test_failed = 1;
      apb_read(32'h04, rdata, err);
      if (rdata[0] !== 1'b1) test_failed = 1;
    end

    else if (test_name == "test_fifo_overflow") begin
      apb_write(32'h00, 32'h0000_0001, err);
      for (int i = 0; i < 16; i++) begin
        apb_write(32'h08, 32'h2000 + i, err);
      end
      apb_write(32'h08, 32'hDEAD_BEEF, err);
      if (err !== 1'b1) test_failed = 1;
      apb_read(32'h1C, rdata, err);
      if (rdata[0] !== 1'b1) test_failed = 1;
    end

    else if (test_name == "test_fifo_underflow") begin
      apb_write(32'h00, 32'h0000_0001, err);
      apb_read(32'h08, rdata, err);
      if (err !== 1'b1) test_failed = 1;
      apb_read(32'h1C, rdata, err);
      if (rdata[1] !== 1'b1) test_failed = 1;
    end

    else if (test_name == "test_irq") begin
      apb_write(32'h00, 32'h0000_0005, err);
      apb_write(32'h18, 32'h0000_0002, err);
      apb_write(32'h10, 32'h0000_0004, err);

      apb_write(32'h08, 32'h1111_1111, err);
      apb_write(32'h08, 32'h2222_2222, err);
      @(posedge clk);
      #1;
      if (vif.irq !== 1'b1) test_failed = 1;

      apb_read(32'h08, rdata, err);
      apb_write(32'h14, 32'h0000_0004, err);
      @(posedge clk);
      #1;
      if (vif.irq !== 1'b0) test_failed = 1;
    end

    else if (test_name == "test_unaligned_access") begin
      apb_write(32'h01, 32'h1234_5678, err);
      if (err !== 1'b1) test_failed = 1;
      apb_write(32'h02, 32'h1234_5678, err);
      if (err !== 1'b1) test_failed = 1;
      apb_write(32'h03, 32'h1234_5678, err);
      if (err !== 1'b1) test_failed = 1;
      apb_read(32'h05, rdata, err);
      if (err !== 1'b1) test_failed = 1;
      apb_read(32'h07, rdata, err);
      if (err !== 1'b1) test_failed = 1;
    end

    else begin
      $display("[REGRESSION HARNESS ERROR] Unknown TESTNAME: %s", test_name);
      test_failed = 1;
    end

    if (test_failed) begin
      $display("[REGRESSION STATUS] TESTNAME=%s : FAILED", test_name);
    end else begin
      $display("[REGRESSION STATUS] TESTNAME=%s : PASSED", test_name);
    end

    #20;
    $finish;
  end

endmodule
