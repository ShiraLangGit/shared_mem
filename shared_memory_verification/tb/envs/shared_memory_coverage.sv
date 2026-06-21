`uvm_analysis_imp_decl(_cov_fac)
`uvm_analysis_imp_decl(_cov_wifi)
`uvm_analysis_imp_decl(_cov_bt)
`uvm_analysis_imp_decl(_cov_read)

class shared_memory_coverage extends uvm_component;

    uvm_analysis_imp_cov_fac#(fac_seq_item,  shared_memory_coverage) fac_imp;
    uvm_analysis_imp_cov_wifi#(wifi_seq_item, shared_memory_coverage) wifi_imp;
    uvm_analysis_imp_cov_bt#(bt_seq_item,    shared_memory_coverage) bt_imp;
    uvm_analysis_imp_cov_read#(read_seq_item,  shared_memory_coverage) read_imp;

    virtual ctrl_if ctrl_vif;

    sel_e         last_sel;
    mem_status_e  prev_status;
    bit           fac_written;
    bit           wifi_written;
    bit           bt_written;

    // --- Functional covergroups ---

    covergroup cg_interface_select with function sample(sel_e sel);
        option.per_instance = 1;
        cp_sel: coverpoint sel {
            bins fac  = {SEL_FAC};
            bins wifi = {SEL_WIFI};
            bins bt   = {SEL_BT};
            ignore_bins invalid = {SEL_INVALID};
        }
    endgroup

    covergroup cg_memory_status with function sample(mem_status_e status);
        option.per_instance = 1;
        cp_status: coverpoint status {
            bins idle    = {STATUS_IDLE};
            bins writing = {STATUS_WRITING};
            bins reading = {STATUS_READING};
            bins error   = {STATUS_ERROR};
        }
    endgroup

    covergroup cg_status_transition with function sample(mem_status_e from_s, mem_status_e to_s);
        option.per_instance = 1;
        cp_from: coverpoint from_s {
            bins idle    = {STATUS_IDLE};
            bins writing = {STATUS_WRITING};
            bins reading = {STATUS_READING};
            bins error   = {STATUS_ERROR};
        }
        cp_to: coverpoint to_s {
            bins idle    = {STATUS_IDLE};
            bins writing = {STATUS_WRITING};
            bins reading = {STATUS_READING};
            bins error   = {STATUS_ERROR};
        }
        cx_flow: cross cp_from, cp_to {
            bins idle_to_writing  = binsof(cp_from.idle)    && binsof(cp_to.writing);
            bins writing_to_idle  = binsof(cp_from.writing) && binsof(cp_to.idle);
            bins idle_to_reading  = binsof(cp_from.idle)    && binsof(cp_to.reading);
            bins reading_to_idle  = binsof(cp_from.reading) && binsof(cp_to.idle);
            bins writing_to_read  = binsof(cp_from.writing) && binsof(cp_to.reading);
            bins read_to_writing  = binsof(cp_from.reading) && binsof(cp_to.writing);
            bins any_to_error     = binsof(cp_to.error);
        }
    endgroup

    covergroup cg_write_ops with function sample(
        int unsigned if_id,
        bit [31:0]   addr,
        int unsigned beat_count
    );
        option.per_instance = 1;
        cp_if: coverpoint if_id {
            bins fac  = {0};
            bins wifi = {1};
            bins bt   = {2};
        }
        cp_addr: coverpoint addr {
            bins low  = {[32'h00:32'hFF]};
            bins mid  = {[32'h100:32'h3FF]};
            bins high = {[32'h400:32'hFFF]};
        }
        cp_beats: coverpoint beat_count {
            bins one   = {1};
            bins multi = {[2:16]};
        }
        cx_if_beats: cross cp_if, cp_beats;
    endgroup

    covergroup cg_read_ops with function sample(
        bit [31:0] addr,
        int unsigned beat_count
    );
        option.per_instance = 1;
        cp_addr: coverpoint addr {
            bins low  = {[32'h00:32'hFF]};
            bins mid  = {[32'h100:32'h3FF]};
            bins high = {[32'h400:32'hFFF]};
        }
        cp_beats: coverpoint beat_count {
            bins one   = {1};
            bins multi = {[2:16]};
        }
    endgroup

    covergroup cg_read_after_write with function sample(
        int unsigned write_if_id,
        int unsigned read_done
    );
        option.per_instance = 1;
        cp_wr_if: coverpoint write_if_id {
            bins fac  = {0};
            bins wifi = {1};
            bins bt   = {2};
            bins none = {3};
        }
        cp_read: coverpoint read_done {
            bins readback = {1};
        }
        cx_wr_then_rd: cross cp_wr_if, cp_read;
    endgroup

    `uvm_component_utils(shared_memory_coverage)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_interface_select   = new();
        cg_memory_status      = new();
        cg_status_transition  = new();
        cg_write_ops          = new();
        cg_read_ops           = new();
        cg_read_after_write   = new();
        last_sel              = SEL_FAC;
        prev_status           = STATUS_IDLE;
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

    task run_phase(uvm_phase phase);
        mem_status_e cur_status;

        forever begin
            @(ctrl_vif.mon_cb);
            last_sel = sel_e'(ctrl_vif.mon_cb.interface_select);
            cg_interface_select.sample(last_sel);

            cur_status = mem_status_e'(ctrl_vif.mon_cb.memory_status);
            cg_memory_status.sample(cur_status);

            if (cur_status != prev_status) begin
                cg_status_transition.sample(prev_status, cur_status);
                prev_status = cur_status;
            end
        end
    endtask

    function void write_cov_fac(fac_seq_item t);
        fac_written = 1'b1;
        cg_write_ops.sample(0, t.start_addr, t.beat_count);
    endfunction

    function void write_cov_wifi(wifi_seq_item t);
        wifi_written = 1'b1;
        cg_write_ops.sample(1, t.start_addr, 2);
    endfunction

    function void write_cov_bt(bt_seq_item t);
        bt_written = 1'b1;
        cg_write_ops.sample(2, t.start_addr, 3);
    endfunction

    function void write_cov_read(read_seq_item t);
        int unsigned wr_if = 3;

        if (fac_written)  wr_if = 0;
        else if (wifi_written) wr_if = 1;
        else if (bt_written)   wr_if = 2;

        cg_read_ops.sample(t.addr, t.beat_count);
        cg_read_after_write.sample(wr_if, 1);
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
    endfunction

endclass
