param(
    [string]$CoverageFile = "sim_build/axi_lite_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "AXI-Lite coverage file not found: $CoverageFile. Run .\\scripts\\run-axi-lite.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "AXI-Lite Coverage Summary"
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
Write-Host "  setup_phases:          $($cov.setup_phases)"
Write-Host "  access_phases:         $($cov.access_phases)"
Write-Host "  read_accesses:         $($cov.read_accesses)"
Write-Host "  write_accesses:        $($cov.write_accesses)"
Write-Host "  partial_write_attempts:$($cov.partial_write_attempts)"

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


