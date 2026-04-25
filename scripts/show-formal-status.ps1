param(
    [string[]]$Targets = @(
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_mmio_wait",
        "formal/simple_cpu_mmio_wait_faults",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_wishbone",
        "formal/simple_cpu_axi_lite",
        "formal/simple_cpu_apb_faults",
        "formal/simple_cpu_wishbone_faults",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover",
        "formal/simple_cpu_wishbone_cover",
        "formal/simple_cpu_axi_lite_cover"
    )
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\show-formal-status.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
