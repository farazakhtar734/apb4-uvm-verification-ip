`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;
  uvm_analysis_port #(apb_item) ap;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON", "Failed to obtain virtual interface from uvm_config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_item tr;

    @(posedge vif.presetn);

    forever begin
      @(posedge vif.pclk);
      if (vif.psel && vif.penable && vif.pready) begin
        tr = apb_item::type_id::create("tr");
        tr.addr    = vif.paddr;
        tr.pwrite  = vif.pwrite;
        tr.data    = vif.pwdata;
        tr.prdata  = vif.prdata;
        tr.pslverr = vif.pslverr;
        ap.write(tr);
      end
    end
  endtask

endclass
