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

if (-not (Get-Command make -ErrorAction SilentlyContinue)) {
    throw "make is required for cocotb/pyuvm runs."
}

$pythonBin = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $py313 = & py -3.13 -c "import sys; print(sys.executable)" 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($py313)) {
        $pythonBin = $py313.Trim()
    }
}
if (-not $pythonBin -and (Get-Command python -ErrorAction SilentlyContinue)) {
    $pythonBin = (Get-Command python).Source
}
if (-not $pythonBin) {
    throw "Python is required for cocotb/pyuvm runs. Install Python 3.13 and retry."
}

& $pythonBin -c "import sys; assert sys.version_info < (3,14); import cocotb, pyuvm" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python < 3.14 with cocotb and pyuvm is required. Install with: py -3.13 -m pip install -r requirements.txt"
}

New-Item -ItemType Directory -Force -Path sim_build | Out-Null

$projectRoot = (Resolve-Path ".").Path
if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) {
    $env:PYTHONPATH = $projectRoot
} else {
    $env:PYTHONPATH = "$projectRoot;$env:PYTHONPATH"
}

$env:COCOTB_TEST_MODULES = "tb.test_simple_cpu_pyuvm"
$env:SIM = "icarus"
$env:SIM_BUILD = "sim_build/pyuvm"
$env:COCOTB_RESULTS_FILE = "sim_build/uvm_results.xml"
$env:WAVES = if ($NoWaves) { "0" } else { "1" }
$env:PYTHON_BIN = $pythonBin

& make -f Makefile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "pyuvm run complete."
Write-Host "Results XML: sim_build/uvm_results.xml"
