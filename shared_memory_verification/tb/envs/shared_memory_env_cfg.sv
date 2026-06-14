class shared_memory_env_cfg extends uvm_object;

    virtual fac_if  fac_vif;
    virtual wifi_if wifi_vif;
    virtual bt_if   bt_vif;
    virtual read_if read_vif;
    virtual ctrl_if ctrl_vif;

    uvm_active_passive_enum fac_is_active  = UVM_ACTIVE;
    uvm_active_passive_enum wifi_is_active = UVM_ACTIVE;
    uvm_active_passive_enum bt_is_active   = UVM_ACTIVE;
    uvm_active_passive_enum read_is_active = UVM_ACTIVE;

    `uvm_object_utils_begin(shared_memory_env_cfg)
        `uvm_field_enum(uvm_active_passive_enum, fac_is_active,  UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, wifi_is_active, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, bt_is_active,   UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, read_is_active, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "shared_memory_env_cfg");
        super.new(name);
    endfunction

endclass
