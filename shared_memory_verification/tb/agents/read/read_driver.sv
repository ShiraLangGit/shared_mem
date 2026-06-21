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
        @(posedge vif.clk);
        vif.rd_en = 1'b0;
        vif.addr  = '0;
    endtask

    task automatic wait_for_ready();
        @(posedge vif.clk);
        while (!vif.ready) begin
            @(posedge vif.clk);
        end
    endtask

    // One-cycle rd_en pulse; monitor handles data sampling (driver does not read data).
    task automatic drive_beat(input bit [31:0] beat_addr);
        wait_for_ready();

        @(negedge vif.clk);
        vif.rd_en = 1'b1;
        vif.addr  = beat_addr;

        @(posedge vif.clk);

        @(negedge vif.clk);
        vif.rd_en = 1'b0;

        // Wait until read_ctrl pipeline completes before next transaction
        do @(posedge vif.clk); while (!vif.data_valid);
        @(posedge vif.clk);
        wait_for_ready();
    endtask

    task drive_item(read_seq_item req);
        int unsigned i;

        `uvm_info("READ_DRV", $sformatf("Driving read %s", req.convert2string()), UVM_MEDIUM)

        for (i = 0; i < req.beat_count; i++) begin
            drive_beat(req.addr + i);
        end
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
