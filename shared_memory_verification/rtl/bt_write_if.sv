// BT 96-bit write interface @ bt_clk — splits to 3×32-bit FIFO beats (little-endian)

`include "shared_memory_defs.svh"

module bt_write_if (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [1:0]            interface_select,
    input  wire                  wr_en,
    input  wire                  data_valid,
    input  wire [31:0]           start_addr,
    input  wire [95:0]           data,

    output wire                  ready,
    output wire                  write_error,

    output wire                  fifo_w_en,
    output wire [FIFO_BEAT_W-1:0] fifo_wdata,
    input  wire                  fifo_full
);

    bt_split_state_e state;
    reg [31:0]       txn_addr;
    reg [31:0]       word1;
    reg [31:0]       word2;

    wire selected = (interface_select == SEL_BT);

    wire new_word = wr_en && data_valid && selected && !fifo_full &&
                    (state == BT_IDLE);

    wire push_beat = (state == BT_BEAT1 || state == BT_BEAT2) && !fifo_full;

    assign ready       = selected && !fifo_full && (state == BT_IDLE);
    assign write_error = wr_en && data_valid && !selected && (state == BT_IDLE);

    assign fifo_w_en  = new_word || push_beat;
    assign fifo_wdata = (state == BT_BEAT1) ? {txn_addr + 32'd1, word1} :
                        (state == BT_BEAT2) ? {txn_addr + 32'd2, word2} :
                                              {start_addr, data[31:0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= BT_IDLE;
            txn_addr <= 32'h0;
            word1    <= 32'h0;
            word2    <= 32'h0;
        end else begin
            case (state)
                BT_IDLE: begin
                    if (new_word) begin
                        txn_addr <= start_addr;
                        word1    <= data[63:32];
                        word2    <= data[95:64];
                        state    <= BT_BEAT1;
                    end
                end

                BT_BEAT1: begin
                    if (push_beat)
                        state <= BT_BEAT2;
                end

                BT_BEAT2: begin
                    if (push_beat)
                        state <= BT_IDLE;
                end

                default: state <= BT_IDLE;
            endcase
        end
    end

endmodule
