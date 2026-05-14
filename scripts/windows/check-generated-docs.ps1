param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonExe = "py"
    $pythonArgs = @("-3")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonExe = (Get-Command python).Source
    $pythonArgs = @()
} else {
    throw "Python is required to check generated docs."
}

$checks = @(
    "scripts/isa_report.py",
    "scripts/asm_corpus_report.py",
    "scripts/mutation_catalog.py",
    "scripts/formal_catalog.py",
    "scripts/script_catalog.py",
    "scripts/ci_catalog.py",
    "scripts/tooling_catalog.py",
    "scripts/verification_matrix.py",
    "scripts/artifact_catalog.py",
    "scripts/requirements_traceability.py",
    "scripts/documentation_index.py",
    "scripts/coverage_goals.py",
    "scripts/register_map.py",
    "scripts/protocol_catalog.py",
    "scripts/adapter_contract.py",
    "scripts/reference_regression_catalog.py"
)

foreach ($check in $checks) {
    $args = @()
    $args += $pythonArgs
    $args += @($check, "--check")
    $args += $Arguments
    & $pythonExe @args
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "Generated documentation checks passed."
