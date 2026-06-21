class test_sanity_fac extends shared_memory_base_test;

    virtual ctrl_if ctrl_vif;

    `uvm_component_utils(test_sanity_fac)

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
        fac_write_word_seq   fac_seq;
        wait_idle_seq        idle_seq;
        read_word_seq        read_seq;
        int unsigned         errors_at_start;

        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_sanity_fac: FAC write + readback @ 0x10", UVM_LOW)

        sel_seq = select_interface_seq::type_id::create("sel_seq");
        if (!sel_seq.randomize() with { sel == SEL_FAC; }) begin
            `uvm_fatal("RAND", "select_interface_seq randomize failed")
        end
        sel_seq.start(null);

        repeat (200) @(ctrl_vif.mon_cb);

        fac_seq = fac_write_word_seq::type_id::create("fac_seq");
        fac_seq.addr = 32'h10;
        fac_seq.data = 32'hA5A5_5A5A;
        fac_seq.start(env.fac_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq");
        idle_seq.start(null);

        repeat (100) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("read_seq");
        read_seq.addr = 32'h10;
        read_seq.start(env.read_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq2");
        idle_seq.start(null);

        check_pass("test_sanity_fac", errors_at_start);

        phase.drop_objection(this);
    endtask

endclass
