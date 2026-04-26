param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-axi-lite-fault.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
