`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_base_seq extends uvm_sequence #(apb_item);

  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) begin
      phase.raise_objection(this, "Starting sequence");
    end
  endtask

  virtual task post_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) begin
      phase.drop_objection(this, "Ending sequence");
    end
  endtask

endclass

class apb_reg_seq extends apb_base_seq;

  `uvm_object_utils(apb_reg_seq)

  function new(string name = "apb_reg_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_item req;

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h00;
    req.pwrite = 1'b1;
    req.data   = 32'h0000_0001;
    finish_item(req);

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h00;
    req.pwrite = 1'b0;
    finish_item(req);

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h18;
    req.pwrite = 1'b1;
    req.data   = 32'h0000_000A;
    finish_item(req);

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h18;
    req.pwrite = 1'b0;
    finish_item(req);
  endtask

endclass

class apb_fifo_seq extends apb_base_seq;

  `uvm_object_utils(apb_fifo_seq)

  function new(string name = "apb_fifo_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_item req;

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h00;
    req.pwrite = 1'b1;
    req.data   = 32'h0000_0001;
    finish_item(req);

    for (int i = 0; i < 16; i++) begin
      req = apb_item::type_id::create("req");
      start_item(req);
      req.addr   = 32'h08;
      req.pwrite = 1'b1;
      req.data   = 32'hA000_0000 + i;
      finish_item(req);
    end

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h0C;
    req.pwrite = 1'b0;
    finish_item(req);

    for (int i = 0; i < 16; i++) begin
      req = apb_item::type_id::create("req");
      start_item(req);
      req.addr   = 32'h08;
      req.pwrite = 1'b0;
      finish_item(req);
    end
  endtask

endclass

class apb_error_seq extends apb_base_seq;

  `uvm_object_utils(apb_error_seq)

  function new(string name = "apb_error_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_item req;

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h07;
    req.pwrite = 1'b1;
    req.data   = 32'hBAD0_0001;
    finish_item(req);

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h80;
    req.pwrite = 1'b0;
    finish_item(req);
  endtask

endclass

class apb_rand_seq extends apb_base_seq;

  `uvm_object_utils(apb_rand_seq)

  function new(string name = "apb_rand_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_item req;

    req = apb_item::type_id::create("req");
    start_item(req);
    req.addr   = 32'h00;
    req.pwrite = 1'b1;
    req.data   = 32'h0000_0001;
    finish_item(req);

    repeat (50) begin
      req = apb_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) begin
        `uvm_fatal("RAND_FAIL", "Transaction randomization failed")
      end
      finish_item(req);
    end
  endtask

endclass
