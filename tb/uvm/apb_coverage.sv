`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_coverage extends uvm_subscriber #(apb_item);

  `uvm_component_utils(apb_coverage)

  apb_item tr_sample;

  covergroup apb_cov_grp;
    cp_addr: coverpoint tr_sample.addr[7:0] {
      bins ctrl         = {8'h00};
      bins status       = {8'h04};
      bins fifo_data    = {8'h08};
      bins fifo_level   = {8'h0C};
      bins irq_enable   = {8'h10};
      bins irq_status   = {8'h14};
      bins config_reg   = {8'h18};
      bins error_status = {8'h1C};
      bins illegal_addr = {[8'h20:8'hFF]};
    }

    cp_rw: coverpoint tr_sample.pwrite {
      bins read_op  = {1'b0};
      bins write_op = {1'b1};
    }

    cp_err: coverpoint tr_sample.pslverr {
      bins ok    = {1'b0};
      bins error = {1'b1};
    }

    cross_addr_rw: cross cp_addr, cp_rw;
  endgroup

  function new(string name = "apb_coverage", uvm_component parent = null);
    super.new(name, parent);
    apb_cov_grp = new();
  endfunction

  virtual function void write(apb_item t);
    tr_sample = t;
    apb_cov_grp.sample();
  endfunction

endclass
