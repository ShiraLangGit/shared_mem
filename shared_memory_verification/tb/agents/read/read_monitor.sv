class read_monitor extends uvm_monitor;

    virtual read_if vif;
    uvm_analysis_port #(read_seq_item) ap;

    `uvm_component_utils(read_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual read_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Read virtual interface not set")
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Pending-address FIFO — one entry per o_rd_en assertion.
        // read_ctrl pipelines o_rd_en through rd_en_d1 and rd_en_d2 (registered delays).
        // o_data_valid is asserted exactly 2 mem_clk cycles after the original o_rd_en.
        //
        //   Cycle N   : o_rd_en=1, capture o_addr  -> push addr onto pending_q
        //   Cycle N+1 : rd_en_d1=1  (internal)
        //   Cycle N+2 : rd_en_d2=1  -> o_data_valid=1, o_data valid; pop addr, emit txn
        bit [31:0] pending_q[$];
        read_seq_item txn;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.rd_en) begin
                pending_q.push_back(vif.mon_cb.addr);
            end

            if (vif.mon_cb.data_valid && pending_q.size() > 0) begin
                txn = read_seq_item::type_id::create("txn");
                txn.addr       = pending_q.pop_front();
                txn.data       = vif.mon_cb.data;
                txn.beat_count = 1;
                ap.write(txn);
            end
        end
    endtask

endclass
