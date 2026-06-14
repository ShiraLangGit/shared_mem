// Control / status virtual interface — mem_clk domain
//
// interface_select : driven by testbench → DUT input
// memory_status    : monitored from DUT  → IDLE(00), WRITING(01), READING(10), ERROR(11)

interface ctrl_if (input logic clk);
    logic        rst_n;
    logic [1:0]  interface_select;  // TB → DUT
    logic [1:0]  memory_status;     // DUT → TB

    // Drive interface_select; sample memory_status one step after posedge
    clocking drv_cb @(posedge clk);
        default input #1step output negedge;
        output interface_select;
        input  memory_status;
    endclocking

    // Synchronous monitor — sample both DUT-facing signals after posedge
    clocking mon_cb @(posedge clk);
        default input #1step;
        input interface_select, memory_status;
    endclocking

    // Decode helpers (encoding from shared_memory_pkg::mem_status_e)
    function automatic bit is_idle();
        return memory_status == 2'b00;
    endfunction

    function automatic bit is_writing();
        return memory_status == 2'b01;
    endfunction

    function automatic bit is_reading();
        return memory_status == 2'b10;
    endfunction

    function automatic bit is_error();
        return memory_status == 2'b11;
    endfunction
endinterface
