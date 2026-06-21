class wifi_driver extends uvm_driver #(wifi_seq_item);

    virtual wifi_if vif;

    `uvm_component_utils(wifi_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wifi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "WiFi virtual interface not set")
        end
    endfunction

    task automatic reset_signals();
        @(posedge vif.clk);
        vif.wr_en      = 1'b0;
        vif.data_valid = 1'b0;
        vif.start_addr = '0;
        vif.data       = '0;
    endtask

    task automatic wait_for_ready();
        @(posedge vif.clk);
        while (!vif.ready) begin
            @(posedge vif.clk);
        end
    endtask

    // Drive with blocking assigns at negedge so addr/data are stable at the
    // next posedge where wifi_write_if accept samples them.
    task drive_item(wifi_seq_item req);
        `uvm_info("WIFI_DRV", $sformatf(
            "Driving start_addr=0x%08h data=0x%016h beat_count=2 (LE split)",
            req.start_addr, req.data
        ), UVM_MEDIUM)

        wait_for_ready();

        @(negedge vif.clk);
        vif.wr_en      = 1'b1;
        vif.data_valid = 1'b1;
        vif.start_addr = req.start_addr;
        vif.data       = req.data;

        do @(posedge vif.clk); while (!vif.ready);

        @(negedge vif.clk);
        vif.wr_en      = 1'b0;
        vif.data_valid = 1'b0;
    endtask

    task run_phase(uvm_phase phase);
        reset_signals();
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

endclass
