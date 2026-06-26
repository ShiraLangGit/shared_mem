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
        bit        rd_en_prev;
        read_seq_item txn;

        forever begin
            @(posedge vif.clk);

            if (vif.rd_en && !rd_en_prev) begin
                bit [31:0] addr = vif.addr;

                do @(posedge vif.clk); while (!vif.data_valid);
                @(posedge vif.clk);

                txn = read_seq_item::type_id::create("txn");
                txn.addr       = addr;
                txn.data       = vif.data;
                txn.beat_count = 1;
                ap.write(txn);
            end

            rd_en_prev = vif.rd_en;
        end
    endtask

endclass
