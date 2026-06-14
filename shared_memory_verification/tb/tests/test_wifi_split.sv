class test_wifi_split extends shared_memory_base_test;

    virtual ctrl_if ctrl_vif;

    `uvm_component_utils(test_wifi_split)

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
            `uvm_info("TEST", $sformatf("%s: scoreboard reports no mismatches — PASS", test_name), UVM_LOW)
        end

        if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) > errors_at_start) begin
            `uvm_error("TEST", $sformatf("Unexpected UVM_ERROR(s) during %s", test_name))
        end
    endtask

    task run_phase(uvm_phase phase);
        select_interface_seq  sel_seq;
        wifi_write_word_seq   wifi_seq;
        wait_idle_seq         idle_seq;
        read_word_seq         read_seq;
        int unsigned          errors_at_start;
        bit [31:0]            base_addr;

        base_addr       = 32'h30;
        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_wifi_split: 64b WiFi LE split → 2×32b readback", UVM_LOW)

        sel_seq = select_interface_seq::type_id::create("sel_seq");
        if (!sel_seq.randomize() with { sel == SEL_WIFI; }) begin
            `uvm_fatal("RAND", "select_interface_seq randomize failed")
        end
        sel_seq.start(null);

        wifi_seq = wifi_write_word_seq::type_id::create("wifi_seq");
        wifi_seq.addr = base_addr;
        wifi_seq.data = 64'hCAFE_BABE_DEAD_BEEF;
        wifi_seq.start(env.wifi_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq");
        idle_seq.start(null);
        repeat (20) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("read_lo");
        read_seq.addr = base_addr;
        read_seq.start(env.read_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq2");
        idle_seq.start(null);

        read_seq = read_word_seq::type_id::create("read_hi");
        read_seq.addr = base_addr + 32'd1;
        read_seq.start(env.read_agent.sqr);

        idle_seq = wait_idle_seq::type_id::create("idle_seq3");
        idle_seq.start(null);

        check_pass("test_wifi_split", errors_at_start);

        phase.drop_objection(this);
    endtask

endclass
