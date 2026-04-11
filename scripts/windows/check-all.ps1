$ErrorActionPreference = "Stop"

& .\scripts\check-native.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\lint.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-static-analysis.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-cocotb-mmio.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-cocotb-mmio-wait.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-uvm.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-mmio-uvm.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-mmio-wait-uvm.ps1 -NoWaves
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\show-verilator-coverage.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-formal.ps1 -Mode all
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& .\scripts\run-equiv.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "All checks passed."
