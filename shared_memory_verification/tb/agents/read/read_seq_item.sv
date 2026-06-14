class read_seq_item extends uvm_sequence_item;

    rand bit [31:0] addr;
    bit [31:0]      data;
    rand int unsigned beat_count;

    constraint beat_count_c {
        beat_count inside {[1:16]};
    }

    `uvm_object_utils_begin(read_seq_item)
        `uvm_field_int(addr, UVM_DEFAULT)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(beat_count, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "read_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=0x%08h data=0x%08h beats=%0d", addr, data, beat_count);
    endfunction

endclass
