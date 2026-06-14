// Read port control @ mem_clk — 2-cycle RAM read latency, burst auto-increment

`include "shared_memory_defs.svh"

module read_ctrl (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  rd_en,
    input  wire [31:0]           rd_addr,

    output reg                   ram_rd_en,
    output reg  [MEM_ADDR_W-1:0] ram_rd_addr,

    input  wire [MEM_DATA_W-1:0] ram_rd_data,

    output reg  [MEM_DATA_W-1:0] o_data,
    output reg                   o_data_valid,
    output reg                   o_ready,

    output wire                  read_active,
    output wire                  read_done_pulse
);

    reg        in_burst;
    reg [31:0] next_addr;
    reg        rd_en_d1;
    reg        rd_en_d2;
    reg        was_reading;
    reg        read_done_r;

    assign read_active     = in_burst || rd_en_d1 || rd_en_d2;
    assign read_done_pulse = read_done_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_rd_en    <= 1'b0;
            ram_rd_addr  <= {MEM_ADDR_W{1'b0}};
            o_data       <= {MEM_DATA_W{1'b0}};
            o_data_valid <= 1'b0;
            o_ready      <= 1'b1;
            in_burst     <= 1'b0;
            next_addr    <= 32'h0;
            rd_en_d1     <= 1'b0;
            rd_en_d2     <= 1'b0;
            was_reading  <= 1'b0;
            read_done_r  <= 1'b0;
        end else begin
            ram_rd_en    <= 1'b0;
            o_data_valid <= 1'b0;
            read_done_r  <= 1'b0;

            rd_en_d1 <= rd_en;
            rd_en_d2 <= rd_en_d1;

            if (rd_en) begin
                ram_rd_en   <= 1'b1;
                ram_rd_addr <= in_burst ? next_addr[MEM_ADDR_W-1:0] :
                               rd_addr[MEM_ADDR_W-1:0];
                next_addr   <= (in_burst ? next_addr : rd_addr) + 32'd1;
                in_burst    <= 1'b1;
                o_ready     <= 1'b0;
            end

            if (rd_en_d2) begin
                o_data       <= ram_rd_data;
                o_data_valid <= 1'b1;
            end

            if (in_burst && !rd_en && !rd_en_d1 && !rd_en_d2) begin
                in_burst    <= 1'b0;
                o_ready     <= 1'b1;
                read_done_r <= was_reading;
            end

            was_reading <= in_burst || rd_en || rd_en_d1 || rd_en_d2;
        end
    end

endmodule
