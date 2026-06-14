class wait_idle_seq extends uvm_sequence;

    virtual ctrl_if ctrl_vif;

    `uvm_object_utils(wait_idle_seq)

    function new(string name = "wait_idle_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not found in config_db for wait_idle_seq")
        end

        `uvm_info("COMMON_SEQ", "Waiting for memory_status == IDLE", UVM_MEDIUM)

        @(ctrl_vif.mon_cb);
        while (ctrl_vif.mon_cb.memory_status != STATUS_IDLE) begin
            if (ctrl_vif.mon_cb.memory_status == STATUS_ERROR) begin
                `uvm_fatal("WAIT_IDLE", "memory_status entered ERROR while waiting for IDLE")
            end
            @(ctrl_vif.mon_cb);
        end

        `uvm_info("COMMON_SEQ", "memory_status is IDLE", UVM_MEDIUM)
    endtask

endclass
