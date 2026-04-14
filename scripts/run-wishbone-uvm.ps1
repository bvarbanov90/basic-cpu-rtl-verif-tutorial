param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-wishbone-uvm.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE

