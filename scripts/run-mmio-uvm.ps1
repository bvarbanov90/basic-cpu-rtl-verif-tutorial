param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-mmio-uvm.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
