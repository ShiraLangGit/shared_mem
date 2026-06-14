class bt_seq_item extends uvm_sequence_item;

    rand bit [31:0] start_addr;
    rand bit [95:0] data;
    rand int unsigned beat_count;

    constraint beat_count_c {
        beat_count == 3;
    }

    `uvm_object_utils_begin(bt_seq_item)
        `uvm_field_int(start_addr, UVM_DEFAULT)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(beat_count, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "bt_seq_item");
        super.new(name);
        beat_count = 3;
    endfunction

    function string convert2string();
        return $sformatf(
            "start_addr=0x%08h data=0x%024h beat_count=%0d (LE split)",
            start_addr, data, beat_count
        );
    endfunction

endclass
