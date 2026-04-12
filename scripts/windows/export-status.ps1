param(
    [string]$Core = "sim_build/coverage.json",
    [string]$Mmio = "sim_build/mmio_coverage.json",
    [string]$Apb = "sim_build/apb_coverage.json",
    [string]$Pyuvm = "sim_build/pyuvm_coverage.json",
    [string]$Mutations = "sim_build/mutations/mutation_summary.json",
    [string]$VerilatorCoverage = "sim_build/verilator_coverage/summary.json",
    [string]$Equivalence = "equiv/simple_cpu_eqy",
    [string]$StaticAnalysis = "sim_build/static_analysis/summary.json",
    [string]$History = "docs/coverage-history.json",
    [string[]]$FormalTargets = @(
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_apb_cover"
    ),
    [string]$StatusJson = "docs/status/status.json",
    [string]$StatusMarkdown = "docs/status/status.md",
    [string]$BadgeDir = "docs/status/badges",
    [string]$Label = ""
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
    throw "Python is required to export status."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @(
    "scripts/export_status.py",
    "--core", $Core,
    "--mmio", $Mmio,
    "--apb", $Apb,
    "--pyuvm", $Pyuvm,
    "--mutations", $Mutations,
    "--verilator-coverage", $VerilatorCoverage,
    "--equivalence", $Equivalence,
    "--static-analysis", $StaticAnalysis,
    "--history", $History,
    "--status-json", $StatusJson,
    "--status-markdown", $StatusMarkdown,
    "--badge-dir", $BadgeDir
)

foreach ($target in $FormalTargets) {
    $args += @("--formal-target", $target)
}

if (-not [string]::IsNullOrWhiteSpace($Label)) {
    $args += @("--label", $Label)
}

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
