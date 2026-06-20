// memory_status FSM: IDLE / WRITING / READING / ERROR
// Stays in WRITING until the selected interface FIFO is fully drained (CDC-safe).

`include "shared_memory_defs.svh"

module mem_status_ctrl (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [1:0] interface_select,
    input  wire       fifo_pending,

    input  wire       write_active,
    input  wire       write_done_pulse,
    input  wire       read_active,
    input  wire       read_done_pulse,

    input  wire       fac_write_error,
    input  wire       wifi_write_error,
    input  wire       bt_write_error,

    output reg  [1:0] memory_status
);

    wire invalid_select = (interface_select == SEL_INVALID);

    wire error_event = invalid_select ||
                       fac_write_error ||
                       wifi_write_error ||
                       bt_write_error;

    wire write_busy = write_active || fifo_pending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            memory_status <= STATUS_IDLE;
        end else begin
            case (memory_status)
                STATUS_IDLE: begin
                    if (error_event)
                        memory_status <= STATUS_ERROR;
                    else if (write_busy || write_done_pulse)
                        memory_status <= STATUS_WRITING;
                    else if (read_active)
                        memory_status <= STATUS_READING;
                end

                STATUS_WRITING: begin
                    if (error_event)
                        memory_status <= STATUS_ERROR;
                    else if (!write_busy && !write_active)
                        memory_status <= STATUS_IDLE;
                    else if (read_active)
                        memory_status <= STATUS_READING;
                end

                STATUS_READING: begin
                    if (error_event)
                        memory_status <= STATUS_ERROR;
                    else if (read_done_pulse && !read_active)
                        memory_status <= STATUS_IDLE;
                    else if (write_busy || write_active)
                        memory_status <= STATUS_WRITING;
                end

                STATUS_ERROR: begin
                    if (!error_event)
                        memory_status <= STATUS_IDLE;
                end

                default: memory_status <= STATUS_IDLE;
            endcase
        end
    end

endmodule
