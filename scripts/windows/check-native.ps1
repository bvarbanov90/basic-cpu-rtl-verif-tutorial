$ErrorActionPreference = "Stop"

& .\scripts\run.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-mmio.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-mmio-wait.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-apb.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-coverage.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-apb-coverage.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-mmio-wait-coverage.ps1
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

& .\scripts\run-asm-corpus.ps1 -Runner apb
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-asm-corpus.ps1 -Runner mmio_wait
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Native simulation checks passed."
