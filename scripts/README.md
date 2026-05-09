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
11. `generate-artifact-catalog` (`generate-artifact-catalog.ps1` / `generate-artifact-catalog.sh`)
12. `generate-requirements-traceability` (`generate-requirements-traceability.ps1` / `generate-requirements-traceability.sh`)
13. `generate-coverage-goals` (`generate-coverage-goals.ps1` / `generate-coverage-goals.sh`)
14. `generate-register-map` (`generate-register-map.ps1` / `generate-register-map.sh`)
15. `generate-protocol-catalog` (`generate-protocol-catalog.ps1` / `generate-protocol-catalog.sh`)
16. `generate-documentation-index` (`generate-documentation-index.ps1` / `generate-documentation-index.sh`)
17. `run-uvm` (`run-uvm.ps1` / `run-uvm.sh`)
18. `run-asm-corpus` (`run-asm-corpus.ps1` / `run-asm-corpus.sh`)
19. `run-mmio` (`run-mmio.ps1` / `run-mmio.sh`)
20. `run-mmio-wait` (`run-mmio-wait.ps1` / `run-mmio-wait.sh`)
21. `run-apb` (`run-apb.ps1` / `run-apb.sh`)
22. `run-wishbone` (`run-wishbone.ps1` / `run-wishbone.sh`)
23. `run-axi-lite` (`run-axi-lite.ps1` / `run-axi-lite.sh`)
24. `run-axi-lite-fault` (`run-axi-lite-fault.ps1` / `run-axi-lite-fault.sh`)
25. `run-apb-fault` (`run-apb-fault.ps1` / `run-apb-fault.sh`)
26. `run-wishbone-fault` (`run-wishbone-fault.ps1` / `run-wishbone-fault.sh`)
27. `run-mutations` (`run-mutations.ps1` / `run-mutations.sh`)
28. `check-python-model` (`check-python-model.ps1` / `check-python-model.sh`)
29. `check-native` (`check-native.ps1` / `check-native.sh`)
30. `check-all` (`check-all.ps1` / `check-all.sh`)
31. `check-coverage-delta` (`check-coverage-delta.ps1` / `check-coverage-delta.sh`)
32. `update-coverage-baseline` (`update-coverage-baseline.ps1` / `update-coverage-baseline.sh`)
33. `run-formal` (`run-formal.ps1` / `run-formal.sh`)
34. `run-cocotb-verilator` (`run-cocotb-verilator.ps1` / `run-cocotb-verilator.sh`)
35. `run-cocotb-mmio` (`run-cocotb-mmio.ps1` / `run-cocotb-mmio.sh`)
36. `run-mmio-uvm` (`run-mmio-uvm.ps1` / `run-mmio-uvm.sh`)
37. `run-cocotb-mmio-wait` (`run-cocotb-mmio-wait.ps1` / `run-cocotb-mmio-wait.sh`)
38. `run-mmio-wait-uvm` (`run-mmio-wait-uvm.ps1` / `run-mmio-wait-uvm.sh`)
39. `run-cocotb-apb` (`run-cocotb-apb.ps1` / `run-cocotb-apb.sh`)
40. `run-apb-uvm` (`run-apb-uvm.ps1` / `run-apb-uvm.sh`)
41. `run-cocotb-wishbone` (`run-cocotb-wishbone.ps1` / `run-cocotb-wishbone.sh`)
42. `run-wishbone-uvm` (`run-wishbone-uvm.ps1` / `run-wishbone-uvm.sh`)
43. `run-cocotb-axi-lite` (`run-cocotb-axi-lite.ps1` / `run-cocotb-axi-lite.sh`)
44. `run-axi-lite-uvm` (`run-axi-lite-uvm.ps1` / `run-axi-lite-uvm.sh`)
45. `run-equiv` (`run-equiv.ps1` / `run-equiv.sh`)
46. `update-equivalence-golden` (`update-equivalence-golden.ps1` / `update-equivalence-golden.sh`)
47. `format-sv` (`format-sv.ps1` / `format-sv.sh`)
48. `lint` (`lint.ps1` / `lint.sh`)
49. `show-static-analysis` (`show-static-analysis.ps1` / `show-static-analysis.sh`)
50. `open-waves` (`open-waves.ps1` / `open-waves.sh`)
51. `show-model-trace` (`show-model-trace.ps1` / `show-model-trace.sh`)
52. `show-coverage` (`show-coverage.ps1` / `show-coverage.sh`)
53. `show-pyuvm-coverage` (`show-pyuvm-coverage.ps1` / `show-pyuvm-coverage.sh`)
54. `show-mmio-coverage` (`show-mmio-coverage.ps1` / `show-mmio-coverage.sh`)
55. `show-mmio-wait-coverage` (`show-mmio-wait-coverage.ps1` / `show-mmio-wait-coverage.sh`)
56. `show-apb-coverage` (`show-apb-coverage.ps1` / `show-apb-coverage.sh`)
57. `show-wishbone-coverage` (`show-wishbone-coverage.ps1` / `show-wishbone-coverage.sh`)
58. `show-axi-lite-coverage` (`show-axi-lite-coverage.ps1` / `show-axi-lite-coverage.sh`)
59. `show-axi-lite-fault-coverage` (`show-axi-lite-fault-coverage.ps1` / `show-axi-lite-fault-coverage.sh`)
60. `show-apb-fault-coverage` (`show-apb-fault-coverage.ps1` / `show-apb-fault-coverage.sh`)
61. `show-wishbone-fault-coverage` (`show-wishbone-fault-coverage.ps1` / `show-wishbone-fault-coverage.sh`)
62. `show-verilator-coverage` (`show-verilator-coverage.ps1` / `show-verilator-coverage.sh`)
63. `record-coverage-history` (`record-coverage-history.ps1` / `record-coverage-history.sh`)
64. `show-coverage-trend` (`show-coverage-trend.ps1` / `show-coverage-trend.sh`)
65. `show-mutations` (`show-mutations.ps1` / `show-mutations.sh`)
66. `show-formal-status` (`show-formal-status.ps1` / `show-formal-status.sh`)
67. `export-status` (`export-status.ps1` / `export-status.sh`)

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

1. `scripts/check-python-model.*` runs `tb/test_cpu_lib_unit.py`, `tb/test_asm_unit.py`, `tb/test_mutation_unit.py`, `tb/test_formal_catalog_unit.py`, `tb/test_script_catalog_unit.py`, `tb/test_ci_catalog_unit.py`, `tb/test_tooling_catalog_unit.py`, `tb/test_verification_matrix_unit.py`, `tb/test_artifact_catalog_unit.py`, `tb/test_requirements_traceability_unit.py`, `tb/test_documentation_index_unit.py`, `tb/test_coverage_goals_unit.py`, `tb/test_register_map_unit.py`, and `tb/test_protocol_catalog_unit.py`, checks generated ISA, assembler-corpus, mutation-catalog, formal-target, script-catalog, CI-catalog, tooling-catalog, verification-matrix, artifact-catalog, requirements-traceability, documentation-index, coverage-goals, register-map, and protocol-conformance docs, and emits example traces under `sim_build/model_trace`; `scripts/show-model-trace.*` is the interactive wrapper around the same disassembly/trace utility.

Mutation note:

1. `scripts/run_mutation_campaign.py` now builds APB, Wishbone, AXI-Lite, and MMIO-wait protocol-shell mutants through helper templates (`make_assign_mutation`, `make_port_mutation`, `make_localparam_mutation`) so extending a new wrapper family does not require hand-writing every mutation block. `scripts/mutation_catalog.py` validates those definitions and generates `docs/mutation-catalog.md` for review.
