// Detect wrong-address reads: each cell gets a unique address-tagged signature.
// If RTL returns data from address B while A was read, scoreboard flags aliasing.

class test_addr_signature extends shared_memory_base_test;

    virtual ctrl_if ctrl_vif;

    localparam int unsigned FILL_WORDS = 8;
    localparam bit [31:0]   FAC_BASE    = 32'h40;
    localparam bit [31:0]   WIFI_BASE   = 32'h100;
    localparam bit [31:0]   BT_BASE     = 32'h600;

    `uvm_component_utils(test_addr_signature)

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

    task automatic fac_write_sig(bit [31:0] addr);
        fac_write_word_seq fac_seq;

        fac_seq = fac_write_word_seq::type_id::create($sformatf("fac_wr_0x%0h", addr));
        if (!fac_seq.randomize() with {
            this.addr == local::addr;
            this.data == shared_memory_base_test::addr_signature(local::addr);
        }) begin
            `uvm_fatal("RAND", "fac_write_word_seq randomize failed")
        end
        fac_seq.start(env.fac_agent.sqr);
        wait_idle($sformatf("fac_idle_0x%0h", addr));
        repeat (50) @(ctrl_vif.mon_cb);
    endtask

    task automatic read_check_sig(bit [31:0] addr);
        read_word_seq read_seq;

        read_seq = read_word_seq::type_id::create($sformatf("read_0x%0h", addr));
        read_seq.addr = addr;
        read_seq.start(env.read_agent.sqr);
        wait_idle($sformatf("read_idle_0x%0h", addr));
        repeat (50) @(ctrl_vif.mon_cb);
    endtask

    task automatic fill_fac_block();
        int unsigned i;

        `uvm_info("TEST", $sformatf(
            "Fill FAC block 0x%08h..0x%08h with address signatures",
            FAC_BASE, FAC_BASE + FILL_WORDS - 1
        ), UVM_LOW)

        select_if(SEL_FAC);
        for (i = 0; i < FILL_WORDS; i++) begin
            fac_write_sig(FAC_BASE + i);
        end
    endtask

    task automatic verify_fac_reads();
        int unsigned order[$];
        int unsigned i;

        order.push_back(3);
        order.push_back(0);
        order.push_back(7);
        order.push_back(1);
        order.push_back(5);
        order.push_back(2);
        order.push_back(6);
        order.push_back(4);

        `uvm_info("TEST", "Read FAC block in non-sequential order (aliasing check)", UVM_LOW)
        foreach (order[i]) begin
            read_check_sig(FAC_BASE + order[i]);
        end
    endtask

    task automatic verify_wifi_split_signatures();
        wifi_write_word_seq wifi_seq;
        read_word_seq       read_seq;
        bit [31:0]          lo_addr;
        bit [31:0]          hi_addr;
        bit [63:0]          wifi_data;

        lo_addr = WIFI_BASE;
        hi_addr = WIFI_BASE + 32'd1;
        wifi_data = {addr_signature(hi_addr), addr_signature(lo_addr)};

        `uvm_info("TEST", $sformatf(
            "WiFi split @ 0x%08h: lo=0x%08h hi=0x%08h",
            lo_addr, addr_signature(lo_addr), addr_signature(hi_addr)
        ), UVM_LOW)

        select_if(SEL_WIFI);
        wifi_seq = wifi_write_word_seq::type_id::create("wifi_sig");
        if (!wifi_seq.randomize() with {
            addr == local::lo_addr;
            data == local::wifi_data;
        }) begin
            `uvm_fatal("RAND", "wifi_write_word_seq randomize failed")
        end
        wifi_seq.start(env.wifi_agent.sqr);
        wait_idle("wifi_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        read_seq = read_word_seq::type_id::create("wifi_read_lo");
        read_seq.addr = lo_addr;
        read_seq.start(env.read_agent.sqr);
        wait_idle("wifi_read_lo_idle");

        read_seq = read_word_seq::type_id::create("wifi_read_hi");
        read_seq.addr = hi_addr;
        read_seq.start(env.read_agent.sqr);
        wait_idle("wifi_read_hi_idle");
    endtask

    task automatic verify_bt_split_signatures();
        bt_write_word_seq bt_seq;
        read_word_seq     read_seq;
        bit [31:0]        base;
        bit [95:0]        bt_data;
        int unsigned      i;

        base = BT_BASE;
        bt_data = {
            addr_signature(base + 2),
            addr_signature(base + 1),
            addr_signature(base)
        };

        `uvm_info("TEST", $sformatf(
            "BT split @ 0x%08h..0x%08h with per-word signatures",
            base, base + 2
        ), UVM_LOW)

        select_if(SEL_BT);
        bt_seq = bt_write_word_seq::type_id::create("bt_sig");
        if (!bt_seq.randomize() with {
            addr == local::base;
            data == local::bt_data;
        }) begin
            `uvm_fatal("RAND", "bt_write_word_seq randomize failed")
        end
        bt_seq.start(env.bt_agent.sqr);
        wait_idle("bt_idle");
        repeat (100) @(ctrl_vif.mon_cb);

        for (i = 0; i < 3; i++) begin
            read_seq = read_word_seq::type_id::create($sformatf("bt_read_%0d", i));
            read_seq.addr = base + i;
            read_seq.start(env.read_agent.sqr);
            wait_idle($sformatf("bt_read_idle_%0d", i));
        end
    endtask

    task run_phase(uvm_phase phase);
        int unsigned errors_at_start;

        errors_at_start = uvm_report_server::get_server().get_severity_count(UVM_ERROR);

        phase.raise_objection(this);

        `uvm_info("TEST", "test_addr_signature: unique per-address data to catch wrong-address reads", UVM_LOW)

        fill_fac_block();
        verify_fac_reads();
        verify_wifi_split_signatures();
        verify_bt_split_signatures();

        check_pass("test_addr_signature", errors_at_start);

        phase.drop_objection(this);
    endtask

endclass
