// Drains the selected FIFO and writes beats into dual-port RAM @ mem_clk
// FSM: IDLE -> LATCH (capture registered rdata) -> POP -> WRITE -> repeat
// One mem_clk wait after !empty before capture (pairs with registered async_fifo rdata).

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

    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_LATCH,
        STATE_POP,
        STATE_WRITE
    } state_t;

    state_t state, next_state;
    reg [MEM_ADDR_W-1:0] stored_addr;
    reg [MEM_DATA_W-1:0] stored_data;
    reg write_done_r;

    assign write_active     = (state != STATE_IDLE);
    assign write_done_pulse = write_done_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE: begin
                if (!fifo_empty)
                    next_state = STATE_LATCH;
            end
            STATE_LATCH: begin
                next_state = STATE_POP;
            end
            STATE_POP: begin
                next_state = STATE_WRITE;
            end
            STATE_WRITE: begin
                if (!fifo_empty)
                    next_state = STATE_LATCH;
                else
                    next_state = STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_r_en    <= 1'b0;
            ram_wr_en    <= 1'b0;
            ram_wr_addr  <= {MEM_ADDR_W{1'b0}};
            ram_wr_data  <= {MEM_DATA_W{1'b0}};
            stored_addr  <= {MEM_ADDR_W{1'b0}};
            stored_data  <= {MEM_DATA_W{1'b0}};
            write_done_r <= 1'b0;
        end else begin
            fifo_r_en    <= 1'b0;
            ram_wr_en    <= 1'b0;
            write_done_r <= 1'b0;

            case (state)
                STATE_LATCH: begin
                    stored_addr <= fifo_rdata[FIFO_ADDR_MSB:FIFO_ADDR_LSB];
                    stored_data <= fifo_rdata[FIFO_DATA_MSB:FIFO_DATA_LSB];
                end

                STATE_POP: begin
                    fifo_r_en <= 1'b1;
                end

                STATE_WRITE: begin
                    ram_wr_en   <= 1'b1;
                    ram_wr_addr <= stored_addr;
                    ram_wr_data <= stored_data;

                    if (next_state == STATE_IDLE)
                        write_done_r <= 1'b1;
                end
            endcase
        end
    end

endmodule
