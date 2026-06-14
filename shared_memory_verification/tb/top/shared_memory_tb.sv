// Shared Memory Block — UVM testbench top

`timescale 1ns / 1ps

module shared_memory_tb;

    import uvm_pkg::*;
    import shared_memory_pkg::*;
    import fac_agent_pkg::*;
    import wifi_agent_pkg::*;
    import bt_agent_pkg::*;
    import read_agent_pkg::*;
    import shared_memory_env_pkg::*;
    import shared_memory_test_pkg::*;

    // Clock periods (Verification Plan)
    localparam time FAC_PERIOD  = 12.5ns;   // 80 MHz
    localparam time WIFI_PERIOD = 8.333ns;  // 120 MHz
    localparam time BT_PERIOD   = 35.714ns; // 28 MHz
    localparam time MEM_PERIOD  = 12.5ns;   // 80 MHz

    logic fac_clk;
    logic wifi_clk;
    logic bt_clk;
    logic mem_clk;
    logic reset_n;

    // Virtual interfaces
    fac_if  fac_vif  (fac_clk);
    wifi_if wifi_vif (wifi_clk);
    bt_if   bt_vif   (bt_clk);
    read_if read_vif (mem_clk);
    ctrl_if ctrl_vif (mem_clk);

    // Interface bindings
    assign fac_vif.rst_n  = reset_n;
    assign wifi_vif.rst_n = reset_n;
    assign bt_vif.rst_n   = reset_n;
    assign read_vif.rst_n = reset_n;
    assign ctrl_vif.rst_n = reset_n;

    shared_memory dut (
        .reset_n          (reset_n),

        .fac_clk          (fac_clk),
        .fac_wr_en        (fac_vif.wr_en),
        .fac_data_valid   (fac_vif.data_valid),
        .fac_start_addr   (fac_vif.start_addr),
        .fac_data         (fac_vif.data),
        .fac_ready        (fac_vif.ready),

        .wifi_clk         (wifi_clk),
        .wifi_wr_en       (wifi_vif.wr_en),
        .wifi_data_valid  (wifi_vif.data_valid),
        .wifi_start_addr  (wifi_vif.start_addr),
        .wifi_data        (wifi_vif.data),
        .wifi_ready       (wifi_vif.ready),

        .bt_clk           (bt_clk),
        .bt_wr_en         (bt_vif.wr_en),
        .bt_data_valid    (bt_vif.data_valid),
        .bt_start_addr    (bt_vif.start_addr),
        .bt_data          (bt_vif.data),
        .bt_ready         (bt_vif.ready),

        .mem_clk          (mem_clk),
        .o_rd_en          (read_vif.rd_en),
        .o_addr           (read_vif.addr),
        .o_data           (read_vif.data),
        .o_data_valid     (read_vif.data_valid),
        .o_ready          (read_vif.ready),

        .interface_select (ctrl_vif.interface_select),
        .memory_status    (ctrl_vif.memory_status)
    );

    // Clock generation
    initial begin
        fac_clk = 1'b0;
        forever #(FAC_PERIOD / 2) fac_clk = ~fac_clk;
    end

    initial begin
        wifi_clk = 1'b0;
        forever #(WIFI_PERIOD / 2) wifi_clk = ~wifi_clk;
    end

    initial begin
        bt_clk = 1'b0;
        forever #(BT_PERIOD / 2) bt_clk = ~bt_clk;
    end

    initial begin
        mem_clk = 1'b0;
        forever #(MEM_PERIOD / 2) mem_clk = ~mem_clk;
    end

    // Reset and default control
    initial begin
        reset_n                   = 1'b0;
        fac_vif.wr_en             = 1'b0;
        fac_vif.data_valid        = 1'b0;
        fac_vif.start_addr        = '0;
        fac_vif.data              = '0;
        wifi_vif.wr_en            = 1'b0;
        wifi_vif.data_valid       = 1'b0;
        wifi_vif.start_addr       = '0;
        wifi_vif.data             = '0;
        bt_vif.wr_en              = 1'b0;
        bt_vif.data_valid         = 1'b0;
        bt_vif.start_addr         = '0;
        bt_vif.data               = '0;
        read_vif.rd_en            = 1'b0;
        read_vif.addr             = '0;
        ctrl_vif.interface_select = SEL_FAC;
        #100ns;
        reset_n = 1'b1;
    end

    // UVM config_db + test entry
    initial begin
        uvm_config_db#(virtual fac_if)::set(null, "*", "fac_vif", fac_vif);
        uvm_config_db#(virtual wifi_if)::set(null, "*", "wifi_vif", wifi_vif);
        uvm_config_db#(virtual bt_if)::set(null, "*", "bt_vif", bt_vif);
        uvm_config_db#(virtual read_if)::set(null, "*", "read_vif", read_vif);
        uvm_config_db#(virtual ctrl_if)::set(null, "*", "ctrl_vif", ctrl_vif);
        run_test();
    end

endmodule
