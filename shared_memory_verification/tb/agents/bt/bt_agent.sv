class bt_agent extends uvm_agent;

    bt_sequencer sqr;
    bt_driver    drv;
    bt_monitor   mon;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_component_utils_begin(bt_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = bt_monitor::type_id::create("mon", this);

        if (is_active == UVM_ACTIVE) begin
            sqr = bt_sequencer::type_id::create("sqr", this);
            drv = bt_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass
