# Scripts Layout

This directory is split by platform:

1. `windows/`: PowerShell and CMD implementations.
2. `linux/`: bash implementations for Linux/WSL.
3. Top-level `scripts/*.ps1` and `scripts/*.sh`: compatibility wrappers that call into the platform directories.

Common entrypoints:

1. `run` (`run.ps1` / `run.sh`)
2. `run-asm` (`run-asm.ps1` / `run-asm.sh`)
3. `generate-isa-docs` (`generate-isa-docs.ps1` / `generate-isa-docs.sh`)
4. `generate-asm-corpus-docs` (`generate-asm-corpus-docs.ps1` / `generate-asm-corpus-docs.sh`)
5. `generate-formal-catalog` (`generate-formal-catalog.ps1` / `generate-formal-catalog.sh`)
6. `generate-mutation-catalog` (`generate-mutation-catalog.ps1` / `generate-mutation-catalog.sh`)
7. `generate-script-catalog` (`generate-script-catalog.ps1` / `generate-script-catalog.sh`)
8. `generate-ci-catalog` (`generate-ci-catalog.ps1` / `generate-ci-catalog.sh`)
9. `generate-tooling-catalog` (`generate-tooling-catalog.ps1` / `generate-tooling-catalog.sh`)
10. `generate-verification-matrix` (`generate-verification-matrix.ps1` / `generate-verification-matrix.sh`)
11. `run-uvm` (`run-uvm.ps1` / `run-uvm.sh`)
12. `run-asm-corpus` (`run-asm-corpus.ps1` / `run-asm-corpus.sh`)
13. `run-mmio` (`run-mmio.ps1` / `run-mmio.sh`)
14. `run-mmio-wait` (`run-mmio-wait.ps1` / `run-mmio-wait.sh`)
15. `run-apb` (`run-apb.ps1` / `run-apb.sh`)
16. `run-wishbone` (`run-wishbone.ps1` / `run-wishbone.sh`)
17. `run-axi-lite` (`run-axi-lite.ps1` / `run-axi-lite.sh`)
18. `run-axi-lite-fault` (`run-axi-lite-fault.ps1` / `run-axi-lite-fault.sh`)
19. `run-apb-fault` (`run-apb-fault.ps1` / `run-apb-fault.sh`)
20. `run-wishbone-fault` (`run-wishbone-fault.ps1` / `run-wishbone-fault.sh`)
21. `run-mutations` (`run-mutations.ps1` / `run-mutations.sh`)
22. `check-python-model` (`check-python-model.ps1` / `check-python-model.sh`)
23. `check-native` (`check-native.ps1` / `check-native.sh`)
24. `check-all` (`check-all.ps1` / `check-all.sh`)
25. `check-coverage-delta` (`check-coverage-delta.ps1` / `check-coverage-delta.sh`)
26. `update-coverage-baseline` (`update-coverage-baseline.ps1` / `update-coverage-baseline.sh`)
27. `run-formal` (`run-formal.ps1` / `run-formal.sh`)
28. `run-cocotb-verilator` (`run-cocotb-verilator.ps1` / `run-cocotb-verilator.sh`)
29. `run-cocotb-mmio` (`run-cocotb-mmio.ps1` / `run-cocotb-mmio.sh`)
30. `run-mmio-uvm` (`run-mmio-uvm.ps1` / `run-mmio-uvm.sh`)
31. `run-cocotb-mmio-wait` (`run-cocotb-mmio-wait.ps1` / `run-cocotb-mmio-wait.sh`)
32. `run-mmio-wait-uvm` (`run-mmio-wait-uvm.ps1` / `run-mmio-wait-uvm.sh`)
33. `run-cocotb-apb` (`run-cocotb-apb.ps1` / `run-cocotb-apb.sh`)
34. `run-apb-uvm` (`run-apb-uvm.ps1` / `run-apb-uvm.sh`)
35. `run-cocotb-wishbone` (`run-cocotb-wishbone.ps1` / `run-cocotb-wishbone.sh`)
36. `run-wishbone-uvm` (`run-wishbone-uvm.ps1` / `run-wishbone-uvm.sh`)
37. `run-cocotb-axi-lite` (`run-cocotb-axi-lite.ps1` / `run-cocotb-axi-lite.sh`)
38. `run-axi-lite-uvm` (`run-axi-lite-uvm.ps1` / `run-axi-lite-uvm.sh`)
39. `run-equiv` (`run-equiv.ps1` / `run-equiv.sh`)
40. `update-equivalence-golden` (`update-equivalence-golden.ps1` / `update-equivalence-golden.sh`)
41. `format-sv` (`format-sv.ps1` / `format-sv.sh`)
42. `lint` (`lint.ps1` / `lint.sh`)
43. `show-static-analysis` (`show-static-analysis.ps1` / `show-static-analysis.sh`)
44. `open-waves` (`open-waves.ps1` / `open-waves.sh`)
45. `show-model-trace` (`show-model-trace.ps1` / `show-model-trace.sh`)
46. `show-coverage` (`show-coverage.ps1` / `show-coverage.sh`)
47. `show-mmio-coverage` (`show-mmio-coverage.ps1` / `show-mmio-coverage.sh`)
48. `show-mmio-wait-coverage` (`show-mmio-wait-coverage.ps1` / `show-mmio-wait-coverage.sh`)
49. `show-apb-coverage` (`show-apb-coverage.ps1` / `show-apb-coverage.sh`)
50. `show-wishbone-coverage` (`show-wishbone-coverage.ps1` / `show-wishbone-coverage.sh`)
51. `show-axi-lite-coverage` (`show-axi-lite-coverage.ps1` / `show-axi-lite-coverage.sh`)
52. `show-axi-lite-fault-coverage` (`show-axi-lite-fault-coverage.ps1` / `show-axi-lite-fault-coverage.sh`)
53. `show-apb-fault-coverage` (`show-apb-fault-coverage.ps1` / `show-apb-fault-coverage.sh`)
54. `show-wishbone-fault-coverage` (`show-wishbone-fault-coverage.ps1` / `show-wishbone-fault-coverage.sh`)
55. `show-verilator-coverage` (`show-verilator-coverage.ps1` / `show-verilator-coverage.sh`)
56. `record-coverage-history` (`record-coverage-history.ps1` / `record-coverage-history.sh`)
57. `show-coverage-trend` (`show-coverage-trend.ps1` / `show-coverage-trend.sh`)
58. `show-mutations` (`show-mutations.ps1` / `show-mutations.sh`)
59. `show-formal-status` (`show-formal-status.ps1` / `show-formal-status.sh`)
60. `export-status` (`export-status.ps1` / `export-status.sh`)

