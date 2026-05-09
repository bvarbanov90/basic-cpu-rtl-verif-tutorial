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
    throw "Python is required to generate requirements traceability."
}

$args = @()
$args += $pythonArgs
$args += @("scripts/requirements_traceability.py")
$args += $Arguments

& $pythonExe @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
