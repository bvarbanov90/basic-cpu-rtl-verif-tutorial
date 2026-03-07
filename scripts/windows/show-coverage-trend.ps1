param(
    [string]$HistoryFile = "docs/coverage-history.json",
    [int]$Limit = 12
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
    throw "Python is required to show coverage trends."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @(
    "scripts/coverage_history.py",
    "report",
    "--history", $HistoryFile,
    "--limit", $Limit
)

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
