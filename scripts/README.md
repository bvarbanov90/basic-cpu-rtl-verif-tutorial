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
6. `run-mmio-wait` (`run-mmio-wait.ps1` / `run-mmio-wait.sh`)
7. `run-apb` (`run-apb.ps1` / `run-apb.sh`)
8. `run-wishbone` (`run-wishbone.ps1` / `run-wishbone.sh`)
9. `run-apb-fault` (`run-apb-fault.ps1` / `run-apb-fault.sh`)
10. `run-wishbone-fault` (`run-wishbone-fault.ps1` / `run-wishbone-fault.sh`)
11. `run-mutations` (`run-mutations.ps1` / `run-mutations.sh`)
12. `check-native` (`check-native.ps1` / `check-native.sh`)
13. `check-all` (`check-all.ps1` / `check-all.sh`)
14. `check-coverage-delta` (`check-coverage-delta.ps1` / `check-coverage-delta.sh`)
15. `update-coverage-baseline` (`update-coverage-baseline.ps1` / `update-coverage-baseline.sh`)
16. `run-formal` (`run-formal.ps1` / `run-formal.sh`)
17. `run-cocotb-verilator` (`run-cocotb-verilator.ps1` / `run-cocotb-verilator.sh`)
18. `run-cocotb-mmio` (`run-cocotb-mmio.ps1` / `run-cocotb-mmio.sh`)
19. `run-mmio-uvm` (`run-mmio-uvm.ps1` / `run-mmio-uvm.sh`)
20. `run-cocotb-mmio-wait` (`run-cocotb-mmio-wait.ps1` / `run-cocotb-mmio-wait.sh`)
21. `run-mmio-wait-uvm` (`run-mmio-wait-uvm.ps1` / `run-mmio-wait-uvm.sh`)
22. `run-cocotb-apb` (`run-cocotb-apb.ps1` / `run-cocotb-apb.sh`)
23. `run-apb-uvm` (`run-apb-uvm.ps1` / `run-apb-uvm.sh`)
24. `run-cocotb-wishbone` (`run-cocotb-wishbone.ps1` / `run-cocotb-wishbone.sh`)
25. `run-wishbone-uvm` (`run-wishbone-uvm.ps1` / `run-wishbone-uvm.sh`)
26. `run-equiv` (`run-equiv.ps1` / `run-equiv.sh`)
27. `update-equivalence-golden` (`update-equivalence-golden.ps1` / `update-equivalence-golden.sh`)
28. `format-sv` (`format-sv.ps1` / `format-sv.sh`)
29. `show-static-analysis` (`show-static-analysis.ps1` / `show-static-analysis.sh`)
30. `show-coverage` (`show-coverage.ps1` / `show-coverage.sh`)
31. `show-mmio-coverage` (`show-mmio-coverage.ps1` / `show-mmio-coverage.sh`)
32. `show-mmio-wait-coverage` (`show-mmio-wait-coverage.ps1` / `show-mmio-wait-coverage.sh`)
33. `show-apb-coverage` (`show-apb-coverage.ps1` / `show-apb-coverage.sh`)
34. `show-wishbone-coverage` (`show-wishbone-coverage.ps1` / `show-wishbone-coverage.sh`)
35. `show-apb-fault-coverage` (`show-apb-fault-coverage.ps1` / `show-apb-fault-coverage.sh`)
36. `show-wishbone-fault-coverage` (`show-wishbone-fault-coverage.ps1` / `show-wishbone-fault-coverage.sh`)
37. `show-verilator-coverage` (`show-verilator-coverage.ps1` / `show-verilator-coverage.sh`)
38. `record-coverage-history` (`record-coverage-history.ps1` / `record-coverage-history.sh`)
39. `show-coverage-trend` (`show-coverage-trend.ps1` / `show-coverage-trend.sh`)
40. `show-mutations` (`show-mutations.ps1` / `show-mutations.sh`)
41. `show-formal-status` (`show-formal-status.ps1` / `show-formal-status.sh`)
42. `export-status` (`export-status.ps1` / `export-status.sh`)

When adding a new automation flow:

1. Add the implementation under `scripts/windows/` and `scripts/linux/` when applicable.
2. Add/update the top-level wrapper so legacy command paths keep working.
3. Update `README.md` and `docs/verification-plan.md` if usage or behavior changes.

Static-analysis note:

1. `scripts/static_analysis.py` intentionally gives Verible and svlint different source scopes. Verible targets the hand-written SV files that the current release parses cleanly, while svlint stays focused on synthesizable RTL.

Formal note:

1. `run-formal` now includes the dedicated `formal/simple_cpu_mmio_wait_faults.sby`, `formal/simple_cpu_apb_faults.sby`, and `formal/simple_cpu_wishbone_faults.sby` targets in prove mode, plus the APB/Wishbone prove/cover targets, so protocol-specific fault scenarios stay separated from the lighter baseline wrapper contracts.

Conformance note:

1. The shared wrapper conformance layer in `tb/protocol_conformance.py` assumes each Python bus adapter exposes the same high-level methods (`reset`, `load_program`, `verify_loaded_program`, `begin_execution`, `run_until_halt`, `sample_state`). Keep new wrapper adapters aligned with that interface so the same scenario suite can run across MMIO, MMIO-wait, APB, Wishbone, and future protocols unchanged.

Mutation note:

1. `scripts/run_mutation_campaign.py` now builds APB, Wishbone, and MMIO-wait protocol-shell mutants through helper templates (`make_assign_mutation`, `make_port_mutation`, `make_localparam_mutation`) so extending a new wrapper family does not require hand-writing every mutation block.
