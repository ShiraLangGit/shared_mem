class read_word_seq extends uvm_sequence #(read_seq_item);

    rand bit [31:0] addr;

    `uvm_object_utils(read_word_seq)
    `uvm_declare_p_sequencer(read_sequencer)

    function new(string name = "read_word_seq");
        super.new(name);
    endfunction

    task body();
        read_seq_item req;

        req = read_seq_item::type_id::create("req");
        if (!req.randomize() with {
            addr       == local::addr;
            beat_count == 1;
        }) begin
            `uvm_fatal("RAND", "read_word_seq randomize failed")
        end

        start_item(req);
        finish_item(req);
    endtask

endclass
