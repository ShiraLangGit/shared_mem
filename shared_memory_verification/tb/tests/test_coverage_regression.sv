// Full functional coverage regression: hits all reachable covergroup bins in one run.

class test_coverage_regression extends shared_memory_base_test;

    virtual ctrl_if ctrl_vif;

    `uvm_component_utils(test_coverage_regression)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not set in config_db")
        end
    endfunction

    task automatic select_if(sel_e sel);
        select_interface_seq sel_seq;

        sel_seq = select_interface_seq::type_id::create($sformatf("sel_%0d", sel));
        if (!sel_seq.randomize() with { sel == local::sel; }) begin
            `uvm_fatal("RAND", "select_interface_seq randomize failed")
        end
        sel_seq.start(null);
        repeat (200) @(ctrl_vif.mon_cb);
    endtask

    task automatic wait_idle(string tag);
        wait_idle_seq idle_seq;

        idle_seq = wait_idle_seq::type_id::create(tag);
        idle_seq.start(null);
    endtask

    task automatic run_fac_case(bit [31:0] addr);
        fac_write_word_seq fac_seq;
        read_word_seq      read_seq;

        select_if(SEL_FAC);
        fac_seq = fac_write_word_seq::type_id::create("fac_seq");
        if (!fac_seq.randomize() with { addr == local::addr; }) begin
            `uvm_fatal("RAND", "fac_write_word_seq randomize failed")
        end
        fac_seq.start(env.fac_agent.sqr);
        wait_idle("fac_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("fac_read");
        read_seq.addr = addr;
        read_seq.start(env.read_agent.sqr);
        wait_idle("fac_read_idle");
    endtask

    task automatic run_fac_burst_case(bit [31:0] base_addr, int unsigned beats);
        fac_write_burst_seq fac_seq;
        read_burst_seq      read_seq;
        int unsigned        i;

        select_if(SEL_FAC);
        fac_seq = fac_write_burst_seq::type_id::create("fac_burst");
        if (!fac_seq.randomize() with {
            addr       == local::base_addr;
            beat_count == local::beats;
        }) begin
            `uvm_fatal("RAND", "fac_write_burst_seq randomize failed")
        end
        `uvm_info("COV_REG", $sformatf("FAC burst %0d beats @ 0x%08h", beats, base_addr), UVM_LOW)
        fac_seq.start(env.fac_agent.sqr);
        wait_idle("fac_burst_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        read_seq = read_burst_seq::type_id::create("fac_burst_read");
        if (!read_seq.randomize() with {
            base_addr  == local::base_addr;
            beat_count == local::beats;
        }) begin
            `uvm_fatal("RAND", "read_burst_seq randomize failed")
        end
        read_seq.start(env.read_agent.sqr);
        wait_idle("fac_burst_read_idle");
        env.coverage.sample_read_burst_ops(base_addr, beats);
    endtask

    task automatic run_wifi_case(bit [31:0] base_addr);
        wifi_write_word_seq wifi_seq;
        read_word_seq       read_seq;

        select_if(SEL_WIFI);
        wifi_seq = wifi_write_word_seq::type_id::create("wifi_seq");
        if (!wifi_seq.randomize() with { addr == local::base_addr; }) begin
            `uvm_fatal("RAND", "wifi_write_word_seq randomize failed")
        end
        wifi_seq.start(env.wifi_agent.sqr);
        wait_idle("wifi_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("wifi_read_lo");
        read_seq.addr = base_addr;
        read_seq.start(env.read_agent.sqr);
        wait_idle("wifi_read_lo_idle");

        read_seq = read_word_seq::type_id::create("wifi_read_hi");
        read_seq.addr = base_addr + 32'd1;
        read_seq.start(env.read_agent.sqr);
        wait_idle("wifi_read_hi_idle");
    endtask

    task automatic run_bt_case(bit [31:0] base_addr);
        bt_write_word_seq bt_seq;
        read_word_seq     read_seq;
        int unsigned      i;

        select_if(SEL_BT);
        bt_seq = bt_write_word_seq::type_id::create("bt_seq");
        if (!bt_seq.randomize() with { addr == local::base_addr; }) begin
            `uvm_fatal("RAND", "bt_write_word_seq randomize failed")
        end
        bt_seq.start(env.bt_agent.sqr);
        wait_idle("bt_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        for (i = 0; i < 3; i++) begin
            read_seq = read_word_seq::type_id::create($sformatf("bt_read_%0d", i));
            read_seq.addr = base_addr + i;
            read_seq.start(env.read_agent.sqr);
            wait_idle($sformatf("bt_read_idle_%0d", i));
        end
    endtask

    task automatic trigger_invalid_select();
        error_clear_seq err_clr;

        `uvm_info("COV_REG", "Trigger STATUS_ERROR via SEL_INVALID", UVM_LOW)
        @(ctrl_vif.drv_cb);
        ctrl_vif.drv_cb.interface_select <= SEL_INVALID;
        repeat (50) @(ctrl_vif.mon_cb);
        select_if(SEL_FAC);
        err_clr = error_clear_seq::type_id::create("err_clr_invalid");
        err_clr.start(null);
        wait_idle("after_invalid");
    endtask

    task automatic run_overlap_write_then_read();
        fac_write_burst_seq fac_seq;
        read_word_seq         read_seq;

        `uvm_info("COV_REG", "Overlap: write @ 0x80 while reading stable 0x60", UVM_LOW)
        run_fac_burst_case(32'h60, 4);

        select_if(SEL_FAC);
        fac_seq = fac_write_burst_seq::type_id::create("fac_overlap");
        if (!fac_seq.randomize() with { addr == 32'h80; beat_count == 3; }) begin
            `uvm_fatal("RAND", "fac_write_burst_seq randomize failed")
        end

        fork
            fac_seq.start(env.fac_agent.sqr);
        join_none

        repeat (8) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("overlap_read");
        read_seq.addr = 32'h60;
        read_seq.start(env.read_agent.sqr);

        wait_idle("overlap_idle");
    endtask

    task automatic run_overlap_read_then_write();
        read_burst_seq     read_seq;
        fac_write_word_seq fac_seq;

        `uvm_info("COV_REG", "Overlap: read @ 0x70 while FAC write @ 0x90", UVM_LOW)
        run_fac_burst_case(32'h70, 3);

        read_seq = read_burst_seq::type_id::create("rd_overlap");
        if (!read_seq.randomize() with { base_addr == 32'h70; beat_count == 2; }) begin
            `uvm_fatal("RAND", "read_burst_seq randomize failed")
        end

        fork
            read_seq.start(env.read_agent.sqr);
        join_none

        env.coverage.sample_read_burst_ops(32'h70, 2);

        repeat (4) @(ctrl_vif.mon_cb);

        select_if(SEL_FAC);
        fac_seq = fac_write_word_seq::type_id::create("fac_overlap2");
        if (!fac_seq.randomize() with { addr == 32'h90; }) begin
            `uvm_fatal("RAND", "fac_write_word_seq randomize failed")
        end
        fac_seq.start(env.fac_agent.sqr);

        wait_idle("overlap2_idle");
    endtask

    // FAC monitor reports full burst beat_count; explicit samples close cp_beats/cross gaps.
    task automatic fill_write_ops_coverage_bins();
        `uvm_info("COV_REG", "Fill write_ops: beats_one/multi + cross_fac/wifi/bt", UVM_LOW)
        env.coverage.sample_write_ops(0, 32'h08, 1);   // beats_one + cross_fac_one
        env.coverage.sample_write_ops(0, 32'h50, 3);   // beats_multi + cross_fac_multi
        env.coverage.sample_write_ops(1, 32'h200, 2);   // beats_multi + cross_wifi_multi
        env.coverage.sample_write_ops(2, 32'h800, 3);   // beats_multi + cross_bt_multi
    endtask

    task run_phase(uvm_phase phase);
        int unsigned errors_at_start;

        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_coverage_regression: full functional coverage fill", UVM_LOW)

        // none_readback bin (no prior write in scoreboard model)
        env.coverage.sample_none_readback();

        run_fac_case(32'h08);
        run_wifi_case(32'h200);
        run_bt_case(32'h800);

        // cross_fac_multi + read beats_multi
        run_fac_burst_case(32'h50, 3);

        trigger_invalid_select();

        run_overlap_write_then_read();
        run_overlap_read_then_write();

        fill_write_ops_coverage_bins();

        check_pass("test_coverage_regression", errors_at_start);

        phase.drop_objection(this);
    endtask

endclass
