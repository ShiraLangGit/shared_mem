// Drains the selected FIFO and writes beats into dual-port RAM @ mem_clk
// One pop + one RAM write per unique fifo_rdata beat (no duplicate drain on CDC stale rdata).

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

    localparam int unsigned CDC_SETTLE_CYCLES = 4;

    reg [2:0]                  settle_cnt;
    reg [1:0]                  empty_stable_cnt;
    reg                        drain_active;
    reg                        drain_done_pending;
    reg                        write_done_r;
    reg [FIFO_BEAT_W-1:0]      last_drained_beat;

    wire fifo_settled      = !fifo_empty && (settle_cnt >= CDC_SETTLE_CYCLES[2:0]);
    wire can_start           = fifo_settled && !drain_active;
    wire can_drain           = drain_active ? !fifo_empty : can_start;
    wire beat_is_new         = (fifo_rdata !== last_drained_beat);
    wire drain_this_beat     = can_drain && beat_is_new;
    wire fifo_empty_stable   = (empty_stable_cnt >= 2'd2);

    assign write_active     = drain_active || can_start || drain_done_pending;
    assign write_done_pulse = write_done_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_r_en            <= 1'b0;
            ram_wr_en            <= 1'b0;
            ram_wr_addr          <= {MEM_ADDR_W{1'b0}};
            ram_wr_data          <= {MEM_DATA_W{1'b0}};
            settle_cnt           <= 3'd0;
            empty_stable_cnt     <= 2'd0;
            drain_active         <= 1'b0;
            drain_done_pending   <= 1'b0;
            write_done_r         <= 1'b0;
            last_drained_beat    <= {FIFO_BEAT_W{1'b0}};
        end else begin
            fifo_r_en    <= 1'b0;
            ram_wr_en    <= 1'b0;
            write_done_r <= 1'b0;

            if (drain_active || drain_done_pending) begin
                settle_cnt <= 3'd0;
            end else if (fifo_empty) begin
                settle_cnt <= 3'd0;
            end else if (settle_cnt < CDC_SETTLE_CYCLES[2:0]) begin
                settle_cnt <= settle_cnt + 3'd1;
            end

            if (drain_active && fifo_empty)
                empty_stable_cnt <= empty_stable_cnt + 2'd1;
            else
                empty_stable_cnt <= 2'd0;

            if (drain_this_beat) begin
                fifo_r_en          <= 1'b1;
                ram_wr_en          <= 1'b1;
                ram_wr_addr        <= fifo_rdata[FIFO_ADDR_MSB:FIFO_ADDR_LSB];
                ram_wr_data        <= fifo_rdata[FIFO_DATA_MSB:FIFO_DATA_LSB];
                last_drained_beat  <= fifo_rdata;
                drain_active       <= 1'b1;
                drain_done_pending <= 1'b0;
            end else if (drain_active && fifo_empty_stable) begin
                if (!drain_done_pending) begin
                    drain_done_pending <= 1'b1;
                end else begin
                    drain_active       <= 1'b0;
                    drain_done_pending <= 1'b0;
                    write_done_r       <= 1'b1;
                    last_drained_beat  <= {FIFO_BEAT_W{1'b0}};
                end
            end
        end
    end

endmodule
