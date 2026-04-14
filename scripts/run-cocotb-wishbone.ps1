param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-cocotb-wishbone.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE

