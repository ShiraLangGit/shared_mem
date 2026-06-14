// Selects the active interface FIFO read port for write_ctrl

`include "shared_memory_defs.svh"

module interface_mux (
    input  wire [1:0]            interface_select,

    // FAC FIFO read side
    input  wire                  fac_fifo_empty,
    input  wire [FIFO_BEAT_W-1:0] fac_fifo_rdata,
    output wire                  fac_fifo_r_en,

    // WiFi FIFO read side
    input  wire                  wifi_fifo_empty,
    input  wire [FIFO_BEAT_W-1:0] wifi_fifo_rdata,
    output wire                  wifi_fifo_r_en,

    // BT FIFO read side
    input  wire                  bt_fifo_empty,
    input  wire [FIFO_BEAT_W-1:0] bt_fifo_rdata,
    output wire                  bt_fifo_r_en,

    // Muxed output to write_ctrl
    output wire                  mux_fifo_empty,
    output wire [FIFO_BEAT_W-1:0] mux_fifo_rdata,
    input  wire                  mux_fifo_r_en
);

    wire sel_valid = (interface_select != SEL_INVALID);

    assign fac_fifo_r_en  = mux_fifo_r_en && (interface_select == SEL_FAC);
    assign wifi_fifo_r_en = mux_fifo_r_en && (interface_select == SEL_WIFI);
    assign bt_fifo_r_en   = mux_fifo_r_en && (interface_select == SEL_BT);

    assign mux_fifo_empty = !sel_valid ? 1'b1 :
                            (interface_select == SEL_FAC)  ? fac_fifo_empty  :
                            (interface_select == SEL_WIFI) ? wifi_fifo_empty :
                            (interface_select == SEL_BT)   ? bt_fifo_empty   : 1'b1;

    assign mux_fifo_rdata = (interface_select == SEL_FAC)  ? fac_fifo_rdata  :
                            (interface_select == SEL_WIFI) ? wifi_fifo_rdata :
                            (interface_select == SEL_BT)   ? bt_fifo_rdata   :
                            {FIFO_BEAT_W{1'b0}};

endmodule
