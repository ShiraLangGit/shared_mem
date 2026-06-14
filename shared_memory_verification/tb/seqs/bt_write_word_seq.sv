class bt_write_word_seq extends uvm_sequence #(bt_seq_item);

    rand bit [31:0] addr;
    rand bit [95:0] data;

    `uvm_object_utils(bt_write_word_seq)
    `uvm_declare_p_sequencer(bt_sequencer)

    function new(string name = "bt_write_word_seq");
        super.new(name);
    endfunction

    task body();
        bt_seq_item req;

        req = bt_seq_item::type_id::create("req");
        if (!req.randomize() with {
            start_addr == local::addr;
            data       == local::data;
            beat_count == 3;
        }) begin
            `uvm_fatal("RAND", "bt_write_word_seq randomize failed")
        end

        `uvm_info("BT_SEQ", $sformatf(
            "BT LE write @ 0x%08h data=0x%024h (beat_count=3)", addr, data
        ), UVM_MEDIUM)

        start_item(req);
        finish_item(req);
    endtask

endclass
