`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_item extends uvm_sequence_item;

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        pwrite;

  bit [31:0]      prdata;
  bit             pslverr;

  constraint c_aligned {
    addr[1:0] == 2'b00;
  }

  constraint c_addr_range {
    addr[7:0] <= 8'h1C;
    addr[31:8] == 24'h0;
  }

  constraint c_rw_dist {
    pwrite dist { 1 := 50, 0 := 50 };
  }

  `uvm_object_utils_begin(apb_item)
    `uvm_field_int(addr,    UVM_ALL_ON)
    `uvm_field_int(data,    UVM_ALL_ON)
    `uvm_field_int(pwrite,  UVM_ALL_ON)
    `uvm_field_int(prdata,  UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("pwrite=%b addr=0x%08h wdata=0x%08h prdata=0x%08h pslverr=%b",
                     pwrite, addr, data, prdata, pslverr);
  endfunction

endclass
