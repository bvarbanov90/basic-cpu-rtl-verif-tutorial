param(
    [string]$CoverageFile = "sim_build/apb_fault_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-apb-fault-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
