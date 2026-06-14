class fac_sequencer extends uvm_sequencer #(fac_seq_item);

    `uvm_component_utils(fac_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
