class fac_monitor extends uvm_monitor;

    virtual fac_if vif;
    uvm_analysis_port #(fac_seq_item) ap;

    `uvm_component_utils(fac_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fac_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "FAC virtual interface not set")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fac_seq_item beat;
        bit [31:0]  burst_addr;
        bit         in_burst;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.wr_en && vif.mon_cb.data_valid && vif.mon_cb.ready) begin
                beat = fac_seq_item::type_id::create("beat");
                beat.beat_count = 1;
                beat.data         = new[1];

                if (!in_burst) begin
                    burst_addr      = vif.mon_cb.start_addr;
                    beat.start_addr = burst_addr;
                    in_burst        = 1'b1;
                end else begin
                    beat.start_addr = burst_addr;
                end

                beat.data[0] = vif.mon_cb.data;
                ap.write(beat);

                burst_addr += 32'd1;
            end else if (!vif.mon_cb.wr_en || !vif.mon_cb.data_valid) begin
                in_burst = 1'b0;
            end
        end
    endtask

endclass
