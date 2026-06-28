class error_clear_seq extends uvm_sequence;

    virtual ctrl_if ctrl_vif;

    `uvm_object_utils(error_clear_seq)

    function new(string name = "error_clear_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db#(virtual ctrl_if)::get(null, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not found for error_clear_seq")
        end

        `uvm_info("COMMON_SEQ", "Waiting for memory_status to leave ERROR", UVM_MEDIUM)
        do @(ctrl_vif.mon_cb); while (ctrl_vif.is_error());
        `uvm_info("COMMON_SEQ", "memory_status cleared ERROR", UVM_MEDIUM)
    endtask

endclass
