param(
    [string]$Core = "sim_build/coverage.json",
    [string]$Mmio = "sim_build/mmio_coverage.json",
    [string]$Pyuvm = "sim_build/pyuvm_coverage.json",
    [string]$Mutations = "sim_build/mutations/mutation_summary.json",
    [string]$History = "docs/coverage-history.json",
    [string[]]$FormalTargets = @(
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_mmio_wait",
        "formal/simple_cpu_mmio_wait_faults",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_apb_faults",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover"
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
