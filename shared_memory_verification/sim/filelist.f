# RTL sources (shared_memory_pkg must come first for package definitions)
rtl/shared_memory_pkg.sv
rtl/shared_memory_defs.svh
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
tb/interfaces/ctrl_if.sv
tb/agents/fac/fac_if.sv
tb/agents/wifi/wifi_if.sv
tb/agents/bt/bt_if.sv
tb/agents/read/read_if.sv

# TB FAC agent (package must come first)
tb/agents/fac/fac_seq_item.sv
tb/agents/fac/fac_if.sv
tb/agents/fac/fac_driver.sv
tb/agents/fac/fac_monitor.sv
tb/agents/fac/fac_sequencer.sv
tb/agents/fac/fac_agent.sv
tb/agents/fac/fac_agent_pkg.sv

# TB WiFi agent
tb/agents/wifi/wifi_seq_item.sv
tb/agents/wifi/wifi_if.sv
tb/agents/wifi/wifi_driver.sv
tb/agents/wifi/wifi_monitor.sv
tb/agents/wifi/wifi_sequencer.sv
tb/agents/wifi/wifi_agent.sv
tb/agents/wifi/wifi_agent_pkg.sv

# TB BT agent
tb/agents/bt/bt_seq_item.sv
tb/agents/bt/bt_if.sv
tb/agents/bt/bt_driver.sv
tb/agents/bt/bt_monitor.sv
tb/agents/bt/bt_sequencer.sv
tb/agents/bt/bt_agent.sv
tb/agents/bt/bt_agent_pkg.sv

# TB Read agent
tb/agents/read/read_seq_item.sv
tb/agents/read/read_if.sv
tb/agents/read/read_driver.sv
tb/agents/read/read_monitor.sv
tb/agents/read/read_sequencer.sv
tb/agents/read/read_agent.sv
tb/agents/read/read_agent_pkg.sv

# TB environment (cfg before env, env before pkg)
tb/envs/shared_memory_env_cfg.sv
tb/envs/shared_memory_scoreboard.sv
tb/envs/shared_memory_env.sv
tb/envs/shared_memory_env_pkg.sv

# TB sequences
tb/seqs/fac_seq_pkg.sv
tb/seqs/wifi_seq_pkg.sv
tb/seqs/bt_seq_pkg.sv
tb/seqs/read_seq_pkg.sv
tb/seqs/common_seq_pkg.sv

# TB tests (base test first)
tb/tests/shared_memory_test_pkg.sv

# TB top (testbench must come last)
tb/top/shared_memory_tb.sv
