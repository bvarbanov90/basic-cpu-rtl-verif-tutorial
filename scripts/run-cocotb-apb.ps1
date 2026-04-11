param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-cocotb-apb.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
