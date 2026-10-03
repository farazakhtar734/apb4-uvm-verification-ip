`timescale 1ns/1ps

module tb_apb_sanity;

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

  initial begin
    logic [31:0] rdata;
    logic        err;

    $dumpfile("sim/tb_apb_sanity.vcd");
    $dumpvars(0, tb_apb_sanity);

    clk         = 0;
    resetn      = 0;
    vif.paddr   = 0;
    vif.pwdata  = 0;
    vif.pwrite  = 0;
    vif.psel    = 0;
    vif.penable = 0;

    #20;
    resetn = 1;
    @(posedge clk);
    $display("[TB] Reset complete. Starting tests...");

    apb_read(32'h04, rdata, err);
    if (rdata[0] !== 1'b1 || err !== 1'b0) begin
      $display("[TB ERROR] STATUS check failed! rdata=%h err=%b", rdata, err);
      $finish;
    end
    $display("[TB PASS] STATUS register reset value verified (FIFO Empty).");

    apb_write(32'h00, 32'h0000_0001, err);
    apb_read(32'h00, rdata, err);
    if (rdata[0] !== 1'b1 || err !== 1'b0) begin
      $display("[TB ERROR] CTRL register write/read failed! rdata=%h", rdata);
      $finish;
    end
    $display("[TB PASS] CTRL register enabled.");

    apb_write(32'h08, 32'hDEAD_BEEF, err);
    apb_write(32'h08, 32'hCAFE_BABE, err);
    $display("[TB PASS] Pushed 2 words into FIFO.");

    apb_read(32'h0C, rdata, err);
    if (rdata[4:0] !== 5'd2) begin
      $display("[TB ERROR] FIFO level mismatch! Expected 2, got %0d", rdata[4:0]);
      $finish;
    end
    $display("[TB PASS] FIFO_LEVEL verified: 2 entries.");

    apb_read(32'h08, rdata, err);
    if (rdata !== 32'hDEAD_BEEF) begin
      $display("[TB ERROR] FIFO data mismatch on word 1! Got %h", rdata);
      $finish;
    end

    apb_read(32'h08, rdata, err);
    if (rdata !== 32'hCAFE_BABE) begin
      $display("[TB ERROR] FIFO data mismatch on word 2! Got %h", rdata);
      $finish;
    end
    $display("[TB PASS] Popped and matched both FIFO words (FIFO Ordering Verified).");

    apb_write(32'h07, 32'h1234_5678, err);
    if (err !== 1'b1) begin
      $display("[TB ERROR] PSLVERR not asserted on unaligned address 0x07!");
      $finish;
    end
    $display("[TB PASS] PSLVERR correctly detected unaligned address 0x07.");

    $display("=================================================");
    $display(">>> ALL SANITY CHECKS PASSED SUCCESSFULLY! <<<");
    $display("=================================================");
    #40;
    $finish;
  end

endmodule
