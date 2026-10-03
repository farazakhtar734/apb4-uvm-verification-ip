`timescale 1ns/1ps

module apb_assertions #(
  parameter int FIFO_DEPTH = 16
)(
  input logic        pclk,
  input logic        presetn,
  input logic [31:0] paddr,
  input logic        psel,
  input logic        penable,
  input logic        pwrite,
  input logic [31:0] pwdata,
  input logic        pready,
  input logic [4:0]  fifo_level
);

`ifndef __ICARUS__

  property p_penable_rise;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable) |=> penable;
  endproperty
  assert_penable_rise: assert property (p_penable_rise)
    else $error("[SVA ERROR] APB Protocol Violation: PENABLE did not assert cycle after PSEL!");

  property p_addr_stable_during_access;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pready) |=> $stable(paddr);
  endproperty
  assert_addr_stable: assert property (p_addr_stable_during_access)
    else $error("[SVA ERROR] APB Protocol Violation: PADDR changed during wait states!");

  property p_write_data_stable_during_access;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite && !pready) |=> $stable(pwdata);
  endproperty
  assert_data_stable: assert property (p_write_data_stable_during_access)
    else $error("[SVA ERROR] APB Protocol Violation: PWDATA changed during wait states!");

  property p_fifo_level_max;
    @(posedge pclk) disable iff (!presetn)
    (fifo_level <= FIFO_DEPTH);
  endproperty
  assert_fifo_level_max: assert property (p_fifo_level_max)
    else $error("[SVA ERROR] Hardware Invariant Violation: FIFO level exceeded FIFO_DEPTH!");

`endif

  always_ff @(posedge pclk) begin
    if (presetn) begin
      if (fifo_level > FIFO_DEPTH) begin
        $display("[ASSERTION ERROR] Immediate Check: FIFO level %0d > %0d", fifo_level, FIFO_DEPTH);
      end
    end
  end

endmodule
