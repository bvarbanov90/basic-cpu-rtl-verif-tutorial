param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-apb-fault.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
