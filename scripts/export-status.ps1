param(
    [string]$Core = "sim_build/coverage.json",
    [string]$Mmio = "sim_build/mmio_coverage.json",
    [string]$MmioWait = "sim_build/mmio_wait_coverage.json",
    [string]$Apb = "sim_build/apb_coverage.json",
    [string]$Wishbone = "sim_build/wishbone_coverage.json",
    [string]$AxiLite = "sim_build/axi_lite_coverage.json",
    [string]$ApbFault = "sim_build/apb_fault_coverage.json",
    [string]$WishboneFault = "sim_build/wishbone_fault_coverage.json",
    [string]$AxiLiteFault = "sim_build/axi_lite_fault_coverage.json",
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
    [string]$AxiLiteCocotb = "sim_build/axi_lite_cocotb_results.xml",
    [string]$AxiLitePyuvm = "sim_build/axi_lite_uvm_results.xml",
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
        "formal/simple_cpu_axi_lite",
        "formal/simple_cpu_apb_faults",
        "formal/simple_cpu_wishbone_faults",
        "formal/simple_cpu_axi_lite_faults",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover",
        "formal/simple_cpu_wishbone_cover",
        "formal/simple_cpu_axi_lite_cover"
    ),
    [string]$StatusJson = "docs/status/status.json",
    [string]$StatusMarkdown = "docs/status/status.md",
    [string]$BadgeDir = "docs/status/badges",
    [string]$Label = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\export-status.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
