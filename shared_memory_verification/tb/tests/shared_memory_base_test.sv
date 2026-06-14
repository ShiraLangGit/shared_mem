class shared_memory_base_test extends uvm_test;

    shared_memory_env     env;
    shared_memory_env_cfg cfg;

    `uvm_component_utils(shared_memory_base_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = shared_memory_env_cfg::type_id::create("cfg");
        if (!uvm_config_db#(virtual fac_if)::get(this, "", "fac_vif", cfg.fac_vif)) begin
            `uvm_fatal("NOVIF", "fac_vif not set in config_db")
        end
        if (!uvm_config_db#(virtual wifi_if)::get(this, "", "wifi_vif", cfg.wifi_vif)) begin
            `uvm_fatal("NOVIF", "wifi_vif not set in config_db")
        end
        if (!uvm_config_db#(virtual bt_if)::get(this, "", "bt_vif", cfg.bt_vif)) begin
            `uvm_fatal("NOVIF", "bt_vif not set in config_db")
        end
        if (!uvm_config_db#(virtual read_if)::get(this, "", "read_vif", cfg.read_vif)) begin
            `uvm_fatal("NOVIF", "read_vif not set in config_db")
        end
        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", cfg.ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not set in config_db")
        end
        uvm_config_db#(shared_memory_env_cfg)::set(this, "*", "cfg", cfg);

        env = shared_memory_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("BASE_TEST", "shared_memory_base_test run_phase (no sequences)", UVM_LOW)
        #1us;
        phase.drop_objection(this);
    endtask

endclass
