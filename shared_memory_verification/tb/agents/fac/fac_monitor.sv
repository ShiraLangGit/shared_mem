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
        fac_seq_item burst;
        bit in_burst;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.wr_en && vif.mon_cb.data_valid && vif.mon_cb.ready) begin
                if (!in_burst) begin
                    burst = fac_seq_item::type_id::create("burst");
                    burst.start_addr = vif.mon_cb.start_addr;
                    burst.beat_count = 1;
                    burst.data       = new[1];
                    burst.data[0]    = vif.mon_cb.data;
                    in_burst         = 1'b1;
                end else begin
                    burst.beat_count++;
                    burst.data = new[burst.beat_count](burst.data);
                    burst.data[burst.beat_count - 1] = vif.mon_cb.data;
                end
            end else if (in_burst && (!vif.mon_cb.wr_en || !vif.mon_cb.data_valid)) begin
                ap.write(burst);
                in_burst = 1'b0;
            end
        end
    endtask

endclass