When adding a new automation flow:

1. Add the implementation under `scripts/windows/` and `scripts/linux/` when applicable.
2. Add/update the top-level wrapper so legacy command paths keep working.
3. Update `README.md` and `docs/verification-plan.md` if usage or behavior changes.

Static-analysis note:

1. `scripts/static_analysis.py` intentionally gives Verible and svlint different source scopes. Verible targets the hand-written SV files that the current release parses cleanly, while svlint stays focused on synthesizable RTL.

Formal note:

1. `run-formal` now includes the dedicated `formal/simple_cpu_mmio_wait_faults.sby`, `formal/simple_cpu_apb_faults.sby`, `formal/simple_cpu_wishbone_faults.sby`, and `formal/simple_cpu_axi_lite_faults.sby` targets in prove mode, plus the APB/Wishbone/AXI-Lite prove/cover targets, so protocol-specific fault scenarios stay separated from the lighter baseline wrapper contracts. `scripts/formal_catalog.py` validates the `.sby` inventory against both platform wrappers and generates `docs/formal-targets.md` for review.

Toolchain note:

1. `scripts/linux/oss-cad-suite.sh` is shared by Linux EQY and cocotb/Verilator flows. Export `OSS_CAD_SUITE_RELEASE_TAG=YYYY-MM-DD` to pin a daily Linux OSS CAD Suite build; leave it unset to use the latest release.

Conformance note:

1. The shared wrapper conformance layer in `tb/protocol_conformance.py` assumes each Python bus adapter exposes the same high-level methods (`reset`, `load_program`, `verify_loaded_program`, `begin_execution`, `run_until_halt`, `sample_state`). Keep new wrapper adapters aligned with that interface so the same scenario suite can run across MMIO, MMIO-wait, APB, Wishbone, AXI-Lite, and future protocols unchanged.

Reference-model note:

1. `scripts/check-python-model.*` runs `tb/test_cpu_lib_unit.py`, `tb/test_asm_unit.py`, `tb/test_mutation_unit.py`, `tb/test_formal_catalog_unit.py`, `tb/test_script_catalog_unit.py`, `tb/test_ci_catalog_unit.py`, `tb/test_tooling_catalog_unit.py`, and `tb/test_verification_matrix_unit.py`, checks generated ISA, assembler-corpus, mutation-catalog, formal-target, script-catalog, CI-catalog, tooling-catalog, and verification-matrix docs, and emits example traces under `sim_build/model_trace`; `scripts/show-model-trace.*` is the interactive wrapper around the same disassembly/trace utility.

Mutation note:

1. `scripts/run_mutation_campaign.py` now builds APB, Wishbone, AXI-Lite, and MMIO-wait protocol-shell mutants through helper templates (`make_assign_mutation`, `make_port_mutation`, `make_localparam_mutation`) so extending a new wrapper family does not require hand-writing every mutation block. `scripts/mutation_catalog.py` validates those definitions and generates `docs/mutation-catalog.md` for review.
