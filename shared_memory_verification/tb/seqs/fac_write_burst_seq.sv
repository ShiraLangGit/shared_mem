class fac_write_burst_seq extends uvm_sequence #(fac_seq_item);

    rand bit [31:0]   addr;
    rand int unsigned beat_count;
    rand bit [31:0]   data[];

    constraint beat_count_c {
        beat_count inside {[2:4]};
    }

    constraint data_size_c {
        data.size() == beat_count;
    }

    `uvm_object_utils(fac_write_burst_seq)
    `uvm_declare_p_sequencer(fac_sequencer)

    function new(string name = "fac_write_burst_seq");
        super.new(name);
    endfunction

    task body();
        fac_seq_item req;
        int unsigned i;

        req = fac_seq_item::type_id::create("req");
        if (!req.randomize() with {
            start_addr == local::addr;
            beat_count == local::beat_count;
            foreach (data[i]) { this.data[i] == local::data[i]; }
        }) begin
            `uvm_fatal("RAND", "fac_write_burst_seq randomize failed")
        end

        start_item(req);
        finish_item(req);
    endtask

endclass
