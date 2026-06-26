// Consolidated coverage regression: FAC + WiFi + BT in one simulation.

// Exercises all interface_select bins, addr ranges, readback paths, and FSM

// transitions; coverage summary is printed once in report_phase.



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

        `uvm_info("COV_REG", $sformatf(
            "FAC write/read @ 0x%08h data=0x%08h", fac_seq.addr, fac_seq.data
        ), UVM_LOW)

        fac_seq.start(env.fac_agent.sqr);



        wait_idle("fac_idle");

        repeat (100) @(ctrl_vif.mon_cb);



        read_seq = read_word_seq::type_id::create("fac_read");

        read_seq.addr = addr;

        read_seq.start(env.read_agent.sqr);



        wait_idle("fac_read_idle");

    endtask



    task automatic run_wifi_case(bit [31:0] base_addr);

        wifi_write_word_seq wifi_seq;

        read_word_seq       read_seq;



        select_if(SEL_WIFI);



        wifi_seq = wifi_write_word_seq::type_id::create("wifi_seq");

        if (!wifi_seq.randomize() with { addr == local::base_addr; }) begin

            `uvm_fatal("RAND", "wifi_write_word_seq randomize failed")

        end

        `uvm_info("COV_REG", $sformatf(
            "WiFi LE split write/read @ 0x%08h data=0x%016h",
            wifi_seq.addr, wifi_seq.data
        ), UVM_LOW)

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

        `uvm_info("COV_REG", $sformatf(
            "BT LE split write/read @ 0x%08h data=0x%024h",
            bt_seq.addr, bt_seq.data
        ), UVM_LOW)

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



    task run_phase(uvm_phase phase);

        int unsigned errors_at_start;



        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);



        phase.raise_objection(this);



        `uvm_info("TEST", "test_coverage_regression: FAC + WiFi + BT (functional coverage)", UVM_LOW)



        // Fixed addrs for addr_low / addr_mid / addr_high coverage bins; data is random.

        run_fac_case(32'h08);

        run_wifi_case(32'h200);

        run_bt_case(32'h800);



        check_pass("test_coverage_regression", errors_at_start);



        phase.drop_objection(this);

    endtask



endclass

