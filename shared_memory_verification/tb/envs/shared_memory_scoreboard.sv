`uvm_analysis_imp_decl(_fac)
`uvm_analysis_imp_decl(_wifi)
`uvm_analysis_imp_decl(_bt)
`uvm_analysis_imp_decl(_read)

class shared_memory_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_fac#(fac_seq_item, shared_memory_scoreboard)  fac_imp;
    uvm_analysis_imp_wifi#(wifi_seq_item, shared_memory_scoreboard) wifi_imp;
    uvm_analysis_imp_bt#(bt_seq_item, shared_memory_scoreboard)    bt_imp;
    uvm_analysis_imp_read#(read_seq_item, shared_memory_scoreboard) read_imp;

    bit [31:0] mem[bit[31:0]];
    int unsigned mismatch_count;

    `uvm_component_utils(shared_memory_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mismatch_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fac_imp  = new("fac_imp",  this);
        wifi_imp = new("wifi_imp", this);
        bt_imp   = new("bt_imp",   this);
        read_imp = new("read_imp", this);
    endfunction

    function int unsigned get_mismatch_count();
        return mismatch_count;
    endfunction

    function void write_fac(fac_seq_item t);
        if (t.data.size() == 0) begin
            `uvm_warning("SCB", $sformatf("FAC txn with no data @ 0x%08h", t.start_addr))
            return;
        end
        mem[t.start_addr] = t.data[0];
        `uvm_info("SCB", $sformatf("FAC write mem[0x%08h] = 0x%08h", t.start_addr, t.data[0]), UVM_HIGH)
    endfunction

    function void write_wifi(wifi_seq_item t);
        mem[t.start_addr]         = t.data[31:0];
        mem[t.start_addr + 32'd1] = t.data[63:32];
        `uvm_info("SCB", $sformatf(
            "WiFi LE write mem[0x%08h]=0x%08h mem[0x%08h]=0x%08h",
            t.start_addr, t.data[31:0], t.start_addr + 32'd1, t.data[63:32]
        ), UVM_HIGH)
    endfunction

    function void write_bt(bt_seq_item t);
        mem[t.start_addr]         = t.data[31:0];
        mem[t.start_addr + 32'd1] = t.data[63:32];
        mem[t.start_addr + 32'd2] = t.data[95:64];
        `uvm_info("SCB", $sformatf(
            "BT LE write mem[0x%08h..0x%08h] = 0x%08h 0x%08h 0x%08h",
            t.start_addr, t.start_addr + 32'd2,
            t.data[31:0], t.data[63:32], t.data[95:64]
        ), UVM_HIGH)
    endfunction

    function void write_read(read_seq_item t);
        if (!mem.exists(t.addr)) begin
            mismatch_count++;
            `uvm_error("SCB", $sformatf(
                "Read from untracked address 0x%08h (data=0x%08h)",
                t.addr, t.data
            ))
            return;
        end

        if (mem[t.addr] !== t.data) begin
            mismatch_count++;
            `uvm_error("SCB", $sformatf(
                "Data mismatch @ 0x%08h: expected=0x%08h, read=0x%08h",
                t.addr, mem[t.addr], t.data
            ))
        end else begin
            `uvm_info("SCB", $sformatf(
                "Read check passed @ 0x%08h: 0x%08h",
                t.addr, t.data
            ), UVM_MEDIUM)
        end
    endfunction

endclass
