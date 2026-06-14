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
        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not found in config_db for select_interface_seq")
        end

        `uvm_info("COMMON_SEQ", $sformatf("Selecting interface %0d", sel), UVM_MEDIUM)

        @(ctrl_vif.drv_cb);
        ctrl_vif.drv_cb.interface_select <= sel;
        @(ctrl_vif.drv_cb);
    endtask

endclass
