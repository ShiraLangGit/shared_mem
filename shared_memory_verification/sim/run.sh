#!/bin/bash
# Shared Memory UVM — 3 דברים:
#
#   ./sim/run.sh                 # 1) כל הטסטים (מ-regression.list)
#   ./sim/regression.sh          # 2) coverage regression + IMC
#   ./sim/run.sh waves wifi      # 3) גלים

COV_REG_TEST="test_coverage_regression"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/tb/top/shared_memory_tb.sv" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$SCRIPT_DIR/.."
}

ROOT="$(cd "$(find_project_root "$SCRIPT_DIR")" && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/sim/logs"
REG_LIST="$ROOT/sim/regression.list"
WAVES_TCL="$ROOT/sim/waves.tcl"

show_help() {
    cat <<'EOF'
Shared Memory — sim/run.sh

  1) הרצת כל הטסטים (batch) — קורא מ-regression.list:
       ./sim/run.sh
       ./sim/run.sh all --clean

  2) Coverage regression + IMC — טסט אחד שמכיל הכל:
       ./sim/regression.sh
       ./sim/regression.sh --clean
     (מריץ test_coverage_regression = FAC + WiFi + BT)
     ב-IMC: Reports -> Functional -> CoverGroup Summary

  3) גלים (SimVision):
       ./sim/run.sh waves wifi

  קבצים ב-sim/:
       run.sh            — הרצת כל הטסטים / גלים
       regression.sh     — coverage regression + IMC
       regression.list   — רשימת טסטים ל-run.sh all
       waves.tcl         — probes לגלים
EOF
}

resolve_fac_pkg() {
    local candidate found
    for candidate in tb/agents/fac/fac_agent.pkg.sv tb/agents/fac/fac_agent_pkg.sv; do
        [ -f "$candidate" ] && { echo "$candidate"; return 0; }
    done
    found="$(find . -path '*/fac/fac_agent*.sv' 2>/dev/null | head -1)"
    [ -n "$found" ] && { echo "$found"; return 0; }
    echo "ERROR: fac agent package not found" >&2
    exit 1
}

resolve_bt_if() {
    local candidate
    for candidate in rtl/bt_wirte_if.sv rtl/bt_write_if.sv; do
        [ -f "$candidate" ] && { echo "$candidate"; return 0; }
    done
    echo "ERROR: bt_write_if.sv not found" >&2
    exit 1
}

FAC_PKG="$(resolve_fac_pkg)"
BT_IF="$(resolve_bt_if)"

map_test() {
    case "$1" in
        sanity|fac) echo "test_sanity_fac" ;;
        wifi)       echo "test_wifi_split" ;;
        bt)         echo "test_bt_split" ;;
        *)          echo "$1" ;;
    esac
}

load_tests() {
    local -a tests=() line trimmed
    [ -f "$REG_LIST" ] || { echo "sanity wifi bt"; return; }
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed="${line%%#*}"
        trimmed="$(echo "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$trimmed" ] && continue
        tests+=("$trimmed")
    done < "$REG_LIST"
    [ "${#tests[@]}" -gt 0 ] || { echo "ERROR: $REG_LIST is empty" >&2; exit 1; }
    echo "${tests[@]}"
}

run_xrun() {
    local uvm_test="$1"
    shift
    xrun -sv -uvm -timescale 1ns/1ps -access +rwc "$@" \
        -incdir rtl -incdir tb/agents/fac -incdir tb/agents/wifi \
        -incdir tb/agents/bt -incdir tb/agents/read -incdir tb/interfaces \
        -incdir tb/envs -incdir tb/seqs -incdir tb/tests \
        rtl/shared_memory_pkg.sv "$FAC_PKG" \
        tb/agents/wifi/wifi_agent_pkg.sv tb/agents/bt/bt_agent_pkg.sv \
        tb/agents/read/read_agent_pkg.sv tb/envs/shared_memory_env_pkg.sv \
        tb/seqs/fac_seq_pkg.sv tb/seqs/wifi_seq_pkg.sv tb/seqs/bt_seq_pkg.sv \
        tb/seqs/read_seq_pkg.sv tb/seqs/common_seq_pkg.sv \
        tb/tests/shared_memory_test_pkg.sv \
        rtl/async_fifo.sv "$BT_IF" \
        rtl/fac_write_if.sv rtl/wifi_write_if.sv rtl/dual_port_ram.sv \
        rtl/interface_mux.sv rtl/mem_status_ctrl.sv rtl/read_ctrl.sv \
        rtl/shared_memory.sv rtl/write_ctrl.sv \
        tb/agents/fac/fac_if.sv tb/agents/wifi/wifi_if.sv \
        tb/agents/bt/bt_if.sv tb/agents/read/read_if.sv \
        tb/interfaces/ctrl_if.sv tb/top/shared_memory_tb.sv \
        +UVM_TESTNAME="$uvm_test"
}

