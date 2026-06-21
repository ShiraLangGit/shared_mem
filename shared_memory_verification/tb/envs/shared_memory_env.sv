class shared_memory_env extends uvm_env;

    shared_memory_env_cfg       cfg;
    fac_agent_pkg::fac_agent    fac_agent;
    wifi_agent_pkg::wifi_agent  wifi_agent;
    bt_agent_pkg::bt_agent      bt_agent;
    read_agent_pkg::read_agent  read_agent;
    shared_memory_scoreboard    scoreboard;
    shared_memory_coverage      coverage;

    `uvm_component_utils(shared_memory_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(shared_memory_env_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "shared_memory_env_cfg not found in config_db")
        end

        fac_agent  = fac_agent_pkg::fac_agent::type_id::create("fac_agent",  this);
        wifi_agent = wifi_agent_pkg::wifi_agent::type_id::create("wifi_agent", this);
        bt_agent   = bt_agent_pkg::bt_agent::type_id::create("bt_agent",   this);
        read_agent = read_agent_pkg::read_agent::type_id::create("read_agent", this);
        scoreboard = shared_memory_scoreboard::type_id::create("scoreboard", this);
        coverage   = shared_memory_coverage::type_id::create("coverage",   this);

        fac_agent.is_active  = cfg.fac_is_active;
        wifi_agent.is_active = cfg.wifi_is_active;
        bt_agent.is_active   = cfg.bt_is_active;
        read_agent.is_active = cfg.read_is_active;

        uvm_config_db#(virtual fac_if)::set(this, "fac_agent*",  "vif", cfg.fac_vif);
        uvm_config_db#(virtual wifi_if)::set(this, "wifi_agent*", "vif", cfg.wifi_vif);
        uvm_config_db#(virtual bt_if)::set(this, "bt_agent*",   "vif", cfg.bt_vif);
        uvm_config_db#(virtual read_if)::set(this, "read_agent*", "vif", cfg.read_vif);
        uvm_config_db#(virtual ctrl_if)::set(this, "*", "ctrl_vif", cfg.ctrl_vif);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        fac_agent.mon.ap.connect(scoreboard.fac_imp);
        wifi_agent.mon.ap.connect(scoreboard.wifi_imp);
        bt_agent.mon.ap.connect(scoreboard.bt_imp);
        read_agent.mon.ap.connect(scoreboard.read_imp);

        fac_agent.mon.ap.connect(coverage.fac_imp);
        wifi_agent.mon.ap.connect(coverage.wifi_imp);
        bt_agent.mon.ap.connect(coverage.bt_imp);
        read_agent.mon.ap.connect(coverage.read_imp);
    endfunction

endclass
