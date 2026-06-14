// BT write virtual interface @ bt_clk (28 MHz) — 96-bit data

interface bt_if (input logic clk);
    logic        rst_n;
    logic        wr_en;
    logic        data_valid;
    logic [31:0] start_addr;
    logic [95:0] data;
    logic        ready;

    clocking drv_cb @(posedge clk);
        default input #1step output negedge;
        output wr_en, data_valid, start_addr, data;
        input  ready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input wr_en, data_valid, start_addr, data, ready;
    endclocking

    // RTL accept (beat 0): wr_en && data_valid && ready (BT_IDLE)
    function automatic bit accepted();
        return wr_en && data_valid && ready;
    endfunction
endinterface
