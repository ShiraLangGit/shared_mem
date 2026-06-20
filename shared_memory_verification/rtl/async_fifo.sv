// Asynchronous FIFO with Gray-code pointers and double-flop CDC synchronizers
// Read data is registered on rclk for stable capture by write_ctrl.

module async_fifo #(
    parameter DATA_W = 64,
    parameter DEPTH  = 16,
    parameter ADDR_W = $clog2(DEPTH)
) (
    input  wire               wclk,
    input  wire               w_rst_n,
    input  wire               w_en,
    input  wire [DATA_W-1:0]  wdata,
    output wire               w_full,

    input  wire               rclk,
    input  wire               r_rst_n,
    input  wire               r_en,
    output wire [DATA_W-1:0]  rdata,
    output wire               r_empty
);

    localparam PTR_W = ADDR_W + 1;

    reg [DATA_W-1:0] mem [0:DEPTH-1];

    reg [PTR_W-1:0] wptr_bin;
    reg [PTR_W-1:0] rptr_bin;

    reg [PTR_W-1:0] wptr_gray;
    reg [PTR_W-1:0] rptr_gray;

    reg [PTR_W-1:0] wptr_gray_rclk1;
    reg [PTR_W-1:0] wptr_gray_rclk2;
    reg [PTR_W-1:0] rptr_gray_wclk1;
    reg [PTR_W-1:0] rptr_gray_wclk2;

    reg [DATA_W-1:0] rdata_r;

    wire [PTR_W-1:0] wptr_bin_next  = wptr_bin + {{(PTR_W-1){1'b0}}, 1'b1};
    wire [PTR_W-1:0] rptr_bin_next  = rptr_bin + {{(PTR_W-1){1'b0}}, 1'b1};

    wire [PTR_W-1:0] wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
    wire [PTR_W-1:0] rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

    wire w_push = w_en && !w_full;
    wire r_pop  = r_en && !r_empty;

    assign w_full  = (wptr_gray_next == {~rptr_gray_wclk2[PTR_W-1:PTR_W-2],
                                         rptr_gray_wclk2[PTR_W-3:0]});
    assign r_empty = (rptr_gray == wptr_gray_rclk2);

    assign rdata = rdata_r;

    // Write clock domain
    always @(posedge wclk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            wptr_bin  <= {PTR_W{1'b0}};
            wptr_gray <= {PTR_W{1'b0}};
        end else if (w_push) begin
            mem[wptr_bin[ADDR_W-1:0]] <= wdata;
            wptr_bin                  <= wptr_bin_next;
            wptr_gray                 <= wptr_gray_next;
        end
    end

    // Read clock domain — register FIFO output for stable downstream capture
    always @(posedge rclk or negedge r_rst_n) begin
        if (!r_rst_n) begin
            rptr_bin  <= {PTR_W{1'b0}};
            rptr_gray <= {PTR_W{1'b0}};
            rdata_r   <= {DATA_W{1'b0}};
        end else begin
            if (r_pop) begin
                rptr_bin  <= rptr_bin_next;
                rptr_gray <= rptr_gray_next;
            end

            if (!r_empty)
                rdata_r <= mem[rptr_bin[ADDR_W-1:0]];
        end
    end

    // Synchronize write pointer into read clock domain
    always @(posedge rclk or negedge r_rst_n) begin
        if (!r_rst_n) begin
            wptr_gray_rclk1 <= {PTR_W{1'b0}};
            wptr_gray_rclk2 <= {PTR_W{1'b0}};
        end else begin
            wptr_gray_rclk1 <= wptr_gray;
            wptr_gray_rclk2 <= wptr_gray_rclk1;
        end
    end

    // Synchronize read pointer into write clock domain
    always @(posedge wclk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            rptr_gray_wclk1 <= {PTR_W{1'b0}};
            rptr_gray_wclk2 <= {PTR_W{1'b0}};
        end else begin
            rptr_gray_wclk1 <= rptr_gray;
            rptr_gray_wclk2 <= rptr_gray_wclk1;
        end
    end

endmodule
