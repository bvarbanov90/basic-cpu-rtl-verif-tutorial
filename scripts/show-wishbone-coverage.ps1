param(
    [string]$CoverageFile = "sim_build/wishbone_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-wishbone-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE

