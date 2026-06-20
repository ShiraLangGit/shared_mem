// WiFi 64-bit write interface @ wifi_clk — splits to 2×32-bit FIFO beats (little-endian)
// Accept latches addr/data on posedge; beats push from registered fields on later cycles.

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
    reg [31:0] lo_word;
    reg [31:0] hi_word;
    reg        beat0_pending;
    reg        beat1_pending;

    wire selected = (interface_select == SEL_WIFI);

    wire accept = wr_en && data_valid && selected && !fifo_full &&
                  !beat0_pending && !beat1_pending;

    wire push_beat0 = beat0_pending && !fifo_full;
    wire push_beat1 = beat1_pending && !fifo_full;

    assign ready       = selected && !fifo_full && !beat0_pending && !beat1_pending;
    assign write_error = wr_en && data_valid && !selected &&
                         !beat0_pending && !beat1_pending;

    assign fifo_w_en  = push_beat0 || push_beat1;
    assign fifo_wdata = push_beat1 ? {txn_addr + 32'd1, hi_word} :
                        push_beat0 ? {txn_addr, lo_word} :
                                     {FIFO_BEAT_W{1'b0}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txn_addr      <= 32'h0;
            lo_word       <= 32'h0;
            hi_word       <= 32'h0;
            beat0_pending <= 1'b0;
            beat1_pending <= 1'b0;
        end else begin
            if (accept) begin
                txn_addr      <= start_addr;
                lo_word       <= data[31:0];
                hi_word       <= data[63:32];
                beat0_pending <= 1'b1;
            end else if (push_beat0) begin
                beat0_pending <= 1'b0;
                beat1_pending <= 1'b1;
            end else if (push_beat1) begin
                beat1_pending <= 1'b0;
            end
        end
    end

endmodule
