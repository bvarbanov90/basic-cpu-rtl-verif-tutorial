param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-apb-uvm.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
