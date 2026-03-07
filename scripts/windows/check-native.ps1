$ErrorActionPreference = "Stop"

& .\scripts\run.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-mmio.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-coverage.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\check-coverage-delta.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-asm-corpus.ps1 -NoSimulate
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Native simulation checks passed."
