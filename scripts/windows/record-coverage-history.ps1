param(
    [string]$CoreCoverage = "sim_build/coverage.json",
    [string]$MmioCoverage = "sim_build/mmio_coverage.json",
    [string]$HistoryFile = "docs/coverage-history.json",
    [string]$MarkdownFile = "docs/coverage-history.md",
    [string]$Label = "tutorial-regression",
    [int]$Limit = 12,
    [int]$MaxEntries = 64
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
    throw "Python is required to record coverage history."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @(
    "scripts/coverage_history.py",
    "snapshot",
    "--core", $CoreCoverage,
    "--mmio", $MmioCoverage,
    "--history", $HistoryFile,
    "--markdown", $MarkdownFile,
    "--label", $Label,
    "--limit", $Limit,
    "--max-entries", $MaxEntries
)

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
