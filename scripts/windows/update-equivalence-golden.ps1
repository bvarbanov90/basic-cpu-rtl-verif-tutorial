$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path equiv | Out-Null
Copy-Item rtl\simple_cpu.sv equiv\simple_cpu_golden.sv -Force

Write-Host "Updated equivalence golden snapshot: equiv/simple_cpu_golden.sv"
