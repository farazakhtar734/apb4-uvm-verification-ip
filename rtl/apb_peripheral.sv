`timescale 1ns/1ps

module apb_peripheral #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int FIFO_DEPTH = 16
)(
  input  logic                  pclk,
  input  logic                  presetn,
  input  logic [ADDR_WIDTH-1:0] paddr,
  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [DATA_WIDTH-1:0] pwdata,
  output logic [DATA_WIDTH-1:0] prdata,
  output logic                  pready,
  output logic                  pslverr,
  output logic                  irq
);

  localparam logic [7:0] ADDR_CTRL         = 8'h00;
  localparam logic [7:0] ADDR_STATUS       = 8'h04;
  localparam logic [7:0] ADDR_FIFO_DATA    = 8'h08;
  localparam logic [7:0] ADDR_FIFO_LEVEL   = 8'h0C;
  localparam logic [7:0] ADDR_IRQ_ENABLE   = 8'h10;
  localparam logic [7:0] ADDR_IRQ_STATUS   = 8'h14;
  localparam logic [7:0] ADDR_CONFIG       = 8'h18;
  localparam logic [7:0] ADDR_ERROR_STATUS = 8'h1C;

  logic [2:0]  reg_ctrl;
  logic [3:0]  reg_irq_enable;
  logic [3:0]  reg_irq_status;
  logic [4:0]  reg_config;
  logic [2:0]  reg_error_status;

  logic [7:0]  reg_addr;
  logic [1:0]  addr_align;
  logic        ctrl_en;
  logic        ctrl_fifo_clr;
  logic        ctrl_irq_en;

  logic        fifo_clear;
  logic        fifo_push;
  logic        fifo_pop;
  logic [31:0] fifo_rdata;
  logic        fifo_empty;
  logic        fifo_full;
  logic [$clog2(FIFO_DEPTH):0] fifo_level;
  logic        fifo_overflow;
  logic        fifo_underflow;

  logic [31:0] reg_status;
  logic        addr_valid;
  logic        transfer_active;
  logic        illegal_access;

  assign reg_addr      = paddr[7:0];
  assign addr_align    = paddr[1:0];
  assign ctrl_en       = reg_ctrl[0];
  assign ctrl_fifo_clr = reg_ctrl[1];
  assign ctrl_irq_en   = reg_ctrl[2];

  fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) u_fifo (
    .clk      (pclk),
    .resetn   (presetn),
    .clear    (fifo_clear),
    .push     (fifo_push),
    .pop      (fifo_pop),
    .wdata    (pwdata),
    .rdata    (fifo_rdata),
    .empty    (fifo_empty),
    .full     (fifo_full),
    .level    (fifo_level),
    .overflow (fifo_overflow),
    .underflow(fifo_underflow)
  );

  assign transfer_active = psel && penable;
  assign pready          = 1'b1;

  assign addr_valid = (addr_align == 2'b00) && (reg_addr <= ADDR_ERROR_STATUS);

  assign fifo_clear = ctrl_fifo_clr;

  assign fifo_push = transfer_active && pwrite && (reg_addr == ADDR_FIFO_DATA) && ctrl_en;
  assign fifo_pop  = transfer_active && !pwrite && (reg_addr == ADDR_FIFO_DATA) && ctrl_en;

  assign reg_status = {
    28'h0,
    (|reg_error_status),
    (fifo_level >= reg_config),
    fifo_full,
    fifo_empty
  };

  always @(*) begin
    illegal_access = 1'b0;
    if (transfer_active) begin
      if (!addr_valid) begin
        illegal_access = 1'b1;
      end else if (reg_addr == ADDR_FIFO_DATA) begin
        if (!ctrl_en) begin
          illegal_access = 1'b1;
        end else if (pwrite && fifo_full) begin
          illegal_access = 1'b1;
        end else if (!pwrite && fifo_empty) begin
          illegal_access = 1'b1;
        end
      end
    end
  end

  assign pslverr = illegal_access;

  always @(*) begin
    prdata = 32'h0;
    if (psel && !pwrite) begin
      case (reg_addr)
        ADDR_CTRL:         prdata = {29'h0, reg_ctrl};
        ADDR_STATUS:       prdata = reg_status;
        ADDR_FIFO_DATA:    prdata = fifo_rdata;
        ADDR_FIFO_LEVEL:   prdata = {26'h0, fifo_level};
        ADDR_IRQ_ENABLE:   prdata = {28'h0, reg_irq_enable};
        ADDR_IRQ_STATUS:   prdata = {28'h0, reg_irq_status};
        ADDR_CONFIG:       prdata = {27'h0, reg_config};
        ADDR_ERROR_STATUS: prdata = {29'h0, reg_error_status};
        default:           prdata = 32'hDEAD_BEEF;
      endcase
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      reg_ctrl         <= 3'h0;
      reg_irq_enable   <= 4'h0;
      reg_irq_status   <= 4'h0;
      reg_config       <= 5'd8;
      reg_error_status <= 3'h0;
    end else begin
      if (ctrl_fifo_clr) begin
        reg_ctrl[1] <= 1'b0;
      end

      if (fifo_overflow)  reg_error_status[0] <= 1'b1;
      if (fifo_underflow) reg_error_status[1] <= 1'b1;
      if (transfer_active && !addr_valid) reg_error_status[2] <= 1'b1;

      if (fifo_full)                             reg_irq_status[0] <= 1'b1;
      if (fifo_empty)                            reg_irq_status[1] <= 1'b1;
      if (fifo_level >= reg_config)              reg_irq_status[2] <= 1'b1;
      if (|reg_error_status || illegal_access)   reg_irq_status[3] <= 1'b1;

      if (transfer_active && pwrite && addr_valid) begin
        case (reg_addr)
          ADDR_CTRL:         reg_ctrl         <= pwdata[2:0];
          ADDR_IRQ_ENABLE:   reg_irq_enable   <= pwdata[3:0];
          ADDR_IRQ_STATUS:   reg_irq_status   <= reg_irq_status & ~pwdata[3:0];
          ADDR_CONFIG:       reg_config       <= pwdata[4:0];
          ADDR_ERROR_STATUS: reg_error_status <= reg_error_status & ~pwdata[2:0];
          default: ;
        endcase
      end
    end
  end

  assign irq = ctrl_irq_en & (|(reg_irq_status & reg_irq_enable));

endmodule
