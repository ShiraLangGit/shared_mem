package shared_memory_env_pkg;

    import uvm_pkg::*;
    import shared_memory_pkg::*;
    import fac_agent_pkg::*;
    import wifi_agent_pkg::*;
    import bt_agent_pkg::*;
    import read_agent_pkg::*;
    `include "uvm_macros.svh"

    `include "shared_memory_env_cfg.sv"
    `include "shared_memory_scoreboard.sv"
    `include "shared_memory_coverage.sv"
    `include "shared_memory_env.sv"

endpackage
