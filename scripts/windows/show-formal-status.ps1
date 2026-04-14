param(
    [string[]]$Targets = @(
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_mmio_wait",
        "formal/simple_cpu_mmio_wait_faults",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_apb_faults",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover"
    )
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
    throw "Python is required to show formal status."
}

$args = @()
$args += $pythonCmd.Arguments
$args += "scripts/show_formal_status.py"
$args += $Targets

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
