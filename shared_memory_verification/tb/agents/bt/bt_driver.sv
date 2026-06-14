class bt_driver extends uvm_driver #(bt_seq_item);

    virtual bt_if vif;

    `uvm_component_utils(bt_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual bt_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "BT virtual interface not set")
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

    // Wait until DUT FSM returns to BT_IDLE after beats 1 and 2
    task automatic wait_for_split_complete();
        @(vif.drv_cb);
        while (!vif.drv_cb.ready) begin
            @(vif.drv_cb);
        end
    endtask

    // BT 96-bit LE split (bt_write_if RTL):
    //   Beat 0 @ start_addr     ← data[31:0]
    //   Beat 1 @ start_addr + 1 ← data[63:32]  — DUT auto-pushes in BT_BEAT1
    //   Beat 2 @ start_addr + 2 ← data[95:64]  — DUT auto-pushes in BT_BEAT2
    task automatic drive_le_beat_0(bt_seq_item req);
        wait_for_ready();

        vif.drv_cb.wr_en      <= 1'b1;
        vif.drv_cb.data_valid <= 1'b1;
        vif.drv_cb.start_addr <= req.start_addr;
        vif.drv_cb.data       <= req.data;
        @(vif.drv_cb);
    endtask

    task drive_item(bt_seq_item req);
        `uvm_info("BT_DRV", $sformatf("Driving %s", req.convert2string()), UVM_MEDIUM)

        drive_le_beat_0(req);

        @(vif.drv_cb);
        vif.drv_cb.wr_en      <= 1'b0;
        vif.drv_cb.data_valid <= 1'b0;

        wait_for_split_complete();
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
