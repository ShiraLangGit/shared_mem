// Shared Memory Block — global parameters, typedefs, and encodings

package shared_memory_pkg;

    // Memory geometry
    parameter int MEM_DEPTH  = 1024;
    parameter int MEM_ADDR_W = 10;
    parameter int MEM_DATA_W = 32;

    // Async FIFO geometry
    parameter int FIFO_DEPTH  = 16;
    parameter int FIFO_ADDR_W = 4;
    parameter int FIFO_BEAT_W = 64;

    // FIFO beat packing: {addr[31:0], data[31:0]}
    parameter int FIFO_ADDR_MSB = 63;
    parameter int FIFO_ADDR_LSB = 32;
    parameter int FIFO_DATA_MSB = 31;
    parameter int FIFO_DATA_LSB = 0;

    typedef enum logic [1:0] {
        SEL_FAC     = 2'b00,
        SEL_WIFI    = 2'b01,
        SEL_BT      = 2'b10,
        SEL_INVALID = 2'b11
    } sel_e;

    typedef enum logic [1:0] {
        STATUS_IDLE    = 2'b00,
        STATUS_WRITING = 2'b01,
        STATUS_READING = 2'b10,
        STATUS_ERROR   = 2'b11
    } mem_status_e;

    typedef enum logic [1:0] {
        BT_IDLE  = 2'd0,
        BT_BEAT1 = 2'd1,
        BT_BEAT2 = 2'd2
    } bt_split_state_e;

endpackage
