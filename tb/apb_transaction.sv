`timescale 1ns/1ps

class apb_transaction;

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        we;

  bit             err;
  bit [31:0]      rdata;

  constraint c_aligned {
    addr[1:0] == 2'b00;
  }

  constraint c_legal_addr {
    addr[7:0] <= 8'h1C;
    addr[31:8] == 24'h0;
  }

  constraint c_we_dist {
    we dist { 1 := 50, 0 := 50 };
  }

  function new(bit [31:0] addr = 0, bit [31:0] data = 0, bit we = 0);
    this.addr = addr;
    this.data = data;
    this.we   = we;
  endfunction

  function apb_transaction copy();
    apb_transaction tr;
    tr = new();
    tr.addr  = this.addr;
    tr.data  = this.data;
    tr.we    = this.we;
    tr.err   = this.err;
    tr.rdata = this.rdata;
    return tr;
  endfunction

  function void print(string tag = "TRANS");
    $display("[%s] we=%b addr=0x%08h wdata=0x%08h rdata=0x%08h err=%b",
             tag, we, addr, data, rdata, err);
  endfunction

endclass
