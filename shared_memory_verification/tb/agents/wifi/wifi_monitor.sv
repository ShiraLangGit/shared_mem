class wifi_monitor extends uvm_monitor;

    virtual wifi_if vif;
    uvm_analysis_port #(wifi_seq_item) ap;

    `uvm_component_utils(wifi_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wifi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "WiFi virtual interface not set")
        end
    endfunction

    task run_phase(uvm_phase phase);
        wifi_seq_item txn;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.wr_en && vif.mon_cb.data_valid && vif.mon_cb.ready) begin
                txn = wifi_seq_item::type_id::create("txn");
                txn.start_addr = vif.mon_cb.start_addr;
                txn.data       = vif.mon_cb.data;
                txn.beat_count = 2;
                ap.write(txn);
            end
        end
    endtask

endclass
