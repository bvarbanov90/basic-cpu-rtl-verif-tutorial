param(
    [string]$CoverageFile = "sim_build/apb_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-apb-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
