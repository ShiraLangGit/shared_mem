# waves.tcl — SimVision probes
# הרצה: ./sim/run.sh waves [sanity|wifi|bt]

database -open waves/waves -shm -default

# clocks & reset
probe -create shared_memory_tb.mem_clk
probe -create shared_memory_tb.fac_clk
probe -create shared_memory_tb.wifi_clk
probe -create shared_memory_tb.bt_clk
probe -create shared_memory_tb.reset_n

# interfaces
probe -create shared_memory_tb.ctrl_vif  -all -depth 1
probe -create shared_memory_tb.fac_vif   -all -depth 1
probe -create shared_memory_tb.wifi_vif -all -depth 1
probe -create shared_memory_tb.bt_vif    -all -depth 1
probe -create shared_memory_tb.read_vif  -all -depth 1

# RTL internals
probe -create shared_memory_tb.dut.u_write_ctrl       -all -depth 1
probe -create shared_memory_tb.dut.u_read_ctrl        -all -depth 1
probe -create shared_memory_tb.dut.u_dual_port_ram    -all -depth 1
probe -create shared_memory_tb.dut.u_mem_status_ctrl  -all -depth 1
probe -create shared_memory_tb.dut.u_interface_mux    -all -depth 1

run
