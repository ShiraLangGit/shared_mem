class fac_agent extends uvm_agent;

    fac_sequencer  sqr;
    fac_driver     drv;
    fac_monitor    mon;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_component_utils_begin(fac_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = fac_monitor::type_id::create("mon", this);

        if (is_active == UVM_ACTIVE) begin
            sqr = fac_sequencer::type_id::create("sqr", this);
            drv = fac_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass
