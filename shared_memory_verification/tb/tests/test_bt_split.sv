class test_bt_split extends shared_memory_base_test;

    virtual ctrl_if ctrl_vif;

    `uvm_component_utils(test_bt_split)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not set in config_db")
        end
    endfunction

    task automatic check_pass(string test_name, int unsigned errors_at_start);
        repeat (10) @(ctrl_vif.mon_cb);

        if (env.scoreboard.get_mismatch_count() != 0) begin
            `uvm_error("TEST", $sformatf(
                "%s: scoreboard reported %0d mismatch(es)",
                test_name, env.scoreboard.get_mismatch_count()
            ))
        end else begin
            `uvm_info("TEST", $sformatf("%s: scoreboard reports no mismatches - PASS", test_name), UVM_LOW)
        end

        if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) > errors_at_start) begin
            `uvm_error("TEST", $sformatf("Unexpected UVM_ERROR(s) during %s", test_name))
        end
    endtask

    task run_phase(uvm_phase phase);
        select_interface_seq sel_seq;
        bt_write_word_seq    bt_seq;
        wait_idle_seq        idle_seq;
        read_word_seq        read_seq;
        int unsigned         errors_at_start;
        bit [31:0]           base_addr;
        int unsigned         i;

        base_addr       = 32'h50;
        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_bt_split: 96b BT LE split -> 3x32b readback", UVM_LOW)

        // CRITICAL: Must set interface_select FIRST, before any write activity
        // Interface_select is in mem_clk, but must propagate through CDC (3-4 cycles)
        // to bt_sel_s2 in bt_clk domain. If beats are pushed before interface_select
        // becomes SEL_BT, they go to the WRONG FIFO (FAC instead of BT)!
        sel_seq = select_interface_seq::type_id::create("sel_seq");
        if (!sel_seq.randomize() with { sel == SEL_BT; }) begin
            `uvm_fatal("RAND", "select_interface_seq randomize failed")
        end
        sel_seq.start(null);
        
        // Wait extra margin to ensure bt_sel_s2 has settled on SEL_BT
        // Worst case: BT @ 28MHz is slowest write clock
        // Need ~3-4 cycles per clock domain for FF chains
        repeat (200) @(ctrl_vif.mon_cb);

        bt_seq = bt_write_word_seq::type_id::create("bt_seq");
        bt_seq.addr = base_addr;
        bt_seq.data = 96'h1122_3344_5566_7788_99AA_BBCC;
        bt_seq.start(env.bt_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq");
        idle_seq.start(null);
        
        // CRITICAL: Extra delay after write completes to ensure:
        // 1. All BT beats have exited the FIFO and been written to RAM
        // 2. Dual-port RAM write is complete (at least 1 cycle after write_ctrl sets wr_en)
        // 3. Sufficient margin for CDC synchronization back through read side
        repeat (100) @(ctrl_vif.mon_cb);

        for (i = 0; i < 3; i++) begin
            read_seq = read_word_seq::type_id::create($sformatf("read_%0d", i));
            read_seq.addr = base_addr + i;
            read_seq.start(env.read_agent.sqr);

            idle_seq = wait_idle_seq::type_id::create($sformatf("idle_%0d", i));
            idle_seq.start(null);
        end

        check_pass("test_bt_split", errors_at_start);

        phase.drop_objection(this);
    endtask

endclass
