`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"
import apb_pkg::*;

class apb_base_test extends uvm_test;

  `uvm_component_utils(apb_base_test)

  apb_env env;

  function new(string name = "apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass

class apb_reg_test extends apb_base_test;

  `uvm_component_utils(apb_reg_test)

  function new(string name = "apb_reg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_reg_seq seq;
    seq = apb_reg_seq::type_id::create("seq");
    seq.set_starting_phase(phase);
    seq.start(env.agent.sequencer);
  endtask

endclass

class apb_fifo_test extends apb_base_test;

  `uvm_component_utils(apb_fifo_test)

  function new(string name = "apb_fifo_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_fifo_seq seq;
    seq = apb_fifo_seq::type_id::create("seq");
    seq.set_starting_phase(phase);
    seq.start(env.agent.sequencer);
  endtask

endclass

class apb_error_test extends apb_base_test;

  `uvm_component_utils(apb_error_test)

  function new(string name = "apb_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_error_seq seq;
    seq = apb_error_seq::type_id::create("seq");
    seq.set_starting_phase(phase);
    seq.start(env.agent.sequencer);
  endtask

endclass

class apb_rand_test extends apb_base_test;

  `uvm_component_utils(apb_rand_test)

  function new(string name = "apb_rand_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_rand_seq seq;
    seq = apb_rand_seq::type_id::create("seq");
    seq.set_starting_phase(phase);
    seq.start(env.agent.sequencer);
  endtask

endclass
