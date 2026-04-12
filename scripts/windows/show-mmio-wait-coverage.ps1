param(
    [string]$CoverageFile = "sim_build/mmio_wait_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "MMIO-wait coverage file not found: $CoverageFile. Run .\\scripts\\run-mmio-wait.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "MMIO-wait Coverage Summary"
Write-Host "  pass:                  $($cov.coverage_pass)"
Write-Host "  program_runs:          $($cov.program_runs)"
Write-Host "  external_program_runs: $($cov.external_program_runs)"
Write-Host "  shadow_writes:         $($cov.shadow_writes)"
Write-Host "  shadow_reads:          $($cov.shadow_reads)"
Write-Host "  dmem_reads:            $($cov.dmem_reads)"
Write-Host "  status_reads:          $($cov.status_reads)"
Write-Host "  acc_reads:             $($cov.acc_reads)"
Write-Host "  pc_reads:              $($cov.pc_reads)"
Write-Host "  control_reads:         $($cov.control_reads)"
Write-Host "  start_writes:          $($cov.control_start_writes)"
Write-Host "  stop_writes:           $($cov.control_stop_writes)"
Write-Host "  read_transactions:     $($cov.read_transactions)"
Write-Host "  write_transactions:    $($cov.write_transactions)"
Write-Host "  wait_transactions:     $($cov.wait_transactions)"
Write-Host "  wait_cycles:           $($cov.wait_cycles)"
Write-Host "  max_wait_observed:     $($cov.max_wait_observed)"

if ($cov.state_seen) {
    Write-Host ""
    Write-Host "Wrapper States Seen"
    $cov.state_seen.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
        }
}

if ($cov.coverage_goals) {
    Write-Host ""
    Write-Host "Coverage Goals"
    $cov.coverage_goals.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
        }
}

