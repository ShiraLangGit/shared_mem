class wifi_sequencer extends uvm_sequencer #(wifi_seq_item);

    `uvm_component_utils(wifi_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
