class fac_write_word_seq extends uvm_sequence #(fac_seq_item);

    rand bit [31:0] addr;
    rand bit [31:0] data;

    `uvm_object_utils(fac_write_word_seq)
    `uvm_declare_p_sequencer(fac_sequencer)

    function new(string name = "fac_write_word_seq");
        super.new(name);
    endfunction

    task body();
        fac_seq_item req;

        req = fac_seq_item::type_id::create("req");
        if (!req.randomize() with {
            start_addr == local::addr;
            beat_count == 1;
            data.size() == 1;
            data[0]    == local::data;
        }) begin
            `uvm_fatal("RAND", "fac_write_word_seq randomize failed")
        end

        start_item(req);
        finish_item(req);
    endtask

endclass
