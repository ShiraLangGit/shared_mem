param(
    [ValidateSet("sanity_fac","wifi_split","bt_split","interface_switch","simultaneous_rw","reset_during_write","fifo_stress_cdc","regression")]
    [string]$Test = "sanity_fac"
)

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$TestMap = @{
    "sanity_fac"          = "test_sanity_fac"
    "wifi_split"          = "test_wifi_split"
    "bt_split"            = "test_bt_split"
    "interface_switch"    = "test_interface_switch"
    "simultaneous_rw"     = "test_simultaneous_rw"
    "reset_during_write"  = "test_reset_during_write"
    "fifo_stress_cdc"     = "test_fifo_stress_cdc"
}

if ($Test -eq "regression") {
    Write-Host "UVM regression runner not yet implemented — run tests individually."
    exit 1
}

$UvmTest = $TestMap[$Test]
if (-not $UvmTest) {
    Write-Host "Unknown test: $Test"
    exit 1
}

$Vlog = Get-Command vlog -ErrorAction SilentlyContinue
$Vsim = Get-Command vsim -ErrorAction SilentlyContinue

if (-not $Vlog -or -not $Vsim) {
    Write-Host "ModelSim/Questa not found in PATH."
    Write-Host ""
    Write-Host "Manual steps:"
    Write-Host "  vlib work"
    Write-Host "  vlog -sv +incdir+rtl +incdir+tb/agents/fac +incdir+tb/agents/wifi +incdir+tb/agents/bt +incdir+tb/agents/read +incdir+tb/envs +incdir+tb/seqs +incdir+tb/tests -f sim/filelist.f"
    Write-Host "  vsim -c shared_memory_tb +UVM_TESTNAME=test_sanity_fac -do `"run -all; quit -f`""
    exit 1
}

if (-not (Test-Path work)) { vlib work }

vlog -sv +incdir+rtl +incdir+tb/agents/fac +incdir+tb/agents/wifi +incdir+tb/agents/bt +incdir+tb/agents/read +incdir+tb/envs +incdir+tb/seqs +incdir+tb/tests -f sim/filelist.f
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

vsim -c shared_memory_tb "+UVM_TESTNAME=$UvmTest" -do "run -all; quit -f"
exit $LASTEXITCODE
