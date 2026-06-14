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

    task automatic wait_mem_idle();
        @(ctrl_vif.mon_cb);
        while (ctrl_vif.mon_cb.memory_status != STATUS_IDLE) begin
            @(ctrl_vif.mon_cb);
        end
    endtask

    task run_phase(uvm_phase phase);
        fac_write_word_seq fac_seq;
        read_word_seq      read_seq;
        int unsigned       errors_at_start;

        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_sanity_fac: FAC write + readback @ 0x10", UVM_LOW)

        fac_seq = fac_write_word_seq::type_id::create("fac_seq");
        fac_seq.addr = 32'h10;
        fac_seq.data = 32'hA5A5_5A5A;
        fac_seq.start(env.fac_agent.sqr);

        wait_mem_idle();
        repeat (20) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("read_seq");
        read_seq.addr = 32'h10;
        read_seq.start(env.read_agent.sqr);

        wait_mem_idle();
        repeat (10) @(ctrl_vif.mon_cb);

        if (env.scoreboard.get_mismatch_count() != 0) begin
            `uvm_error("TEST", $sformatf(
                "Scoreboard reported %0d mismatch(es)", env.scoreboard.get_mismatch_count()
            ))
        end else begin
            `uvm_info("TEST", "Scoreboard reports no mismatches — PASS", UVM_LOW)
        end

        if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) > errors_at_start) begin
            `uvm_error("TEST", "Unexpected UVM_ERROR(s) during test_sanity_fac")
        end

        phase.drop_objection(this);
    endtask

endclass
