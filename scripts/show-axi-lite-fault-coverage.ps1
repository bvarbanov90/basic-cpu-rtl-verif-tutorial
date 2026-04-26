param(
    [string]$CoverageFile = "sim_build/axi_lite_fault_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-axi-lite-fault-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
