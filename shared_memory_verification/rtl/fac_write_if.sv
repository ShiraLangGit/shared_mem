// FAC 32-bit write interface @ fac_clk → async FIFO

`include "shared_memory_defs.svh"

module fac_write_if (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [1:0]            interface_select,
    input  wire                  wr_en,
    input  wire                  data_valid,
    input  wire [31:0]           start_addr,
    input  wire [31:0]           data,

    output wire                  ready,
    output wire                  write_error,

    output wire                  fifo_w_en,
    output wire [FIFO_BEAT_W-1:0] fifo_wdata,
    input  wire                  fifo_full
);

    reg [31:0] cur_addr;
    reg        in_burst;

    wire selected = (interface_select == SEL_FAC);

    wire accept = wr_en && data_valid && selected && !fifo_full;

    assign ready       = selected && !fifo_full;
    assign write_error = wr_en && data_valid && !selected;

    assign fifo_w_en   = accept;
    assign fifo_wdata  = {in_burst ? cur_addr : start_addr, data};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_addr <= 32'h0;
            in_burst <= 1'b0;
        end else begin
            if (accept) begin
                if (!in_burst) begin
                    cur_addr <= start_addr + 32'd1;
                    in_burst <= 1'b1;
                end else begin
                    cur_addr <= cur_addr + 32'd1;
                end
            end else if (!wr_en || !data_valid) begin
                in_burst <= 1'b0;
            end
        end
    end

endmodule