# --- 1) כל הטסטים (batch) ---
run_all_tests() {
    local -a tests=("$@")
    local t uvm pass=0 fail=0 log=""
    for t in "${tests[@]}"; do
        uvm="$(map_test "$t")"
        echo "========== $uvm =========="
        if run_xrun "$uvm" -batch; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
    done
    echo "========== PASS=$pass  FAIL=$fail =========="
    [ "$fail" -eq 0 ]
}

# --- 2) Coverage regression: טסט אחד (FAC+WiFi+BT) + coverage + IMC ---
run_regression() {
    local uvm="$COV_REG_TEST"
    local log="$LOG_DIR/${uvm}.log"

    rm -rf cov_work
    mkdir -p "$LOG_DIR"

    echo "========== $uvm (FAC + WiFi + BT + coverage) =========="
    echo "  Source: tb/tests/test_coverage_regression.sv"
    run_xrun "$uvm" -batch -l "$log" \
        -coverage functional -covworkdir cov_work -covtest "$uvm" -covoverwrite

    print_cov_summary
}

print_cov_summary() {
    local log
    echo ""
    echo "========== [COV] summary =========="
    for log in "$LOG_DIR"/test_*.log; do
        [ -f "$log" ] || continue
        echo "--- $(basename "$log" .log) ---"
        grep '\[COV\]' "$log" || echo "(no [COV] lines)"
    done
    echo "=================================="
}

open_imc() {
    local dir="$ROOT/cov_work/scope/$COV_REG_TEST"

    command -v imc >/dev/null 2>&1 || { echo "ERROR: imc not in PATH" >&2; exit 1; }
    [ -n "${DISPLAY:-}" ]         || { echo "ERROR: DISPLAY not set (need X11)" >&2; exit 1; }
    [ -d "$dir" ] && compgen -G "$dir/*.ucd" >/dev/null 2>&1 || {
        echo "ERROR: no coverage DB at $dir" >&2
        echo "Run first: ./sim/regression.sh --clean" >&2
        exit 1
    }

    echo "Opening IMC: $dir"
    mkdir -p "$LOG_DIR"
    imc -load "$dir" -gui 2>&1 | tee "$LOG_DIR/imc.log" &

    local pid=$!
    sleep 4
    if kill -0 "$pid" 2>/dev/null; then
        echo "IMC running (PID $pid)."
        echo "  Reports -> Functional -> CoverGroup Summary"
    else
        echo "ERROR: IMC failed — see $LOG_DIR/imc.log" >&2
        tail -15 "$LOG_DIR/imc.log" >&2
        exit 1
    fi
}

# --- 3) גלים ---
run_waves() {
    local uvm_test="$1"
    [ -f "$WAVES_TCL" ] || { echo "ERROR: missing $WAVES_TCL" >&2; exit 1; }
    [ -n "${DISPLAY:-}" ] || { echo "ERROR: DISPLAY not set" >&2; exit 1; }
    mkdir -p "$ROOT/waves"
    echo "========== $uvm_test (waves) =========="
    run_xrun "$uvm_test" -gui -input "$WAVES_TCL"
}

# ---------------------------------------------------------------------------
CMD="all"
WAVE_TEST="sanity"
DO_CLEAN=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)        show_help; exit 0 ;;
        --clean)          DO_CLEAN=1; shift ;;
        all)              CMD="all"; shift ;;
        regression|cov)   CMD="regression"; shift ;;
        waves|gui)        CMD="waves"; shift ;;
        sanity|fac|wifi|bt) WAVE_TEST="$1"; shift ;;
        *)
            echo "Unknown: $1  (try: ./sim/run.sh --help)" >&2
            exit 1
            ;;
    esac
done

echo "Project: $ROOT"
[ "$DO_CLEAN" = "1" ] && { echo "Cleaning xcelium.d ..."; rm -rf xcelium.d; }

read -r -a TESTS <<< "$(load_tests)"

case "$CMD" in
    all)
        run_all_tests "${TESTS[@]}"
        ;;
    regression)
        run_regression
        open_imc
        ;;
    waves)
        run_waves "$(map_test "$WAVE_TEST")"
        ;;
esac
