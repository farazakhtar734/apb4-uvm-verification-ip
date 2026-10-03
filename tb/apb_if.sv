// ============================================================================
// Module: apb_if
// Description: APB4 Bus SystemVerilog Interface (Tool-Portable)
// ============================================================================

interface apb_if (input logic pclk, input logic presetn);

  // 1. Bus Signals
  logic [31:0] paddr;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;
  
  // Sideband interrupt signal
  logic        irq;

  // 2. Clocking Blocks (IEEE 1800 Standard)
  // Guarded with `ifndef so open-source tools compile cleanly
`ifndef __ICARUS__
  clocking drv_cb @(posedge pclk);
    default input #1step output #1ns;
    output paddr, psel, penable, pwrite, pwdata;
    input  prdata, pready, pslverr;
  endclocking

  clocking mon_cb @(posedge pclk);
    default input #1step;
    input paddr, psel, penable, pwrite, pwdata;
    input prdata, pready, pslverr, irq;
  endclocking
`endif

  // 3. Modports
  // DUT perspective: slave receiver
  modport dut (
    input  pclk,
    input  presetn,
    input  paddr,
    input  psel,
    input  penable,
    input  pwrite,
    input  pwdata,
    output prdata,
    output pready,
    output pslverr,
    output irq
  );

  // Testbench Driver perspective: master stimulus generator
  modport drv (
    input  pclk,
    input  presetn,
    input  prdata,
    input  pready,
    input  pslverr,
    output paddr,
    output psel,
    output penable,
    output pwrite,
    output pwdata
  );

  // Testbench Monitor perspective: passive bus observer
  modport mon (
    input pclk,
    input presetn,
    input paddr,
    input psel,
    input penable,
    input pwrite,
    input pwdata,
    input prdata,
    input pready,
    input pslverr,
    input irq
  );

endinterface
