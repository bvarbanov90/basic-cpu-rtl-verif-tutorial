param(
    [string]$CoverageFile = "sim_build/axi_lite_coverage.json"
)

$impl = Join-Path $PSScriptRoot "windows\\show-axi-lite-coverage.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE


