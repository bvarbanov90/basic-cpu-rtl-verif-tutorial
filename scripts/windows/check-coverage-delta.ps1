param(
    [string]$CoverageFile = "sim_build/coverage.json",
    [string]$BaselineFile = "docs/coverage-baseline.json"
)

$ErrorActionPreference = "Stop"

$pythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = "py"
        Arguments = @("-3")
    }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = (Get-Command python).Source
        Arguments = @()
    }
} else {
    throw "Python is required for coverage delta checks."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @("scripts/check_coverage_delta.py", "--current", $CoverageFile, "--baseline", $BaselineFile)

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
