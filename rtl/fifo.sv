`timescale 1ns/1ps

module fifo #(
  parameter int DATA_WIDTH = 32,
  parameter int FIFO_DEPTH = 16
)(
  input  logic                        clk,
  input  logic                        resetn,
  input  logic                        clear,
  input  logic                        push,
  input  logic                        pop,
  input  logic [DATA_WIDTH-1:0]       wdata,
  output logic [DATA_WIDTH-1:0]       rdata,
  output logic                        empty,
  output logic                        full,
  output logic [$clog2(FIFO_DEPTH):0] level,
  output logic                        overflow,
  output logic                        underflow
);

  localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

  logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
  logic [ADDR_WIDTH-1:0] wr_ptr;
  logic [ADDR_WIDTH-1:0] rd_ptr;

  assign empty = (level == 0);
  assign full  = (level == FIFO_DEPTH);
  assign rdata = mem[rd_ptr];

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      wr_ptr    <= '0;
      rd_ptr    <= '0;
      level     <= '0;
      overflow  <= 1'b0;
      underflow <= 1'b0;
    end else if (clear) begin
      wr_ptr    <= '0;
      rd_ptr    <= '0;
      level     <= '0;
      overflow  <= 1'b0;
      underflow <= 1'b0;
    end else begin
      overflow  <= 1'b0;
      underflow <= 1'b0;

      case ({push, pop})
        2'b10: begin
          if (!full) begin
            mem[wr_ptr] <= wdata;
            wr_ptr      <= wr_ptr + 1'b1;
            level       <= level + 1'b1;
          end else begin
            overflow    <= 1'b1;
          end
        end

        2'b01: begin
          if (!empty) begin
            rd_ptr      <= rd_ptr + 1'b1;
            level       <= level - 1'b1;
          end else begin
            underflow   <= 1'b1;
          end
        end

        2'b11: begin
          if (empty) begin
            mem[wr_ptr] <= wdata;
            wr_ptr      <= wr_ptr + 1'b1;
            level       <= level + 1'b1;
            underflow   <= 1'b1;
          end else if (full) begin
            rd_ptr      <= rd_ptr + 1'b1;
            level       <= level - 1'b1;
            overflow    <= 1'b1;
          end else begin
            mem[wr_ptr] <= wdata;
            wr_ptr      <= wr_ptr + 1'b1;
            rd_ptr      <= rd_ptr + 1'b1;
          end
        end

        default: ;
      endcase
    end
  end

endmodule
