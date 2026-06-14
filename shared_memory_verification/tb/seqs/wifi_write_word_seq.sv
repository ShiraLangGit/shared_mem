class wifi_write_word_seq extends uvm_sequence #(wifi_seq_item);

    rand bit [31:0] addr;
    rand bit [63:0] data;

    `uvm_object_utils(wifi_write_word_seq)
    `uvm_declare_p_sequencer(wifi_sequencer)

    function new(string name = "wifi_write_word_seq");
        super.new(name);
    endfunction

    task body();
        wifi_seq_item req;

        req = wifi_seq_item::type_id::create("req");
        if (!req.randomize() with {
            start_addr == local::addr;
            data       == local::data;
            beat_count == 2;
        }) begin
            `uvm_fatal("RAND", "wifi_write_word_seq randomize failed")
        end

        `uvm_info("WIFI_SEQ", $sformatf(
            "WiFi LE write @ 0x%08h data=0x%016h (beat_count=2)", addr, data
        ), UVM_MEDIUM)

        start_item(req);
        finish_item(req);
    endtask

endclass
