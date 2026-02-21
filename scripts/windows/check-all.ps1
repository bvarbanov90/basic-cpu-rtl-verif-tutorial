$ErrorActionPreference = "Stop"

& .\scripts\run.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\lint.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-formal.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-coverage.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "All checks passed."
