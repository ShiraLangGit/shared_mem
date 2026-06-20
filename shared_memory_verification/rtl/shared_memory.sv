// Shared Memory Block — top-level integration

`include "shared_memory_defs.svh"

module shared_memory (
    input  wire        reset_n,

    // FAC write interface @ 80 MHz
    input  wire        fac_clk,
    input  wire        fac_wr_en,
    input  wire        fac_data_valid,
    input  wire [31:0] fac_start_addr,
    input  wire [31:0] fac_data,
    output wire        fac_ready,

    // WiFi write interface @ 120 MHz
    input  wire        wifi_clk,
    input  wire        wifi_wr_en,
    input  wire        wifi_data_valid,
    input  wire [31:0] wifi_start_addr,
    input  wire [63:0] wifi_data,
    output wire        wifi_ready,

    // BT write interface @ 28 MHz
    input  wire        bt_clk,
    input  wire        bt_wr_en,
    input  wire        bt_data_valid,
    input  wire [31:0] bt_start_addr,
    input  wire [95:0] bt_data,
    output wire        bt_ready,

    // Read port @ 80 MHz
    input  wire        mem_clk,
    input  wire        o_rd_en,
    input  wire [31:0] o_addr,
    output wire [31:0] o_data,
    output wire        o_data_valid,
    output wire        o_ready,

    // Control
    input  wire [1:0]  interface_select,
    output wire [1:0]  memory_status
);

    // Synchronized interface_select per write clock domain
    reg [1:0] fac_sel_s1,  fac_sel_s2;
    reg [1:0] wifi_sel_s1, wifi_sel_s2;
    reg [1:0] bt_sel_s1,   bt_sel_s2;

    always @(posedge fac_clk or negedge reset_n) begin
        if (!reset_n) begin
            fac_sel_s1 <= SEL_FAC;
            fac_sel_s2 <= SEL_FAC;
        end else begin
            fac_sel_s1 <= interface_select;
            fac_sel_s2 <= fac_sel_s1;
        end
    end

    always @(posedge wifi_clk or negedge reset_n) begin
        if (!reset_n) begin
            wifi_sel_s1 <= SEL_WIFI;
            wifi_sel_s2 <= SEL_WIFI;
        end else begin
            wifi_sel_s1 <= interface_select;
            wifi_sel_s2 <= wifi_sel_s1;
        end
    end

    always @(posedge bt_clk or negedge reset_n) begin
        if (!reset_n) begin
            bt_sel_s1 <= SEL_BT;
            bt_sel_s2 <= SEL_BT;
        end else begin
            bt_sel_s1 <= interface_select;
            bt_sel_s2 <= bt_sel_s1;
        end
    end

    // FAC write path
    wire                  fac_fifo_w_en;
    wire [FIFO_BEAT_W-1:0] fac_fifo_wdata;
    wire                  fac_fifo_full;
    wire                  fac_fifo_r_en;
    wire                  fac_fifo_empty;
    wire [FIFO_BEAT_W-1:0] fac_fifo_rdata;
    wire                  fac_write_error;

    fac_write_if u_fac_write_if (
        .clk               (fac_clk),
        .rst_n             (reset_n),
        .interface_select  (fac_sel_s2),
        .wr_en             (fac_wr_en),
        .data_valid        (fac_data_valid),
        .start_addr        (fac_start_addr),
        .data              (fac_data),
        .ready             (fac_ready),
        .write_error       (fac_write_error),
        .fifo_w_en         (fac_fifo_w_en),
        .fifo_wdata        (fac_fifo_wdata),
        .fifo_full         (fac_fifo_full)
    );

    async_fifo #(
        .DATA_W (FIFO_BEAT_W),
        .DEPTH  (FIFO_DEPTH)
    ) u_fac_fifo (
        .wclk    (fac_clk),
        .w_rst_n (reset_n),
        .w_en    (fac_fifo_w_en),
        .wdata   (fac_fifo_wdata),
        .w_full  (fac_fifo_full),
        .rclk    (mem_clk),
        .r_rst_n (reset_n),
        .r_en    (fac_fifo_r_en),
        .rdata   (fac_fifo_rdata),
        .r_empty (fac_fifo_empty)
    );

    // WiFi write path
    wire                  wifi_fifo_w_en;
    wire [FIFO_BEAT_W-1:0] wifi_fifo_wdata;
    wire                  wifi_fifo_full;
    wire                  wifi_fifo_r_en;
    wire                  wifi_fifo_empty;
    wire [FIFO_BEAT_W-1:0] wifi_fifo_rdata;
    wire                  wifi_write_error;

    wifi_write_if u_wifi_write_if (
        .clk               (wifi_clk),
        .rst_n             (reset_n),
        .interface_select  (wifi_sel_s2),
        .wr_en             (wifi_wr_en),
        .data_valid        (wifi_data_valid),
        .start_addr        (wifi_start_addr),
        .data              (wifi_data),
        .ready             (wifi_ready),
        .write_error       (wifi_write_error),
        .fifo_w_en         (wifi_fifo_w_en),
        .fifo_wdata        (wifi_fifo_wdata),
        .fifo_full         (wifi_fifo_full)
    );

    async_fifo #(
        .DATA_W (FIFO_BEAT_W),
        .DEPTH  (FIFO_DEPTH)
    ) u_wifi_fifo (
        .wclk    (wifi_clk),
        .w_rst_n (reset_n),
        .w_en    (wifi_fifo_w_en),
        .wdata   (wifi_fifo_wdata),
        .w_full  (wifi_fifo_full),
        .rclk    (mem_clk),
        .r_rst_n (reset_n),
        .r_en    (wifi_fifo_r_en),
        .rdata   (wifi_fifo_rdata),
        .r_empty (wifi_fifo_empty)
    );

    // BT write path
    wire                  bt_fifo_w_en;
    wire [FIFO_BEAT_W-1:0] bt_fifo_wdata;
    wire                  bt_fifo_full;
    wire                  bt_fifo_r_en;
    wire                  bt_fifo_empty;
    wire [FIFO_BEAT_W-1:0] bt_fifo_rdata;
    wire                  bt_write_error;

    bt_write_if u_bt_write_if (
        .clk               (bt_clk),
        .rst_n             (reset_n),
        .interface_select  (bt_sel_s2),
        .wr_en             (bt_wr_en),
        .data_valid        (bt_data_valid),
        .start_addr        (bt_start_addr),
        .data              (bt_data),
        .ready             (bt_ready),
        .write_error       (bt_write_error),
        .fifo_w_en         (bt_fifo_w_en),
        .fifo_wdata        (bt_fifo_wdata),
        .fifo_full         (bt_fifo_full)
    );

    async_fifo #(
        .DATA_W (FIFO_BEAT_W),
        .DEPTH  (FIFO_DEPTH)
    ) u_bt_fifo (
        .wclk    (bt_clk),
        .w_rst_n (reset_n),
        .w_en    (bt_fifo_w_en),
        .wdata   (bt_fifo_wdata),
        .w_full  (bt_fifo_full),
        .rclk    (mem_clk),
        .r_rst_n (reset_n),
        .r_en    (bt_fifo_r_en),
        .rdata   (bt_fifo_rdata),
        .r_empty (bt_fifo_empty)
    );

    // Write path on mem_clk
    wire                  mux_fifo_empty;
    wire [FIFO_BEAT_W-1:0] mux_fifo_rdata;
    wire                  mux_fifo_r_en;

    wire                  ram_wr_en;
    wire [MEM_ADDR_W-1:0] ram_wr_addr;
    wire [MEM_DATA_W-1:0] ram_wr_data;

    wire                  ram_rd_en;
    wire [MEM_ADDR_W-1:0] ram_rd_addr;
    wire [MEM_DATA_W-1:0] ram_rd_data;

    wire                  write_active;
    wire                  write_done_pulse;
    wire                  read_active;
    wire                  read_done_pulse;

    wire sel_fifo_empty = (interface_select == SEL_FAC)  ? fac_fifo_empty  :
                          (interface_select == SEL_WIFI) ? wifi_fifo_empty :
                          (interface_select == SEL_BT)   ? bt_fifo_empty   : 1'b1;

    wire fifo_pending = (interface_select != SEL_INVALID) && !sel_fifo_empty;

    interface_mux u_interface_mux (
        .interface_select (interface_select),
        .fac_fifo_empty   (fac_fifo_empty),
        .fac_fifo_rdata   (fac_fifo_rdata),
        .fac_fifo_r_en    (fac_fifo_r_en),
        .wifi_fifo_empty  (wifi_fifo_empty),
        .wifi_fifo_rdata  (wifi_fifo_rdata),
        .wifi_fifo_r_en   (wifi_fifo_r_en),
        .bt_fifo_empty    (bt_fifo_empty),
        .bt_fifo_rdata    (bt_fifo_rdata),
        .bt_fifo_r_en     (bt_fifo_r_en),
        .mux_fifo_empty   (mux_fifo_empty),
        .mux_fifo_rdata   (mux_fifo_rdata),
        .mux_fifo_r_en    (mux_fifo_r_en)
    );

    write_ctrl u_write_ctrl (
        .clk              (mem_clk),
        .rst_n            (reset_n),
        .fifo_empty       (mux_fifo_empty),
        .fifo_rdata       (mux_fifo_rdata),
        .fifo_r_en        (mux_fifo_r_en),
        .ram_wr_en        (ram_wr_en),
        .ram_wr_addr      (ram_wr_addr),
        .ram_wr_data      (ram_wr_data),
        .write_active     (write_active),
        .write_done_pulse (write_done_pulse)
    );

    read_ctrl u_read_ctrl (
        .clk              (mem_clk),
        .rst_n            (reset_n),
        .rd_en            (o_rd_en),
        .rd_addr          (o_addr),
        .ram_rd_en        (ram_rd_en),
        .ram_rd_addr      (ram_rd_addr),
        .ram_rd_data      (ram_rd_data),
        .o_data           (o_data),
        .o_data_valid     (o_data_valid),
        .o_ready          (o_ready),
        .read_active      (read_active),
        .read_done_pulse  (read_done_pulse)
    );

    dual_port_ram u_dual_port_ram (
        .clk      (mem_clk),
        .rst_n    (reset_n),
        .wr_en    (ram_wr_en),
        .wr_addr  (ram_wr_addr),
        .wr_data  (ram_wr_data),
        .rd_en    (ram_rd_en),
        .rd_addr  (ram_rd_addr),
        .rd_data  (ram_rd_data)
    );

    // Synchronize write-error indicators into mem_clk domain
    reg fac_err_s1,  fac_err_s2;
    reg wifi_err_s1, wifi_err_s2;
    reg bt_err_s1,   bt_err_s2;

    always @(posedge mem_clk or negedge reset_n) begin
        if (!reset_n) begin
            fac_err_s1  <= 1'b0;
            fac_err_s2  <= 1'b0;
            wifi_err_s1 <= 1'b0;
            wifi_err_s2 <= 1'b0;
            bt_err_s1   <= 1'b0;
            bt_err_s2   <= 1'b0;
        end else begin
            fac_err_s1  <= fac_write_error;
            fac_err_s2  <= fac_err_s1;
            wifi_err_s1 <= wifi_write_error;
            wifi_err_s2 <= wifi_err_s1;
            bt_err_s1   <= bt_write_error;
            bt_err_s2   <= bt_err_s1;
        end
    end

    mem_status_ctrl u_mem_status_ctrl (
        .clk              (mem_clk),
        .rst_n            (reset_n),
        .interface_select (interface_select),
        .fifo_pending     (fifo_pending),
        .write_active     (write_active),
        .write_done_pulse (write_done_pulse),
        .read_active      (read_active),
        .read_done_pulse  (read_done_pulse),
        .fac_write_error  (fac_err_s2),
        .wifi_write_error (wifi_err_s2),
        .bt_write_error   (bt_err_s2),
        .memory_status    (memory_status)
    );

endmodule
