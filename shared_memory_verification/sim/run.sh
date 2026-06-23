#!/bin/bash
# Shared Memory UVM — Xcelium run script
#
# Usage:
#   ./sim/run.sh                  # test_sanity_fac (default)
#   ./sim/run.sh wifi             # test_wifi_split
#   ./sim/run.sh bt               # test_bt_split
#   ./sim/run.sh all              # regression (all 3 tests)
#   ./sim/run.sh --clean wifi     # clean compile + run
#   ./sim/run.sh --imc all        # regression + IMC coverage DB
#
# Run from project root (shared_memory_verification/) or anywhere.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find project root (directory that contains tb/top/shared_memory_tb.sv)
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

echo "Project root: $ROOT"

# --- resolve filenames (server may use typo names) ---
resolve_file() {
    local candidate
    for candidate in "$@"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

resolve_fac_pkg() {
    local found candidate
    for candidate in \
        tb/agents/fac/fac_agent.pkg.sv \
        tb/agents/fac/fac_agent_pkg.sv \
        agents/fac/fac_agent.pkg.sv \
        agents/fac/fac_agent_pkg.sv; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    found="$(find . -path '*/fac/fac_agent*.sv' -o -path '*/fac/fac_agent.pkg.sv' 2>/dev/null | head -1)"
    if [ -n "$found" ] && [ -f "$found" ]; then
        echo "$found"
        return 0
    fi
    echo "ERROR: fac agent package not found." >&2
    echo "  Looked in: tb/agents/fac/" >&2
    if [ -d tb/agents/fac ]; then
        echo "  Found in tb/agents/fac/:" >&2
        ls -1 tb/agents/fac/ >&2
    else
        echo "  Directory tb/agents/fac/ does not exist." >&2
        echo "  Make sure you run from shared_memory_verification/ (with rtl/ and tb/)." >&2
    fi
    exit 1
}

resolve_bt_if() {
    local candidate
    for candidate in rtl/bt_wirte_if.sv rtl/bt_write_if.sv; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    echo "ERROR: BT interface file not found (bt_wirte_if.sv or bt_write_if.sv)." >&2
    exit 1
}

FAC_PKG="$(resolve_fac_pkg)"
BT_IF="$(resolve_bt_if)"

# --- defaults ---
TEST_ARG="sanity"
DO_CLEAN=0
ENABLE_IMC=0

# --- parse args ---
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            sed -n '2,14p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        --clean)
            DO_CLEAN=1
            shift
            ;;
        --imc)
            ENABLE_IMC=1
            shift
            ;;
        sanity|sanity_fac|fac|test_sanity_fac)
            TEST_ARG="sanity"
            shift
            ;;
        wifi|wifi_split|test_wifi_split)
            TEST_ARG="wifi"
            shift
            ;;
        bt|bt_split|test_bt_split)
            TEST_ARG="bt"
            shift
            ;;
        all|regression)
            TEST_ARG="all"
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Run: ./sim/run.sh --help" >&2
            exit 1
            ;;
    esac
done

map_test_name() {
    case "$1" in
        sanity) echo "test_sanity_fac" ;;
        wifi)   echo "test_wifi_split" ;;
        bt)     echo "test_bt_split"  ;;
        *)      echo "$1" ;;
    esac
}

run_one_test() {
    local uvm_test="$1"
    local cov_flags=""

    if [ "$ENABLE_IMC" = "1" ]; then
        cov_flags="-coverage all -covoverwrite -covdut shared_memory"
    fi

    echo "============================================================"
    echo " Running: $uvm_test"
    echo " Project: $ROOT"
    echo "============================================================"

    xrun -sv -uvm -timescale 1ns/1ps -access +rwc -batch \
        $cov_flags \
        -incdir rtl \
        -incdir tb/agents/fac \
        -incdir tb/agents/wifi \
        -incdir tb/agents/bt \
        -incdir tb/agents/read \
        -incdir tb/interfaces \
        -incdir tb/envs \
        -incdir tb/seqs \
        -incdir tb/tests \
        rtl/shared_memory_pkg.sv \
        "$FAC_PKG" \
        tb/agents/wifi/wifi_agent_pkg.sv \
        tb/agents/bt/bt_agent_pkg.sv \
        tb/agents/read/read_agent_pkg.sv \
        tb/envs/shared_memory_env_pkg.sv \
        tb/seqs/fac_seq_pkg.sv \
        tb/seqs/wifi_seq_pkg.sv \
        tb/seqs/bt_seq_pkg.sv \
        tb/seqs/read_seq_pkg.sv \
        tb/seqs/common_seq_pkg.sv \
        tb/tests/shared_memory_test_pkg.sv \
        rtl/async_fifo.sv \
        "$BT_IF" \
        rtl/fac_write_if.sv \
        rtl/wifi_write_if.sv \
        rtl/dual_port_ram.sv \
        rtl/interface_mux.sv \
        rtl/mem_status_ctrl.sv \
        rtl/read_ctrl.sv \
        rtl/shared_memory.sv \
        rtl/write_ctrl.sv \
        tb/agents/fac/fac_if.sv \
        tb/agents/wifi/wifi_if.sv \
        tb/agents/bt/bt_if.sv \
        tb/agents/read/read_if.sv \
        tb/interfaces/ctrl_if.sv \
        tb/top/shared_memory_tb.sv \
        +UVM_TESTNAME="$uvm_test"
}

if [ "$DO_CLEAN" = "1" ]; then
    echo "Cleaning xcelium.d ..."
    rm -rf xcelium.d
fi

if [ "$TEST_ARG" = "all" ]; then
    PASS=0
    FAIL=0
    for t in sanity wifi bt; do
        uvm_test="$(map_test_name "$t")"
        if run_one_test "$uvm_test"; then
            PASS=$((PASS + 1))
        else
            FAIL=$((FAIL + 1))
        fi
    done
    echo "============================================================"
    echo " Regression done: PASS=$PASS  FAIL=$FAIL"
    echo "============================================================"
    [ "$FAIL" -eq 0 ]
else
    run_one_test "$(map_test_name "$TEST_ARG")"
fi
