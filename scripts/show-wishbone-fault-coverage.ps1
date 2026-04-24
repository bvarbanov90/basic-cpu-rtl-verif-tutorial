param(
    [string]$CoverageFile = "sim_build/wishbone_fault_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-wishbone-fault-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE



