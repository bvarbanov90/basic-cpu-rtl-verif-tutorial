param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-axi-lite-uvm.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
