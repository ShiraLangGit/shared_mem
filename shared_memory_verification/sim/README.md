# Shared Memory Block — Simulation

## Prerequisites

Install one of:
- **ModelSim / Questa** (recommended for SystemVerilog)
- **VCS** / **Xcelium**
- **Verilator** (partial SV support)

## Run a single test

From the project root (`shared_memory/`):

### Questa / ModelSim

```tcl
vlib work
vlog -sv +incdir+rtl -f sim/filelist.f
vsim -c shared_memory_tb -do "run -all; quit -f"
```

With test selection:

```tcl
vsim -c shared_memory_tb +TEST=sanity_fac -do "run -all; quit -f"
```

### PowerShell helper

```powershell
cd C:\Users\חני קראוס\shared_memory
.\sim\run.ps1 -Test sanity_fac
.\sim\run.ps1 -Test regression
```

## Available tests (Verification Plan)

| Test name | Plusarg | Description |
|-----------|---------|-------------|
| test_sanity_fac | `sanity_fac` | Basic FAC 32-bit write + readback |
| test_wifi_split | `wifi_split` | WiFi 64-bit → 2×32-bit LE split |
| test_bt_split | `bt_split` | BT 96-bit → 3×32-bit LE split |
| test_interface_switch | `interface_switch` | Dynamic interface_select switching |
| test_simultaneous_rw | `simultaneous_rw` | Concurrent write + read |
| test_reset_during_write | `reset_during_write` | Reset during active write |
| test_fifo_stress_cdc | `fifo_stress_cdc` | WiFi burst CDC/FIFO stress |
| Full regression | `regression` | All tests sequentially |

## Waves

VCD is dumped to `shared_memory.vcd` in the run directory.
Open with GTKWave or the simulator waveform viewer.

## Project structure

```
shared_memory/
├── rtl/           # DUT (from GitHub)
├── tb/            # Testbench, VIP, checkers, tests
├── sim/           # File list and run scripts
└── .cursor/skills/ # Cursor verification agents
```
