param(
    [string]$Core = "sim_build/coverage.json",
    [string]$Mmio = "sim_build/mmio_coverage.json",
    [string]$MmioWait = "sim_build/mmio_wait_coverage.json",
    [string]$Apb = "sim_build/apb_coverage.json",
    [string]$Wishbone = "sim_build/wishbone_coverage.json",
    [string]$ApbFault = "sim_build/apb_fault_coverage.json",
    [string]$WishboneFault = "sim_build/wishbone_fault_coverage.json",
    [string]$Pyuvm = "sim_build/pyuvm_coverage.json",
    [string]$CocotbVerilator = "sim_build/verilator_results.xml",
    [string]$MmioCocotb = "sim_build/mmio_cocotb_results.xml",
    [string]$MmioPyuvm = "sim_build/mmio_uvm_results.xml",
    [string]$MmioWaitCocotb = "sim_build/mmio_wait_cocotb_results.xml",
    [string]$MmioWaitPyuvm = "sim_build/mmio_wait_uvm_results.xml",
    [string]$ApbCocotb = "sim_build/apb_cocotb_results.xml",
    [string]$ApbPyuvm = "sim_build/apb_uvm_results.xml",
    [string]$WishboneCocotb = "sim_build/wishbone_cocotb_results.xml",
    [string]$WishbonePyuvm = "sim_build/wishbone_uvm_results.xml",
    [string]$Mutations = "sim_build/mutations/mutation_summary.json",
    [string]$VerilatorCoverage = "sim_build/verilator_coverage/summary.json",
    [string]$Equivalence = "equiv/simple_cpu_eqy",
    [string]$StaticAnalysis = "sim_build/static_analysis/summary.json",
    [string]$History = "docs/coverage-history.json",
    [string[]]$FormalTargets = @(
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_mmio_wait",
        "formal/simple_cpu_mmio_wait_faults",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_wishbone",
        "formal/simple_cpu_apb_faults",
        "formal/simple_cpu_wishbone_faults",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover",
        "formal/simple_cpu_wishbone_cover"
    ),
    [string]$StatusJson = "docs/status/status.json",
    [string]$StatusMarkdown = "docs/status/status.md",
    [string]$BadgeDir = "docs/status/badges",
    [string]$Label = ""
)

$ErrorActionPreference = "Stop"

$pythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = "py"
        Arguments = @("-3")
    }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = (Get-Command python).Source
        Arguments = @()
    }
} else {
    throw "Python is required to export status."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @(
    "scripts/export_status.py",
    "--core", $Core,
    "--mmio", $Mmio,
    "--mmio-wait", $MmioWait,
    "--apb", $Apb,
    "--wishbone", $Wishbone,
    "--apb-fault", $ApbFault,
    "--wishbone-fault", $WishboneFault,
    "--pyuvm", $Pyuvm,
    "--cocotb-verilator", $CocotbVerilator,
    "--mmio-cocotb", $MmioCocotb,
    "--mmio-pyuvm", $MmioPyuvm,
    "--mmio-wait-cocotb", $MmioWaitCocotb,
    "--mmio-wait-pyuvm", $MmioWaitPyuvm,
    "--apb-cocotb", $ApbCocotb,
    "--apb-pyuvm", $ApbPyuvm,
    "--wishbone-cocotb", $WishboneCocotb,
    "--wishbone-pyuvm", $WishbonePyuvm,
    "--mutations", $Mutations,
    "--verilator-coverage", $VerilatorCoverage,
    "--equivalence", $Equivalence,
    "--static-analysis", $StaticAnalysis,
    "--history", $History,
    "--status-json", $StatusJson,
    "--status-markdown", $StatusMarkdown,
    "--badge-dir", $BadgeDir
)

foreach ($target in $FormalTargets) {
    $args += @("--formal-target", $target)
}

if (-not [string]::IsNullOrWhiteSpace($Label)) {
    $args += @("--label", $Label)
}

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
