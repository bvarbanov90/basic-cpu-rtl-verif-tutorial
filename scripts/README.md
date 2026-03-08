# Scripts Layout

This directory is split by platform:

1. `windows/`: PowerShell and CMD implementations.
2. `linux/`: bash implementations for Linux/WSL.
3. Top-level `scripts/*.ps1` and `scripts/*.sh`: compatibility wrappers that call into the platform directories.

Common entrypoints:

1. `run` (`run.ps1` / `run.sh`)
2. `run-asm` (`run-asm.ps1` / `run-asm.sh`)
3. `run-uvm` (`run-uvm.ps1` / `run-uvm.sh`)
4. `run-asm-corpus` (`run-asm-corpus.ps1` / `run-asm-corpus.sh`)
5. `run-mmio` (`run-mmio.ps1` / `run-mmio.sh`)
6. `run-mutations` (`run-mutations.ps1` / `run-mutations.sh`)
7. `check-native` (`check-native.ps1` / `check-native.sh`)
8. `check-all` (`check-all.ps1` / `check-all.sh`)
9. `check-coverage-delta` (`check-coverage-delta.ps1` / `check-coverage-delta.sh`)
10. `update-coverage-baseline` (`update-coverage-baseline.ps1` / `update-coverage-baseline.sh`)
11. `run-formal` (`run-formal.ps1` / `run-formal.sh`)
12. `run-cocotb-verilator` (`run-cocotb-verilator.ps1` / `run-cocotb-verilator.sh`)
13. `run-equiv` (`run-equiv.ps1` / `run-equiv.sh`)
14. `update-equivalence-golden` (`update-equivalence-golden.ps1` / `update-equivalence-golden.sh`)
15. `show-coverage` (`show-coverage.ps1` / `show-coverage.sh`)
16. `show-mmio-coverage` (`show-mmio-coverage.ps1` / `show-mmio-coverage.sh`)
17. `show-verilator-coverage` (`show-verilator-coverage.ps1` / `show-verilator-coverage.sh`)
18. `record-coverage-history` (`record-coverage-history.ps1` / `record-coverage-history.sh`)
19. `show-coverage-trend` (`show-coverage-trend.ps1` / `show-coverage-trend.sh`)
20. `show-mutations` (`show-mutations.ps1` / `show-mutations.sh`)
21. `show-formal-status` (`show-formal-status.ps1` / `show-formal-status.sh`)
22. `export-status` (`export-status.ps1` / `export-status.sh`)

When adding a new automation flow:

1. Add the implementation under `scripts/windows/` and `scripts/linux/` when applicable.
2. Add/update the top-level wrapper so legacy command paths keep working.
3. Update `README.md` and `docs/verification-plan.md` if usage or behavior changes.
