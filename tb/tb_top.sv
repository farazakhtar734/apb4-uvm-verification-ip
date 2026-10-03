`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"
import apb_pkg::*;

module tb_top;

  logic pclk;
  logic presetn;

  always #5 pclk = ~pclk;

  apb_if vif (.pclk(pclk), .presetn(presetn));

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

  initial begin
    pclk    = 0;
    presetn = 0;
    #25;
    presetn = 1;
  end

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
    run_test();
  end

  initial begin
    $dumpfile("sim/uvm_sim.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
