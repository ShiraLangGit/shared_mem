class read_driver extends uvm_driver #(read_seq_item);

    virtual read_if vif;

    `uvm_component_utils(read_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual read_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Read virtual interface not set")
        end
    endfunction

    task automatic reset_signals();
        @(vif.drv_cb);
        vif.drv_cb.rd_en <= 1'b0;
        vif.drv_cb.addr  <= '0;
    endtask

    task automatic wait_for_ready();
        @(vif.drv_cb);
        while (!vif.drv_cb.ready) begin
            @(vif.drv_cb);
        end
    endtask

    // read_ctrl RTL: assert o_rd_en for one mem_clk per beat; addr auto-increments in burst.
    task automatic drive_beat(
        input bit [31:0] beat_addr,
        input bit        is_first_beat
    );
        wait_for_ready();

        vif.drv_cb.rd_en <= 1'b1;
        if (is_first_beat) begin
            vif.drv_cb.addr <= beat_addr;
        end
        @(vif.drv_cb);
    endtask

    task drive_item(read_seq_item req);
        int unsigned i;

        `uvm_info("READ_DRV", $sformatf("Driving read %s", req.convert2string()), UVM_MEDIUM)

        for (i = 0; i < req.beat_count; i++) begin
            drive_beat(req.addr + i, (i == 0));
        end

        @(vif.drv_cb);
        vif.drv_cb.rd_en <= 1'b0;
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
