param(
    [switch]$NoWaves
)

$ErrorActionPreference = "Stop"

function Add-ToolPathIfPresent {
    param(
        [string]$Root
    )

    if ([string]::IsNullOrWhiteSpace($Root)) {
        return
    }

    $bin = Join-Path $Root "bin"
    $lib = Join-Path $Root "lib"
    if ((Test-Path $bin) -and (Test-Path $lib)) {
        if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $bin })) {
            $env:PATH = "$bin;$env:PATH"
        }
        if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $lib })) {
            $env:PATH = "$lib;$env:PATH"
        }
    }
}

$defaultRoot = Join-Path $HOME "tools\\oss-cad-suite\\oss-cad-suite"
Add-ToolPathIfPresent -Root $env:OSS_CAD_SUITE_ROOT
Add-ToolPathIfPresent -Root $defaultRoot

if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
    throw "iverilog is required. Install Icarus Verilog and retry."
}

if (-not (Get-Command vvp -ErrorAction SilentlyContinue)) {
    throw "vvp is required. It usually comes with Icarus Verilog."
}

New-Item -ItemType Directory -Force -Path sim_build | Out-Null

$iverilogArgs = @("-g2012")
if ($NoWaves) {
    $iverilogArgs += "-DNO_WAVES"
}
$iverilogArgs += @(
    "-o", "sim_build/simple_cpu_wishbone_fault_tb.vvp",
    "rtl/simple_cpu.sv",
    "rtl/simple_cpu_mmio.sv",
    "rtl/simple_cpu_wishbone.sv",
    "tb/simple_cpu_wishbone_assertions.sv",
    "tb/simple_cpu_wishbone_fault_tb.sv"
)

& iverilog @iverilogArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& vvp "sim_build/simple_cpu_wishbone_fault_tb.vvp"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ((Test-Path "sim_build/simple_cpu_wishbone_fault_tb.vcd") -and (-not $NoWaves)) {
    Write-Host "Waveform written to sim_build/simple_cpu_wishbone_fault_tb.vcd"
}

if (Test-Path "sim_build/wishbone_fault_coverage.json") {
    Write-Host "Wishbone fault coverage JSON: sim_build/wishbone_fault_coverage.json"
}

if (Test-Path "sim_build/wishbone_fault_coverage.csv") {
    Write-Host "Wishbone fault coverage CSV:  sim_build/wishbone_fault_coverage.csv"
}

Write-Host "Wishbone fault simulation complete."



