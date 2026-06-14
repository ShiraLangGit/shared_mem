class fac_seq_item extends uvm_sequence_item;

    rand bit [31:0] start_addr;
    rand int unsigned beat_count;
    rand bit [31:0] data[];

    constraint beat_count_c {
        beat_count inside {[1:16]};
    }

    constraint data_size_c {
        data.size() == beat_count;
    }

    `uvm_object_utils_begin(fac_seq_item)
        `uvm_field_int(start_addr, UVM_DEFAULT)
        `uvm_field_int(beat_count, UVM_DEFAULT)
        `uvm_field_sarray_int(data, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fac_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("start_addr=0x%08h beats=%0d", start_addr, beat_count);
    endfunction

endclass
