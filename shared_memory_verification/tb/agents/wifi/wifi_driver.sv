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
        @(vif.drv_cb);
        vif.drv_cb.wr_en      <= 1'b0;
        vif.drv_cb.data_valid <= 1'b0;
        vif.drv_cb.start_addr <= '0;
        vif.drv_cb.data       <= '0;
    endtask

    task automatic wait_for_ready();
        @(vif.drv_cb);
        while (!vif.drv_cb.ready) begin
            @(vif.drv_cb);
        end
    endtask

    // WiFi 64-bit LE split (wifi_write_if RTL):
    //   accept cycle  — wr_en/data_valid while ready; DUT latches addr/data
    //   next cycles   — DUT auto-pushes beat0/beat1; hold wr_en until ready again
    task drive_item(wifi_seq_item req);
        `uvm_info("WIFI_DRV", $sformatf("Driving %s", req.convert2string()), UVM_MEDIUM)

        wait_for_ready();

        vif.drv_cb.wr_en      <= 1'b1;
        vif.drv_cb.data_valid <= 1'b1;
        vif.drv_cb.start_addr <= req.start_addr;
        vif.drv_cb.data       <= req.data;
        @(vif.drv_cb);

        while (!vif.drv_cb.ready) begin
            @(vif.drv_cb);
        end

        vif.drv_cb.wr_en      <= 1'b0;
        vif.drv_cb.data_valid <= 1'b0;
        @(vif.drv_cb);
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
