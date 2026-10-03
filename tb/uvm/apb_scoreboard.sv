`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.sv"

class apb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(apb_scoreboard)

  uvm_analysis_imp #(apb_item, apb_scoreboard) item_export;

  bit [31:0] reg_model [bit [7:0]];
  bit [31:0] fifo_model [$];

  int unsigned matches;
  int unsigned mismatches;

  function new(string name = "apb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
    matches    = 0;
    mismatches = 0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reg_model[8'h00] = 32'h0;
    reg_model[8'h04] = 32'h1;
    reg_model[8'h0C] = 32'h0;
    reg_model[8'h10] = 32'h0;
    reg_model[8'h14] = 32'h0;
    reg_model[8'h18] = 32'd8;
    reg_model[8'h1C] = 32'h0;
  endfunction

  virtual function void write(apb_item tr);
    bit [7:0]  addr;
    bit        expected_err;
    bit [31:0] expected_data;

    addr = tr.addr[7:0];
    expected_err = 1'b0;

    if (tr.addr[1:0] != 2'b00 || tr.addr[7:0] > 8'h1C) begin
      expected_err = 1'b1;
    end

    if (tr.pwrite) begin
      if (addr == 8'h08) begin
        if (!reg_model[8'h00][0]) begin
          expected_err = 1'b1;
        end else if (fifo_model.size() >= 16) begin
          expected_err = 1'b1;
          reg_model[8'h1C][0] = 1'b1;
        end else begin
          fifo_model.push_back(tr.data);
        end
      end else if (!expected_err) begin
        case (addr)
          8'h00: begin
            reg_model[8'h00] = tr.data;
            if (tr.data[1]) begin
              fifo_model.delete();
              reg_model[8'h00][1] = 1'b0;
            end
          end
          8'h10: reg_model[8'h10] = tr.data[3:0];
          8'h14: reg_model[8'h14] = reg_model[8'h14] & ~tr.data[3:0];
          8'h18: reg_model[8'h18] = tr.data[4:0];
          8'h1C: reg_model[8'h1C] = reg_model[8'h1C] & ~tr.data[2:0];
          default: ;
        endcase
      end

      if (tr.pslverr !== expected_err) begin
        `uvm_error("SCB_WRITE_ERR", $sformatf("PSLVERR mismatch at addr 0x%02h: Exp=%b Got=%b",
                                              addr, expected_err, tr.pslverr))
        mismatches++;
      end else begin
        matches++;
      end
    end else begin
      if (addr == 8'h08) begin
        if (!reg_model[8'h00][0]) begin
          expected_err = 1'b1;
        end else if (fifo_model.size() == 0) begin
          expected_err = 1'b1;
          reg_model[8'h1C][1] = 1'b1;
        end else begin
          expected_data = fifo_model.pop_front();
        end
      end else if (addr == 8'h0C) begin
        expected_data = fifo_model.size();
      end else if (addr == 8'h04) begin
        expected_data = {
          28'h0,
          (|reg_model[8'h1C]),
          (fifo_model.size() >= reg_model[8'h18]),
          (fifo_model.size() == 16),
          (fifo_model.size() == 0)
        };
      end else if (reg_model.exists(addr)) begin
        expected_data = reg_model[addr];
      end else begin
        expected_data = 32'hDEAD_BEEF;
      end

      if (tr.pslverr !== expected_err) begin
        `uvm_error("SCB_READ_ERR", $sformatf("PSLVERR mismatch at addr 0x%02h: Exp=%b Got=%b",
                                             addr, expected_err, tr.pslverr))
        mismatches++;
      end else if (!expected_err && addr == 8'h08 && tr.prdata !== expected_data) begin
        `uvm_error("SCB_DATA_MISMATCH", $sformatf("FIFO Data mismatch! Exp=0x%08h Got=0x%08h",
                                                  expected_data, tr.prdata))
        mismatches++;
      end else begin
        matches++;
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_REPORT", "=================================================", UVM_LOW)
    `uvm_info("SCB_REPORT", $sformatf("SCOREBOARD RESULTS: Matches=%0d Mismatches=%0d", matches, mismatches), UVM_LOW)
    if (mismatches == 0 && matches > 0) begin
      `uvm_info("SCB_REPORT", ">>> TEST PASSED: ALL TRANSACTIONS MATCHED REFERENCE MODEL <<<", UVM_LOW)
    end else if (mismatches > 0) begin
      `uvm_fatal("SCB_REPORT", ">>> TEST FAILED: MISMATCHES DETECTED IN SCOREBOARD <<<")
    end
    `uvm_info("SCB_REPORT", "=================================================", UVM_LOW)
  endfunction

endclass
