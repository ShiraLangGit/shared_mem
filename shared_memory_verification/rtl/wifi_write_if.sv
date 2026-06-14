// WiFi 64-bit write interface @ wifi_clk — splits to 2×32-bit FIFO beats (little-endian)

`include "shared_memory_defs.svh"

module wifi_write_if (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [1:0]            interface_select,
    input  wire                  wr_en,
    input  wire                  data_valid,
    input  wire [31:0]           start_addr,
    input  wire [63:0]           data,

    output wire                  ready,
    output wire                  write_error,

    output wire                  fifo_w_en,
    output wire [FIFO_BEAT_W-1:0] fifo_wdata,
    input  wire                  fifo_full
);

    reg [31:0] txn_addr;
    reg [31:0] hi_word;
    reg        beat1_pending;

    wire selected = (interface_select == SEL_WIFI);

    wire new_word = wr_en && data_valid && selected && !fifo_full &&
                    !beat1_pending;

    wire push_beat1 = beat1_pending && !fifo_full;

    assign ready       = selected && !fifo_full && !beat1_pending;
    assign write_error = wr_en && data_valid && !selected && !beat1_pending;

    assign fifo_w_en  = new_word || push_beat1;
    assign fifo_wdata = push_beat1 ? {txn_addr + 32'd1, hi_word}
                                   : {start_addr, data[31:0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txn_addr      <= 32'h0;
            hi_word       <= 32'h0;
            beat1_pending <= 1'b0;
        end else begin
            if (new_word) begin
                txn_addr      <= start_addr;
                hi_word       <= data[63:32];
                beat1_pending <= 1'b1;
            end else if (push_beat1) begin
                beat1_pending <= 1'b0;
            end
        end
    end

endmodule
