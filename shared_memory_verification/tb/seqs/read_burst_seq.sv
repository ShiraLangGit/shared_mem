class read_burst_seq extends uvm_sequence #(read_seq_item);

    rand bit [31:0]   base_addr;
    rand int unsigned beat_count;

    constraint beat_count_c {
        beat_count inside {[2:4]};
    }

    `uvm_object_utils(read_burst_seq)
    `uvm_declare_p_sequencer(read_sequencer)

    function new(string name = "read_burst_seq");
        super.new(name);
    endfunction

    task body();
        read_seq_item req;

        req = read_seq_item::type_id::create("req");
        if (!req.randomize() with {
            addr       == local::base_addr;
            beat_count == local::beat_count;
        }) begin
            `uvm_fatal("RAND", "read_burst_seq randomize failed")
        end

        start_item(req);
        finish_item(req);
    endtask

endclass
