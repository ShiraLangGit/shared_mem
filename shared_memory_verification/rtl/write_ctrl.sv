// Drains the selected FIFO and writes beats into dual-port RAM @ mem_clk

`include "shared_memory_defs.svh"

module write_ctrl (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  fifo_empty,
    input  wire [FIFO_BEAT_W-1:0] fifo_rdata,
    output reg                   fifo_r_en,

    output reg                   ram_wr_en,
    output reg  [MEM_ADDR_W-1:0] ram_wr_addr,
    output reg  [MEM_DATA_W-1:0] ram_wr_data,

    output wire                  write_active,
    output wire                  write_done_pulse
);

    reg write_busy;
    reg write_done_r;

    assign write_active     = write_busy;
    assign write_done_pulse = write_done_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_r_en    <= 1'b0;
            ram_wr_en    <= 1'b0;
            ram_wr_addr  <= {MEM_ADDR_W{1'b0}};
            ram_wr_data  <= {MEM_DATA_W{1'b0}};
            write_busy   <= 1'b0;
            write_done_r <= 1'b0;
        end else begin
            fifo_r_en    <= 1'b0;
            ram_wr_en    <= 1'b0;
            write_done_r <= 1'b0;

            if (!fifo_empty) begin
                fifo_r_en   <= 1'b1;
                ram_wr_en   <= 1'b1;
                ram_wr_addr <= fifo_rdata[FIFO_ADDR_MSB:FIFO_ADDR_LSB];
                ram_wr_data <= fifo_rdata[FIFO_DATA_MSB:FIFO_DATA_LSB];
                write_busy  <= 1'b1;
            end else if (write_busy) begin
                write_busy   <= 1'b0;
                write_done_r <= 1'b1;
            end
        end
    end

endmodule
