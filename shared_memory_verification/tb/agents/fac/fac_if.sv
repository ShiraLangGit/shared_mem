// FAC write virtual interface @ fac_clk (80 MHz)

interface fac_if (input logic clk);
    logic        rst_n;
    logic        wr_en;
    logic        data_valid;
    logic [31:0] start_addr;
    logic [31:0] data;
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

    // RTL accept: wr_en && data_valid && ready (ready = selected && !fifo_full)
    function automatic bit accepted();
        return wr_en && data_valid && ready;
    endfunction
endinterface
