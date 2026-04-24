param(
    [string]$CoverageFile = "sim_build/wishbone_fault_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "Wishbone fault coverage file not found: $CoverageFile. Run .\\scripts\\run-wishbone-fault.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "Wishbone Fault Coverage Summary"
Write-Host "  pass:                          $($cov.coverage_pass)"
Write-Host "  cycle_only_writes_ignored:     $($cov.cycle_only_writes_ignored)"
Write-Host "  aborted_writes_ignored:        $($cov.aborted_writes_ignored)"
Write-Host "  cycle_only_starts_ignored:     $($cov.cycle_only_starts_ignored)"
Write-Host "  strobe_without_cycle_ignored:  $($cov.strobe_without_cycle_ignored)"
Write-Host "  shadow_fault_write_observed:   $($cov.shadow_fault_write_observed)"
Write-Host "  deferred_shadow_updates:       $($cov.deferred_shadow_updates)"
Write-Host "  reload_observed_updates:       $($cov.reload_observed_updates)"
Write-Host "  program_runs:                  $($cov.program_runs)"
Write-Host "  fault_readbacks:               $($cov.fault_readbacks)"

if ($cov.coverage_goals) {
    Write-Host ""
    Write-Host "Coverage Goals"
    $cov.coverage_goals.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
        }
}



