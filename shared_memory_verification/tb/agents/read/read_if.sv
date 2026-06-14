// Read port virtual interface @ mem_clk (80 MHz)

interface read_if (input logic clk);
    logic        rst_n;
    logic        rd_en;
    logic [31:0] addr;
    logic [31:0] data;
    logic        data_valid;
    logic        ready;

    clocking drv_cb @(posedge clk);
        default input #1step output negedge;
        output rd_en, addr;
        input  data, data_valid, ready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input rd_en, addr, data, data_valid, ready;
    endclocking
endinterface
