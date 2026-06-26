package shared_memory_test_pkg;

    import uvm_pkg::*;
    import shared_memory_pkg::*;
    import shared_memory_env_pkg::*;
    import fac_seq_pkg::*;
    import wifi_seq_pkg::*;
    import bt_seq_pkg::*;
    import read_seq_pkg::*;
    import common_seq_pkg::*;
    `include "uvm_macros.svh"

    `include "shared_memory_base_test.sv"
    `include "test_sanity_fac.sv"
    `include "test_wifi_split.sv"
    `include "test_bt_split.sv"
    `include "test_coverage_regression.sv"
    `include "test_addr_signature.sv"

endpackage
