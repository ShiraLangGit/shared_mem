class bt_monitor extends uvm_monitor;

    virtual bt_if vif;
    uvm_analysis_port #(bt_seq_item) ap;

    `uvm_component_utils(bt_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual bt_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "BT virtual interface not set")
        end
    endfunction

    task run_phase(uvm_phase phase);
        bt_seq_item txn;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.wr_en && vif.mon_cb.data_valid && vif.mon_cb.ready) begin
                txn = bt_seq_item::type_id::create("txn");
                txn.start_addr = vif.mon_cb.start_addr;
                txn.data       = vif.mon_cb.data;
                txn.beat_count = 3;
                ap.write(txn);
            end
        end
    endtask

endclass
