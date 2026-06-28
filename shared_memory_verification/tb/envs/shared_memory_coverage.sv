`ifndef SHARED_MEMORY_COVERAGE_SV
`define SHARED_MEMORY_COVERAGE_SV

`uvm_analysis_imp_decl(_cov_fac)
`uvm_analysis_imp_decl(_cov_wifi)
`uvm_analysis_imp_decl(_cov_bt)
`uvm_analysis_imp_decl(_cov_read)

// Manual bin tracker — prints [COV] percentages in UVM log.
class cov_group_tracker;
    string bins_q[$];
    bit    hit_map[string];

    function void add_bin(string name);
        bins_q.push_back(name);
        hit_map[name] = 1'b0;
    endfunction

    function void sample_bin(string name);
        if (hit_map.exists(name))
            hit_map[name] = 1'b1;
    endfunction

    function real get_coverage();
        int unsigned hit = 0;
        if (bins_q.size() == 0)
            return 0.0;
        foreach (bins_q[i]) begin
            if (hit_map[bins_q[i]])
                hit++;
        end
        return 100.0 * real'(hit) / real'(bins_q.size());
    endfunction
endclass

class shared_memory_coverage extends uvm_component;

    uvm_analysis_imp_cov_fac#(fac_seq_item,  shared_memory_coverage) fac_imp;
    uvm_analysis_imp_cov_wifi#(wifi_seq_item, shared_memory_coverage) wifi_imp;
    uvm_analysis_imp_cov_bt#(bt_seq_item,    shared_memory_coverage) bt_imp;
    uvm_analysis_imp_cov_read#(read_seq_item,  shared_memory_coverage) read_imp;

    virtual ctrl_if ctrl_vif;

    sel_e         last_sel;
    mem_status_e  prev_status;
    int unsigned  last_write_if;  // 0=fac, 1=wifi, 2=bt, 3=none

    cov_group_tracker cg_interface_select;
    cov_group_tracker cg_memory_status;
    cov_group_tracker cg_status_transition;
    cov_group_tracker cg_write_ops;
    cov_group_tracker cg_read_ops;
    cov_group_tracker cg_read_after_write;

    // SystemVerilog covergroups — collected by xrun -coverage functional, viewed in IMC
    covergroup cg_if_sel_cov with function sample(sel_e sel);
        option.per_instance = 1;
        option.name         = "cg_interface_select";
        cp_sel: coverpoint sel {
            ignore_bins invalid = {SEL_INVALID};
            bins fac  = {SEL_FAC};
            bins wifi = {SEL_WIFI};
            bins bt   = {SEL_BT};
        }
    endgroup

    covergroup cg_mem_status_cov with function sample(mem_status_e status);
        option.per_instance = 1;
        option.name         = "cg_memory_status";
        cp_st: coverpoint status {
            bins idle    = {STATUS_IDLE};
            bins writing = {STATUS_WRITING};
            bins reading = {STATUS_READING};
            bins error   = {STATUS_ERROR};
        }
    endgroup

    covergroup cg_status_x_cov with function sample(mem_status_e from_s, mem_status_e to_s);
        option.per_instance = 1;
        option.name         = "cg_status_transition";
        cp_x: coverpoint {from_s, to_s} {
            bins idle_to_writing = {{STATUS_IDLE,    STATUS_WRITING}};
            bins writing_to_idle = {{STATUS_WRITING, STATUS_IDLE}};
            bins idle_to_reading = {{STATUS_IDLE,    STATUS_READING}};
            bins reading_to_idle = {{STATUS_READING, STATUS_IDLE}};
            bins writing_to_read = {{STATUS_WRITING, STATUS_READING}};
            bins read_to_writing = {{STATUS_READING, STATUS_WRITING}};
            bins any_to_error    = {
                {STATUS_IDLE,    STATUS_ERROR},
                {STATUS_WRITING, STATUS_ERROR},
                {STATUS_READING, STATUS_ERROR}
            };
        }
    endgroup

    covergroup cg_write_ops_cov with function sample(
        int unsigned if_id,
        bit [31:0]   addr,
        int unsigned beat_count
    );
        option.per_instance = 1;
        option.name         = "cg_write_ops";
        cp_if: coverpoint if_id {
            bins if_fac  = {0};
            bins if_wifi = {1};
            bins if_bt   = {2};
        }
        cp_addr: coverpoint addr {
            bins addr_low  = {[32'h0:32'hFF]};
            bins addr_mid  = {[32'h100:32'h3FF]};
            bins addr_high = {[32'h400:32'hFFF]};
        }
        cp_beats: coverpoint beat_count {
            bins beats_one   = {1};
            bins beats_multi = {[2:16]};
        }
        cross_if_beats: cross cp_if, cp_beats {
            bins cross_fac_one   = binsof(cp_if.if_fac)  && binsof(cp_beats.beats_one);
            bins cross_fac_multi = binsof(cp_if.if_fac)  && binsof(cp_beats.beats_multi);
            bins cross_wifi_multi= binsof(cp_if.if_wifi) && binsof(cp_beats.beats_multi);
            bins cross_bt_multi  = binsof(cp_if.if_bt)   && binsof(cp_beats.beats_multi);
            // WiFi is always 2 beats, BT always 3 — beats_one crosses are unreachable.
            ignore_bins wifi_one_unreach = binsof(cp_if.if_wifi) && binsof(cp_beats.beats_one);
            ignore_bins bt_one_unreach   = binsof(cp_if.if_bt)   && binsof(cp_beats.beats_one);
        }
    endgroup

    covergroup cg_read_ops_cov with function sample(
        bit [31:0]   addr,
        int unsigned beat_count
    );
        option.per_instance = 1;
        option.name         = "cg_read_ops";
        cp_addr: coverpoint addr {
            bins addr_low  = {[32'h0:32'hFF]};
            bins addr_mid  = {[32'h100:32'h3FF]};
            bins addr_high = {[32'h400:32'hFFF]};
        }
        cp_beats: coverpoint beat_count {
            bins beats_one   = {1};
            bins beats_multi = {[2:16]};
        }
    endgroup

    covergroup cg_readback_cov with function sample(int unsigned wr_if);
        option.per_instance = 1;
        option.name         = "cg_read_after_write";
        cp_rb: coverpoint wr_if {
            bins fac_readback  = {0};
            bins wifi_readback = {1};
            bins bt_readback   = {2};
            bins none_readback = {3};
        }
    endgroup

    `uvm_component_utils(shared_memory_coverage)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        last_sel      = SEL_FAC;
        prev_status   = STATUS_IDLE;
        last_write_if = 3;
        init_trackers();
        cg_if_sel_cov      = new();
        cg_mem_status_cov  = new();
        cg_status_x_cov    = new();
        cg_write_ops_cov   = new();
        cg_read_ops_cov    = new();
        cg_readback_cov    = new();
    endfunction

    function void init_trackers();
        cg_interface_select = new();
        cg_interface_select.add_bin("fac");
        cg_interface_select.add_bin("wifi");
        cg_interface_select.add_bin("bt");

        cg_memory_status = new();
        cg_memory_status.add_bin("idle");
        cg_memory_status.add_bin("writing");
        cg_memory_status.add_bin("reading");
        cg_memory_status.add_bin("error");

        cg_status_transition = new();
        cg_status_transition.add_bin("idle_to_writing");
        cg_status_transition.add_bin("writing_to_idle");
        cg_status_transition.add_bin("idle_to_reading");
        cg_status_transition.add_bin("reading_to_idle");
        cg_status_transition.add_bin("writing_to_read");
        cg_status_transition.add_bin("read_to_writing");
        cg_status_transition.add_bin("any_to_error");

        cg_write_ops = new();
        cg_write_ops.add_bin("if_fac");
        cg_write_ops.add_bin("if_wifi");
        cg_write_ops.add_bin("if_bt");
        cg_write_ops.add_bin("addr_low");
        cg_write_ops.add_bin("addr_mid");
        cg_write_ops.add_bin("addr_high");
        cg_write_ops.add_bin("beats_one");
        cg_write_ops.add_bin("beats_multi");
        cg_write_ops.add_bin("cross_fac_one");
        cg_write_ops.add_bin("cross_fac_multi");
        cg_write_ops.add_bin("cross_wifi_multi");
        cg_write_ops.add_bin("cross_bt_multi");

        cg_read_ops = new();
        cg_read_ops.add_bin("addr_low");
        cg_read_ops.add_bin("addr_mid");
        cg_read_ops.add_bin("addr_high");
        cg_read_ops.add_bin("beats_one");
        cg_read_ops.add_bin("beats_multi");

        cg_read_after_write = new();
        cg_read_after_write.add_bin("fac_readback");
        cg_read_after_write.add_bin("wifi_readback");
        cg_read_after_write.add_bin("bt_readback");
        cg_read_after_write.add_bin("none_readback");
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fac_imp  = new("fac_imp",  this);
        wifi_imp = new("wifi_imp", this);
        bt_imp   = new("bt_imp",   this);
        read_imp = new("read_imp", this);

        if (!uvm_config_db#(virtual ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
            `uvm_fatal("NOVIF", "ctrl_vif not set for shared_memory_coverage")
        end
    endfunction

    function void sample_interface_select(sel_e sel);
        case (sel)
            SEL_FAC:  cg_interface_select.sample_bin("fac");
            SEL_WIFI: cg_interface_select.sample_bin("wifi");
            SEL_BT:   cg_interface_select.sample_bin("bt");
            default:  ;
        endcase
        if (sel != SEL_INVALID)
            cg_if_sel_cov.sample(sel);
    endfunction

    function void sample_memory_status(mem_status_e status);
        case (status)
            STATUS_IDLE:    cg_memory_status.sample_bin("idle");
            STATUS_WRITING: cg_memory_status.sample_bin("writing");
            STATUS_READING: cg_memory_status.sample_bin("reading");
            STATUS_ERROR:   cg_memory_status.sample_bin("error");
            default:        ;
        endcase
        cg_mem_status_cov.sample(status);
    endfunction

    function void sample_status_transition(mem_status_e from_s, mem_status_e to_s);
        if (to_s == STATUS_ERROR) begin
            cg_status_transition.sample_bin("any_to_error");
        end
        else if (from_s == STATUS_IDLE && to_s == STATUS_WRITING)
            cg_status_transition.sample_bin("idle_to_writing");
        else if (from_s == STATUS_WRITING && to_s == STATUS_IDLE)
            cg_status_transition.sample_bin("writing_to_idle");
        else if (from_s == STATUS_IDLE && to_s == STATUS_READING)
            cg_status_transition.sample_bin("idle_to_reading");
        else if (from_s == STATUS_READING && to_s == STATUS_IDLE)
            cg_status_transition.sample_bin("reading_to_idle");
        else if (from_s == STATUS_WRITING && to_s == STATUS_READING)
            cg_status_transition.sample_bin("writing_to_read");
        else if (from_s == STATUS_READING && to_s == STATUS_WRITING)
            cg_status_transition.sample_bin("read_to_writing");

        if (from_s != to_s)
            cg_status_x_cov.sample(from_s, to_s);
    endfunction

    function void sample_addr_bins(cov_group_tracker tracker, bit [31:0] addr);
        if (addr <= 32'hFF)
            tracker.sample_bin("addr_low");
        else if (addr <= 32'h3FF)
            tracker.sample_bin("addr_mid");
        else if (addr <= 32'hFFF)
            tracker.sample_bin("addr_high");
    endfunction

    function void sample_beat_bins(cov_group_tracker tracker, int unsigned beat_count);
        if (beat_count == 1)
            tracker.sample_bin("beats_one");
        else if (beat_count >= 2 && beat_count <= 16)
            tracker.sample_bin("beats_multi");
    endfunction

    function void sample_write_cross(int unsigned if_id, int unsigned beat_count);
        string cross_bin;

        if (if_id == 0)
            cross_bin = (beat_count == 1) ? "cross_fac_one" : "cross_fac_multi";
        else if (if_id == 1)
            cross_bin = "cross_wifi_multi";
        else
            cross_bin = "cross_bt_multi";

        cg_write_ops.sample_bin(cross_bin);
    endfunction

    function void sample_write_ops(int unsigned if_id, bit [31:0] addr, int unsigned beat_count);
        case (if_id)
            0: cg_write_ops.sample_bin("if_fac");
            1: cg_write_ops.sample_bin("if_wifi");
            2: cg_write_ops.sample_bin("if_bt");
            default: ;
        endcase

        sample_addr_bins(cg_write_ops, addr);
        sample_beat_bins(cg_write_ops, beat_count);
        sample_write_cross(if_id, beat_count);
        cg_write_ops_cov.sample(if_id, addr, beat_count);
    endfunction

    function void sample_read_ops(bit [31:0] addr, int unsigned beat_count);
        sample_addr_bins(cg_read_ops, addr);
        sample_beat_bins(cg_read_ops, beat_count);
        cg_read_ops_cov.sample(addr, beat_count);
    endfunction

    function void sample_read_after_write(int unsigned write_if_id);
        case (write_if_id)
            0: cg_read_after_write.sample_bin("fac_readback");
            1: cg_read_after_write.sample_bin("wifi_readback");
            2: cg_read_after_write.sample_bin("bt_readback");
            default: cg_read_after_write.sample_bin("none_readback");
        endcase
        cg_readback_cov.sample(write_if_id);
    endfunction

    task run_phase(uvm_phase phase);
        mem_status_e cur_status;

        forever begin
            @(ctrl_vif.mon_cb);
            last_sel = sel_e'(ctrl_vif.mon_cb.interface_select);
            sample_interface_select(last_sel);

            cur_status = mem_status_e'(ctrl_vif.mon_cb.memory_status);
            sample_memory_status(cur_status);

            if (cur_status != prev_status) begin
                sample_status_transition(prev_status, cur_status);
                prev_status = cur_status;
            end
        end
    endtask

    function void sample_none_readback();
        sample_read_after_write(3);
    endfunction

    function void sample_read_burst_ops(bit [31:0] addr, int unsigned beat_count);
        sample_read_ops(addr, beat_count);
    endfunction

    function void write_cov_fac(fac_seq_item t);
        last_write_if = 0;
        sample_write_ops(0, t.start_addr, t.beat_count);
    endfunction

    function void write_cov_wifi(wifi_seq_item t);
        last_write_if = 1;
        sample_write_ops(1, t.start_addr, 2);
    endfunction

    function void write_cov_bt(bt_seq_item t);
        last_write_if = 2;
        sample_write_ops(2, t.start_addr, 3);
    endfunction

    function void write_cov_read(read_seq_item t);
        sample_read_ops(t.addr, t.beat_count);
        sample_read_after_write(last_write_if);
    endfunction

    function void report_phase(uvm_phase phase);
        real pct;

        super.report_phase(phase);
        pct = cg_interface_select.get_coverage();
        `uvm_info("COV", $sformatf("cg_interface_select coverage = %0.1f%%", pct), UVM_LOW)
        pct = cg_memory_status.get_coverage();
        `uvm_info("COV", $sformatf("cg_memory_status coverage = %0.1f%%", pct), UVM_LOW)
        pct = cg_status_transition.get_coverage();
        `uvm_info("COV", $sformatf("cg_status_transition coverage = %0.1f%%", pct), UVM_LOW)
        pct = cg_write_ops.get_coverage();
        `uvm_info("COV", $sformatf("cg_write_ops coverage = %0.1f%%", pct), UVM_LOW)
        pct = cg_read_ops.get_coverage();
        `uvm_info("COV", $sformatf("cg_read_ops coverage = %0.1f%%", pct), UVM_LOW)
        pct = cg_read_after_write.get_coverage();
        `uvm_info("COV", $sformatf("cg_read_after_write coverage = %0.1f%%", pct), UVM_LOW)
        `uvm_info("COV", "Open IMC: ./sim/regression.sh", UVM_LOW)
    endfunction

endclass

`endif // SHARED_MEMORY_COVERAGE_SV
