class bt_sequencer extends uvm_sequencer #(bt_seq_item);

    `uvm_component_utils(bt_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
