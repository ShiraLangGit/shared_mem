# RTL sources
rtl/shared_memory_pkg.sv
rtl/dual_port_ram.sv
rtl/async_fifo.sv
rtl/fac_write_if.sv
rtl/wifi_write_if.sv
rtl/bt_write_if.sv
rtl/interface_mux.sv
rtl/write_ctrl.sv
rtl/read_ctrl.sv
rtl/mem_status_ctrl.sv
rtl/shared_memory.sv

# TB interfaces
tb/agents/ctrl/ctrl_if.sv
tb/agents/fac/fac_if.sv
tb/agents/wifi/wifi_if.sv
tb/agents/bt/bt_if.sv
tb/agents/read/read_if.sv

# TB agent packages
tb/agents/fac/fac_agent_pkg.sv
tb/agents/wifi/wifi_agent_pkg.sv
tb/agents/bt/bt_agent_pkg.sv
tb/agents/read/read_agent_pkg.sv

# TB environment
tb/envs/shared_memory_env_pkg.sv

# TB sequences
tb/seqs/fac_seq_pkg.sv
tb/seqs/wifi_seq_pkg.sv
tb/seqs/bt_seq_pkg.sv
tb/seqs/read_seq_pkg.sv
tb/seqs/common_seq_pkg.sv

# TB tests
tb/tests/shared_memory_test_pkg.sv

# TB top
tb/top/shared_memory_tb.sv
