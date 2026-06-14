class fac_driver extends uvm_driver #(fac_seq_item);

    virtual fac_if vif;

    `uvm_component_utils(fac_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fac_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "FAC virtual interface not set")
        end
    endfunction

    task automatic reset_signals();
        @(vif.drv_cb);
        vif.drv_cb.wr_en       <= 1'b0;
        vif.drv_cb.data_valid  <= 1'b0;
        vif.drv_cb.start_addr  <= '0;
        vif.drv_cb.data        <= '0;
    endtask

    // Two-phase beat handshake per fac_write_if RTL:
    //   Phase 1 — wait until ready (selected && !fifo_full)
    //   Phase 2 — assert wr_en && data_valid for one fac_clk cycle
    task automatic drive_beat(
        input bit [31:0] beat_addr,
        input bit [31:0] beat_data,
        input bit        is_first_beat
    );
        @(vif.drv_cb);
        while (!vif.drv_cb.ready) begin
            @(vif.drv_cb);
        end

        vif.drv_cb.wr_en      <= 1'b1;
        vif.drv_cb.data_valid <= 1'b1;
        if (is_first_beat) begin
            vif.drv_cb.start_addr <= beat_addr;
        end
        vif.drv_cb.data <= beat_data;
        @(vif.drv_cb);
    endtask

    task drive_item(fac_seq_item req);
        int unsigned i;

        `uvm_info("FAC_DRV", $sformatf("Driving %s", req.convert2string()), UVM_MEDIUM)

        for (i = 0; i < req.beat_count; i++) begin
            drive_beat(req.start_addr, req.data[i], (i == 0));
        end

        @(vif.drv_cb);
        vif.drv_cb.wr_en      <= 1'b0;
        vif.drv_cb.data_valid <= 1'b0;
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
