`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_driver extends uvm_driver #(apb_item);

  `uvm_component_utils(apb_driver)

  virtual apb_if vif;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV", "Failed to obtain virtual interface from uvm_config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.pwrite  <= 1'b0;
    vif.paddr   <= 32'h0;
    vif.pwdata  <= 32'h0;

    @(posedge vif.presetn);

    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_transfer(apb_item tr);
    @(posedge vif.pclk);
    vif.paddr   <= tr.addr;
    vif.pwrite  <= tr.pwrite;
    vif.psel    <= 1'b1;
    vif.penable <= 1'b0;
    if (tr.pwrite) begin
      vif.pwdata <= tr.data;
    end

    @(posedge vif.pclk);
    vif.penable <= 1'b1;

    @(posedge vif.pclk);
    while (!vif.pready) @(posedge vif.pclk);

    if (!tr.pwrite) begin
      tr.prdata = vif.prdata;
    end
    tr.pslverr = vif.pslverr;

    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.pwrite  <= 1'b0;
  endtask

endclass
