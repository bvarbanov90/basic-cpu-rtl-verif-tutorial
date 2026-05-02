$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Test-PythonHasPytest {
    param(
        [string]$Executable,
        [string[]]$Arguments = @()
    )

    $checkArgs = @()
    $checkArgs += $Arguments
    $checkArgs += @("-c", "import importlib.util, sys; sys.exit(0 if sys.version_info < (3, 14) and importlib.util.find_spec('pytest') else 1)")
    try {
        & $Executable @checkArgs *> $null
    } catch {
        return $false
    }
    return ($LASTEXITCODE -eq 0)
}

function Test-PythonVersionSupported {
    param(
        [string]$Executable,
        [string[]]$Arguments = @()
    )

    $checkArgs = @()
    $checkArgs += $Arguments
    $checkArgs += @("-c", "import sys; sys.exit(0 if sys.version_info < (3, 14) else 1)")
    try {
        & $Executable @checkArgs *> $null
    } catch {
        return $false
    }
    return ($LASTEXITCODE -eq 0)
}

function Get-PythonCandidates {
    $candidates = @()
    $candidatePaths = @(
        ".venv_ci\Scripts\python.exe",
        ".venv_model_win\Scripts\python.exe",
        ".venv\Scripts\python.exe",
        ".venv_pyuvm_probe\Scripts\python.exe"
    )

    foreach ($path in $candidatePaths) {
        if (Test-Path $path) {
            $candidates += @{ Executable = (Resolve-Path $path).Path; Arguments = @() }
        }
    }

    if (Get-Command py -ErrorAction SilentlyContinue) {
        $candidates += @{ Executable = "py"; Arguments = @("-3.13") }
        $candidates += @{ Executable = "py"; Arguments = @("-3.12") }
        $candidates += @{ Executable = "py"; Arguments = @("-3") }
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $candidates += @{ Executable = (Get-Command python).Source; Arguments = @() }
    }

    return $candidates
}

function Find-PythonWithPytest {
    foreach ($candidate in (Get-PythonCandidates)) {
        if (Test-PythonHasPytest -Executable $candidate.Executable -Arguments $candidate.Arguments) {
            return $candidate
        }
    }

    return $null
}

$pythonCmd = Find-PythonWithPytest
if (-not $pythonCmd) {
    $basePython = $null
    foreach ($candidate in (Get-PythonCandidates)) {
        if (Test-PythonVersionSupported -Executable $candidate.Executable -Arguments $candidate.Arguments) {
            $basePython = $candidate
            break
        }
    }

    if (-not $basePython) {
        throw "Python < 3.14 is required for reference model checks."
    }

    $venvArgs = @()
    $venvArgs += $basePython.Arguments
    $venvArgs += @("-m", "venv", ".venv_model_win")
    & $basePython.Executable @venvArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $venvPython = (Resolve-Path ".venv_model_win\Scripts\python.exe").Path
    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    & $venvPython -m pip install "pytest>=8.0"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $pythonCmd = @{ Executable = $venvPython; Arguments = @() }
}

$env:PYTHONPATH = (Get-Location).Path + $(if ($env:PYTHONPATH) { ";$env:PYTHONPATH" } else { "" })

$pytestArgs = @()
$pytestArgs += $pythonCmd.Arguments
$pytestArgs += @("-m", "pytest", "-q", "tb/test_cpu_lib_unit.py")
& $pythonCmd.Executable @pytestArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$isaArgs = @()
$isaArgs += $pythonCmd.Arguments
$isaArgs += @("scripts/isa_report.py", "--check")
& $pythonCmd.Executable @isaArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force -Path "sim_build/model_trace" | Out-Null

$traceArgs = @()
$traceArgs += $pythonCmd.Arguments
$traceArgs += @("scripts/model_trace.py", "--builtin", "smoke", "--format", "table", "--output", "sim_build/model_trace/smoke.txt")
& $pythonCmd.Executable @traceArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$jsonArgs = @()
$jsonArgs += $pythonCmd.Arguments
$jsonArgs += @("scripts/model_trace.py", "--builtin", "branch", "--format", "json", "--output", "sim_build/model_trace/branch.json")
& $pythonCmd.Executable @jsonArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Python reference model checks passed."
