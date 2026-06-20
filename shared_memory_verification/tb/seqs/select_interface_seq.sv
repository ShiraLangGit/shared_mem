class select_interface_seq extends uvm_sequence;

    rand sel_e sel;

    virtual ctrl_if ctrl_vif;

    constraint sel_c {
        sel inside {SEL_FAC, SEL_WIFI, SEL_BT};
    }

    `uvm_object_utils(select_interface_seq)

    function new(string name = "select_interface_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db#(virtual ctrl_if)::get(null, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not found in config_db for select_interface_seq")
        end

        `uvm_info("COMMON_SEQ", $sformatf("Selecting interface %0d", sel), UVM_MEDIUM)

        @(ctrl_vif.drv_cb);
        ctrl_vif.drv_cb.interface_select <= sel;
        @(ctrl_vif.drv_cb);
        
        // Critical CDC margin: interface_select goes from mem_clk to 3 write clock domains
        // (fac_clk @ 80MHz, wifi_clk @ 120MHz, bt_clk @ 28MHz)
        // Each domain has 2 FF stages (fac_sel_s1/s2, wifi_sel_s1/s2, bt_sel_s1/s2)
        // Slowest is BT @ 28MHz = 35.7ns/cycle
        // Need 3-4 cycles per domain = ~143 ns minimum
        // mem_clk @ 80MHz = 12.5ns per cycle
        // 200 cycles * 12.5ns = 2.5us - VERY safe margin
        repeat (200) @(ctrl_vif.mon_cb);
        
        `uvm_info("COMMON_SEQ", $sformatf("Interface select %0d is now synchronized to all clock domains", sel), UVM_HIGH)
    endtask

endclass
