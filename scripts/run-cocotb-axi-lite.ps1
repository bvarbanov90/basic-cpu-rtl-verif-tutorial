param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-cocotb-axi-lite.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
