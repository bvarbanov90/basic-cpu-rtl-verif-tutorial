# Verification Plan (Basic CPU Tutorial)

## Verification goals

1. Confirm each opcode behaves per spec.
2. Confirm status flags (`ZERO`, `CARRY`, `NEG`, `OVERFLOW`, `HALTED`) update correctly.
3. Confirm control-flow behavior (`JMP`, `JZ`) works.
4. Confirm memory side effects (`STA`, `LDA`) are correct.
5. Confirm end-to-end state matches a reference model.
6. Confirm external assembled programs match the reference model.

## Current status (May 1, 2026)

1. `.\scripts\run.ps1 -NoWaves`: PASS
2. `.\scripts\lint.ps1`: PASS
3. `.\scripts\show-static-analysis.ps1`: PASS
4. `.\scripts\run-formal.ps1`: PASS (auto-selected `cvc5`)
5. `.\scripts\run-formal.ps1 -Mode cover`: PASS
6. `.\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage`: PASS (falls back to WSL, auto-uses Linux OSS CAD Suite Verilator 5.047)
7. `.\scripts\show-verilator-coverage.ps1`: PASS
8. `.\scripts\run-equiv.ps1`: PASS (routes through WSL EQY)
9. `.\scripts\show-coverage.ps1`: PASS (`opcode_hit_bitmap=111111111111111`)
10. `.\scripts\show-mmio-coverage.ps1`: PASS
11. `.\scripts\show-mmio-wait-coverage.ps1`: PASS
12. `.\scripts\show-apb-coverage.ps1`: PASS
13. `.\scripts\show-apb-fault-coverage.ps1`: PASS
14. `.\scripts\record-coverage-history.ps1`: PASS
15. `.\scripts\show-coverage-trend.ps1`: PASS
16. `.\scripts\run-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
17. `.\scripts\run-mmio-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
18. `.\scripts\run-cocotb-mmio.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
19. `.\scripts\run-cocotb-mmio-wait.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
20. `.\scripts\run-mmio-wait-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
21. `.\scripts\run-cocotb-apb.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
22. `.\scripts\run-apb-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
23. `.\scripts\run-cocotb-wishbone.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
24. `.\scripts\run-wishbone-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
25. `.\scripts\run-cocotb-axi-lite.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
26. `.\scripts\run-axi-lite-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
27. `.\scripts\check-coverage-delta.ps1`: PASS
28. `.\scripts\run-mmio.ps1 -NoWaves`: PASS
29. `.\scripts\run-mmio-wait.ps1 -NoWaves`: PASS
30. `.\scripts\run-apb.ps1 -NoWaves`: PASS
31. `.\scripts\run-wishbone.ps1 -NoWaves`: PASS
32. `.\scripts\run-axi-lite.ps1 -NoWaves`: PASS
33. `.\scripts\show-axi-lite-coverage.ps1`: PASS
34. `.\scripts\run-axi-lite-fault.ps1 -NoWaves`: PASS
35. `.\scripts\show-axi-lite-fault-coverage.ps1`: PASS
36. `.\scripts\run-asm-corpus.ps1 -Runner axi_lite`: PASS
37. Target-only `formal/simple_cpu_axi_lite.sby`, `formal/simple_cpu_axi_lite_faults.sby`, and `formal/simple_cpu_axi_lite_cover.sby`: PASS
38. `.\scripts\run-apb-fault.ps1 -NoWaves`: PASS
39. `.\scripts\run-wishbone-fault.ps1 -NoWaves`: PASS
40. `.\scripts\show-wishbone-fault-coverage.ps1`: PASS
41. `.\scripts\check-native.ps1`: PASS
42. `.\scripts\run-asm-corpus.ps1 -NoSimulate`: PASS
43. `.\scripts\run-asm-corpus.ps1 -Runner mmio_wait`: PASS
44. `.\scripts\run-asm-corpus.ps1 -Runner apb`: PASS
45. `.\scripts\run-asm-corpus.ps1 -Runner wishbone`: PASS
46. `.\scripts\run-mutations.ps1`: PASS
47. `.\scripts\show-mutations.ps1`: PASS
48. `bash scripts/run.sh --no-waves` (WSL Ubuntu): PASS
49. `bash scripts/run-mmio.sh --no-waves` (WSL Ubuntu): PASS
50. `bash scripts/run-mmio-wait.sh --no-waves` (WSL Ubuntu): PASS
51. `bash scripts/run-apb.sh --no-waves` (WSL Ubuntu): PASS
52. `bash scripts/run-wishbone.sh --no-waves` (WSL Ubuntu): PASS
53. `bash scripts/show-mmio-coverage.sh` (WSL Ubuntu): PASS
54. `bash scripts/show-mmio-wait-coverage.sh` (WSL Ubuntu): PASS
55. `bash scripts/show-apb-coverage.sh` (WSL Ubuntu): PASS
56. `bash scripts/show-wishbone-coverage.sh` (WSL Ubuntu): PASS
57. `bash scripts/show-apb-fault-coverage.sh` (WSL Ubuntu): PASS
58. `bash scripts/check-native.sh`: PASS
59. `bash scripts/lint.sh` (WSL Ubuntu): PASS
60. `bash scripts/show-static-analysis.sh` (WSL Ubuntu): PASS
61. `bash scripts/run-formal.sh --mode all` (WSL Ubuntu, `cvc5`): PASS
62. `bash scripts/run-cocotb-verilator.sh --no-waves --coverage` (WSL Ubuntu): PASS
63. `bash scripts/run-cocotb-mmio.sh --no-waves` (WSL Ubuntu): PASS
64. `bash scripts/run-cocotb-mmio-wait.sh --no-waves` (WSL Ubuntu): PASS
65. `bash scripts/run-cocotb-wishbone.sh --no-waves` (WSL Ubuntu): PASS
66. `bash scripts/run-equiv.sh` (WSL Ubuntu): PASS
67. `bash scripts/run-uvm.sh --no-waves` (WSL Ubuntu): PASS
68. `bash scripts/run-mmio-uvm.sh --no-waves` (WSL Ubuntu): PASS
69. `bash scripts/run-mmio-wait-uvm.sh --no-waves` (WSL Ubuntu): PASS
70. `bash scripts/run-wishbone-uvm.sh --no-waves` (WSL Ubuntu): PASS
71. `bash scripts/run-cocotb-axi-lite.sh --no-waves` (WSL Ubuntu): PASS
72. `bash scripts/run-axi-lite-uvm.sh --no-waves` (WSL Ubuntu): PASS
73. `bash scripts/run-axi-lite-fault.sh --no-waves` (WSL Ubuntu): PASS
74. `bash scripts/show-axi-lite-fault-coverage.sh` (WSL Ubuntu): PASS
75. `bash scripts/check-coverage-delta.sh` (WSL Ubuntu): PASS
76. `bash scripts/show-coverage-trend.sh` (WSL Ubuntu): PASS
77. `bash scripts/run-asm-corpus.sh --no-simulate` (WSL Ubuntu): PASS
78. `bash scripts/run-asm-corpus.sh --runner mmio` (WSL Ubuntu): PASS
79. `bash scripts/run-asm-corpus.sh --runner mmio_wait` (WSL Ubuntu): PASS
80. `bash scripts/run-asm-corpus.sh --runner apb` (WSL Ubuntu): PASS
81. `bash scripts/run-asm-corpus.sh --runner wishbone` (WSL Ubuntu): PASS
82. `bash scripts/run-mutations.sh` (WSL Ubuntu): PASS
83. `.\scripts\check-python-model.ps1`: PASS
84. `.\scripts\show-model-trace.ps1 --bytes 0x13 0x40 0x80`: PASS
85. `bash scripts/check-python-model.sh` (WSL Ubuntu): PASS
86. `bash scripts/show-model-trace.sh --asm programs/counter_loop.asm --format json --output sim_build/model_trace/counter_loop.json` (WSL Ubuntu): PASS
87. `.\scripts\generate-isa-docs.ps1 --check`: PASS
88. `bash scripts/generate-isa-docs.sh --check` (WSL Ubuntu): PASS
89. `.\scripts\generate-asm-corpus-docs.ps1 --check`: PASS
90. `bash scripts/generate-asm-corpus-docs.sh --check` (WSL Ubuntu): PASS
91. `.\scripts\generate-formal-catalog.ps1 --check`: PASS
92. `bash scripts/generate-formal-catalog.sh --check` (WSL Ubuntu): PASS
93. `.\scripts\generate-script-catalog.ps1 --check`: PASS
94. `bash scripts/generate-script-catalog.sh --check` (WSL Ubuntu): PASS
95. `.\scripts\generate-mutation-catalog.ps1 --check`: PASS
96. `bash scripts/generate-mutation-catalog.sh --check` (WSL Ubuntu): PASS
97. `bash scripts/show-mutations.sh` (WSL Ubuntu): PASS
98. `.\scripts\show-formal-status.ps1`: PASS
99. `.\scripts\export-status.ps1 -Label tutorial-regression`: PASS
100. `bash scripts/show-formal-status.sh` (WSL Ubuntu): PASS
101. `bash scripts/export-status.sh --label tutorial-regression`: PASS
102. Target-only `formal/simple_cpu_wishbone_faults.sby` run with a `cvc5` solver override: PASS (1 second on Windows)
103. Target-only `formal/simple_cpu_axi_lite_faults.sby` run with a `cvc5` solver override: PASS (1 second on Windows)

## Test strategy

1. Directed tests for fast, readable intent checks.
2. Multi-seed randomized dataflow and branch-stress programs for broader state exploration.
3. Reference-model comparison for robust end-state checking.
4. Lightweight functional coverage counters with threshold checks.
5. Repo-tracked coverage baseline with delta checks for non-regression.
6. Assembler corpus manifest checks for stable machine-code and end-state regression.
7. Interface-level wrapper verification using the same programs/reference model.
8. Mutation testing that confirms representative RTL bugs are detected by the regressions.
9. Wrapper-specific protocol/transaction coverage for the MMIO shell.
10. Simulator cross-checking with the same cocotb tests on Verilator.
11. Formal cover witness generation for tutorial-quality traces.
12. EQY equivalence checks for refactor-safe RTL cleanup.
13. Multi-tool static analysis with Verilator, Verible lint/format, and svlint.
14. CI workflow on GitHub Actions for automated regression on push/PR.

## Current tests

| Test name | Location | Intent |
|---|---|---|
| `test_directed` | `tb/simple_cpu_tb.sv` | Exercises arithmetic, stores, `ZERO`, `JZ`, and `HLT`. |
| `test_branch_not_taken` | `tb/simple_cpu_tb.sv` | Explicit `JZ` not-taken behavior and `NOP` execution. |
| `test_jump_loop` | `tb/simple_cpu_tb.sv` | `JMP` + `JZ` loop behavior and loop exit via `ZERO`. |
| `test_wraparound_zero` | `tb/simple_cpu_tb.sv` | 8-bit arithmetic wraparound and `ZERO` flag transition checks. |
| `test_logic_and_cmp` | `tb/simple_cpu_tb.sv` | `AND/OR/XOR/SHL/SHR/CMP` behavior and flag checks. |
| `test_shift_carry_and_overflow` | `tb/simple_cpu_tb.sv` | Shift carry-out and overflow behavior checks. |
| `test_cmp_negative` | `tb/simple_cpu_tb.sv` | Negative compare result flag checks (`NEG`, `CARRY`). |
| `test_illegal_opcode` | `tb/simple_cpu_tb.sv` | Illegal opcode handling path should halt safely. |
| `test_randomized_suite` | `tb/simple_cpu_tb.sv` | 20 deterministic randomized programs, full DUT vs model state compare. |
| `test_branch_randomized_suite` | `tb/simple_cpu_tb.sv` | Bounded-loop branch-heavy randomized programs stressing `JZ/JMP` control flow. |
| `test_external_program` | `tb/simple_cpu_tb.sv` | Optional plusarg-driven external `.hex` program check vs model. |
| `report_and_check_coverage` | `tb/simple_cpu_tb.sv` | Coverage thresholds for opcode hits, branch outcomes, and flag transitions. |
| `test_mmio_smoke` | `tb/simple_cpu_mmio_tb.sv` | MMIO programming, shadow readback, loader start, and end-state comparison. |
| `test_mmio_reprogram_sequence` | `tb/simple_cpu_mmio_tb.sv` | Reset/reprogram/run sequencing plus shift carry/overflow status checking. |
| `test_mmio_illegal_opcode` | `tb/simple_cpu_mmio_tb.sv` | MMIO replay of illegal-opcode handling and safe halt behavior. |
| `test_mmio_jump_sub_cmp_sequence` | `tb/simple_cpu_mmio_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the MMIO mutation gap for ALU/control flow. |
| `test_mmio_shadow_fault_injection` | `tb/simple_cpu_mmio_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_mmio_tb.sv` | Optional `.hex` replay through the MMIO wrapper against the reference model. |
| `report_and_check_mmio_coverage` | `tb/simple_cpu_mmio_tb.sv` | Wrapper protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_mmio_assertions` | `tb/simple_cpu_mmio_assertions.sv` | Assertion-based checker for `bus_ready`, control-state encoding, and loader/reset signal alignment. |
| `test_mmio_smoke` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state MMIO programming, shadow readback, delayed bus handshake, and end-state comparison. |
| `test_mmio_reprogram_sequence` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state reset/reprogram/run sequencing plus delayed control/status visibility checks. |
| `test_mmio_illegal_opcode` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state replay of illegal-opcode handling and safe halt behavior. |
| `test_mmio_jump_sub_cmp_sequence` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state wrapper replay of `SUB/CMP/JMP` control flow against the reference model. |
| `test_mmio_shadow_fault_injection` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state proof that shadow writes during `RUN` only affect the next explicit reload. |
| `test_external_program` | `tb/simple_cpu_mmio_wait_tb.sv` | Optional `.hex` replay through the wait-state MMIO wrapper against the reference model. |
| `report_and_check_mmio_wait_coverage` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state wrapper transaction coverage thresholds and artifact emission. |
| `simple_cpu_mmio_wait_assertions` | `tb/simple_cpu_mmio_wait_assertions.sv` | Assertion-based checker for request capture, delayed `bus_ready`, stable pending request fields, and inner-wrapper alignment. |
| `test_apb_smoke` | `tb/simple_cpu_apb_tb.sv` | APB programming, shadow readback, loader start, and end-state comparison. |
| `test_apb_reprogram_sequence` | `tb/simple_cpu_apb_tb.sv` | Reset/reprogram/run sequencing plus APB control/status readback checks. |
| `test_apb_illegal_opcode` | `tb/simple_cpu_apb_tb.sv` | APB replay of illegal-opcode handling and safe halt behavior. |
| `test_apb_jump_sub_cmp_sequence` | `tb/simple_cpu_apb_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the APB native control-flow gap. |
| `test_apb_shadow_fault_injection` | `tb/simple_cpu_apb_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_apb_tb.sv` | Optional `.hex` replay through the APB wrapper against the reference model. |
| `report_and_check_apb_coverage` | `tb/simple_cpu_apb_tb.sv` | APB protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_apb_assertions` | `tb/simple_cpu_apb_assertions.sv` | Assertion-based checker for APB setup/access sequencing, `PREADY` gating, and control/readback alignment. |
| `test_wishbone_smoke` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone programming, shadow readback, loader start, and end-state comparison. |
| `test_wishbone_reprogram_sequence` | `tb/simple_cpu_wishbone_tb.sv` | Reset/reprogram/run sequencing plus Wishbone control/status readback checks. |
| `test_wishbone_illegal_opcode` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone replay of illegal-opcode handling and safe halt behavior. |
| `test_wishbone_jump_sub_cmp_sequence` | `tb/simple_cpu_wishbone_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the Wishbone native control-flow gap. |
| `test_wishbone_shadow_fault_injection` | `tb/simple_cpu_wishbone_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_wishbone_tb.sv` | Optional `.hex` replay through the Wishbone wrapper against the reference model. |
| `report_and_check_wishbone_coverage` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_wishbone_assertions` | `tb/simple_cpu_wishbone_assertions.sv` | Assertion-based checker for Wishbone `CYC/STB/ACK` gating and control/readback alignment. |
| `test_axi_lite_partial_write_channels_ignored` | `tb/simple_cpu_axi_lite_tb.sv` | Proves `AW`-only and `W`-only attempts do not create responses or shadow writes in the coupled-channel AXI-Lite subset. |
| `test_axi_lite_smoke` | `tb/simple_cpu_axi_lite_tb.sv` | AXI-Lite programming, shadow readback, loader start, and end-state comparison. |
| `test_axi_lite_reprogram_sequence` | `tb/simple_cpu_axi_lite_tb.sv` | Reset/reprogram/run sequencing plus AXI-Lite control/status readback checks. |
| `test_axi_lite_illegal_opcode` | `tb/simple_cpu_axi_lite_tb.sv` | AXI-Lite replay of illegal-opcode handling and safe halt behavior. |
| `test_axi_lite_jump_sub_cmp_sequence` | `tb/simple_cpu_axi_lite_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay through the AXI-Lite shell. |
| `test_axi_lite_shadow_fault_injection` | `tb/simple_cpu_axi_lite_tb.sv` | Proves AXI-Lite shadow writes during `RUN` only affect execution after an explicit reload. |
| `test_external_program` | `tb/simple_cpu_axi_lite_tb.sv` | Optional `.hex` replay through the AXI-Lite-style wrapper against the reference model. |
| `report_and_check_axi_lite_coverage` | `tb/simple_cpu_axi_lite_tb.sv` | AXI-Lite protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_axi_lite_assertions` | `tb/simple_cpu_axi_lite_assertions.sv` | Assertion-based checker for coupled `AW/W`, response hold/clear, read-response, and common wrapper invariants. |
| `test_aw_only_shadow_write_ignored` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves `AWVALID` without `WVALID` does not update the AXI-Lite wrapper shadow image or produce a write response. |
| `test_w_only_shadow_write_ignored` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves `WVALID` without `AWVALID` does not update the AXI-Lite wrapper shadow image or produce a write response. |
| `test_split_write_attempt_ignored` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves separated `AW` then `W` attempts are not paired across cycles in the coupled-channel tutorial shell. |
| `test_partial_control_start_ignored` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves partial control writes do not start the loader or release the core. |
| `test_pending_response_blocks_new_write` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves a pending `BVALID` response blocks new write acceptance until `BREADY`. |
| `test_run_phase_shadow_update_requires_reload` | `tb/simple_cpu_axi_lite_fault_tb.sv` | Proves AXI-Lite shadow updates during `RUN` only affect execution after an explicit reload. |
| `report_and_check_axi_lite_fault_coverage` | `tb/simple_cpu_axi_lite_fault_tb.sv` | AXI-Lite fault-injection coverage thresholds and artifact emission. |
| `test_setup_only_shadow_write_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup-only shadow writes do not update the APB wrapper shadow image. |
| `test_aborted_shadow_write_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup then abort traffic does not update the APB wrapper shadow image. |
| `test_setup_only_control_start_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup-only `CONTROL=1` writes do not start the loader. |
| `test_penable_without_select_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves `PENABLE` glitches without `PSEL` do not create hidden APB side effects. |
| `test_run_phase_shadow_update_requires_reload` | `tb/simple_cpu_apb_fault_tb.sv` | Proves APB shadow updates during `RUN` are visible in shadow readback immediately but only affect execution after the next explicit reload. |
| `report_and_check_apb_fault_coverage` | `tb/simple_cpu_apb_fault_tb.sv` | APB fault-injection coverage thresholds and artifact emission. |
| `test_cycle_only_shadow_write_ignored` | `tb/simple_cpu_wishbone_fault_tb.sv` | Proves `CYC` without `STB` does not update the Wishbone wrapper shadow image. |
| `test_aborted_shadow_write_ignored` | `tb/simple_cpu_wishbone_fault_tb.sv` | Proves an aborted Wishbone cycle does not update the wrapper shadow image. |
| `test_cycle_only_control_start_ignored` | `tb/simple_cpu_wishbone_fault_tb.sv` | Proves `CONTROL=1` writes with `CYC` only do not start the loader. |
| `test_strobe_without_cycle_ignored` | `tb/simple_cpu_wishbone_fault_tb.sv` | Proves `STB` glitches without `CYC` do not create hidden Wishbone side effects. |
| `test_run_phase_shadow_update_requires_reload` | `tb/simple_cpu_wishbone_fault_tb.sv` | Proves Wishbone shadow updates during `RUN` are visible in shadow readback immediately but only affect execution after the next explicit reload. |
| `report_and_check_wishbone_fault_coverage` | `tb/simple_cpu_wishbone_fault_tb.sv` | Wishbone fault-injection coverage thresholds and artifact emission. |
| `directed_arithmetic_and_branch` | `tb/test_simple_cpu.py` | Optional cocotb directed test mirroring simulator-native checks. |
| `randomized_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb randomized/reference-model check. |
| `branch_stress_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb bounded-loop branch-stress/reference-model check. |
| `assembler_corpus_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb replay of the tracked assembler corpus against the DUT and reference model. |
| `protocol_conformance_matches_reference_suite` | `tb/test_simple_cpu.py` | Shared conformance-suite replay over the direct programming interface using the same scenario set as the wrapper buses. |
| `program_write_stalls_and_retargets_execution` | `tb/test_simple_cpu.py` | Holds `prog_we` across consecutive cycles, proves architectural state stalls, and confirms a future instruction patch is honored once execution resumes. |
| `test_cpu_lib_unit` | `tb/test_cpu_lib_unit.py` | Pytest self-checks for the Python reference model, disassembler, trace rows, deterministic program builders, and representative flag behavior. |
| `check-python-model` | `scripts/check-python-model.*` | Fast reference-model lane that runs pytest and emits example model traces without requiring an RTL simulator. |
| `show-model-trace` | `scripts/model_trace.py` + wrappers | Disassembles and traces built-in, assembly, or raw-byte programs through the Python reference model for scoreboard/debug walkthroughs. |
| `generate-isa-docs` | `scripts/isa_report.py` + wrappers | Generates and checks `docs/isa.md` from assembler/reference-model metadata, catching ISA-table drift in the Python-model lane. |
| `mmio_program_matches_reference_model` | `tb/test_simple_cpu_mmio.py` | Optional cocotb MMIO wrapper replay against the same `ReferenceCPU` used by the native bench. |
| `mmio_protocol_conformance_suite` | `tb/test_simple_cpu_mmio.py` | Replays the shared conformance-suite scenarios through the MMIO wrapper and checks end state against `ReferenceCPU`. |
| `mmio_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_mmio.py` | Python-side bus-level check that shadow writes during `RUN` do not perturb the current run and only take effect after reload. |
| `mmio_control_status_readback` | `tb/test_simple_cpu_mmio.py` | Reads `CONTROL`, `STATUS`, `ACC`, and DMEM through MMIO across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `run-cocotb-verilator` | `scripts/run-cocotb-verilator.*` | Runs the cocotb core regression on Verilator and emits structural coverage artifacts. |
| `run-cocotb-mmio` | `scripts/run-cocotb-mmio.*` | Runs the dedicated MMIO cocotb regression on Icarus with bus-level programming/readback checks. |
| `run-cocotb-mmio-wait` | `scripts/run-cocotb-mmio-wait.*` | Replays the same MMIO cocotb suite against the wait-state wrapper variant and proves the Python bus helper tolerates delayed `bus_ready`. |
| `apb_program_matches_reference_model` | `tb/test_simple_cpu_apb.py` | Optional cocotb APB-wrapper replay against the same `ReferenceCPU` used by the MMIO and native benches. |
| `apb_protocol_conformance_suite` | `tb/test_simple_cpu_apb.py` | Replays the shared conformance-suite scenarios through the APB wrapper and checks end state against `ReferenceCPU`. |
| `apb_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_apb.py` | APB-side shadow-image change check proving the current run is isolated until reload. |
| `apb_control_status_readback` | `tb/test_simple_cpu_apb.py` | Reads APB-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the APB shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `apb_setup_phase_requires_penable` | `tb/test_simple_cpu_apb.py` | Protocol-focused APB check that `PREADY` stays low during setup until `PENABLE` is asserted. |
| `wishbone_program_matches_reference_model` | `tb/test_simple_cpu_wishbone.py` | Optional cocotb Wishbone-wrapper replay against the same `ReferenceCPU` used by the MMIO/APB/native benches. |
| `wishbone_protocol_conformance_suite` | `tb/test_simple_cpu_wishbone.py` | Replays the shared conformance-suite scenarios through the Wishbone wrapper and checks end state against `ReferenceCPU`. |
| `wishbone_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_wishbone.py` | Wishbone-side shadow-image change check proving the current run is isolated until reload. |
| `wishbone_control_status_readback` | `tb/test_simple_cpu_wishbone.py` | Reads Wishbone-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the Wishbone shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `wishbone_cycle_without_strobe_keeps_ack_low` | `tb/test_simple_cpu_wishbone.py` | Protocol-focused Wishbone check that `ACK` stays low when `CYC` is asserted without `STB`. |
| `axi_lite_program_matches_reference_model` | `tb/test_simple_cpu_axi_lite.py` | Optional cocotb AXI-Lite-wrapper replay against the same `ReferenceCPU` used by the MMIO/APB/Wishbone/native benches. |
| `axi_lite_protocol_conformance_suite` | `tb/test_simple_cpu_axi_lite.py` | Replays the shared conformance-suite scenarios through the AXI-Lite wrapper and checks end state against `ReferenceCPU`. |
| `axi_lite_partial_write_channels_are_ignored` | `tb/test_simple_cpu_axi_lite.py` | Protocol-focused check that `AW`-only and `W`-only attempts do not update the shadow image or create a write response. |
| `axi_lite_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_axi_lite.py` | AXI-Lite-side shadow-image change check proving the current run is isolated until reload. |
| `axi_lite_control_status_readback` | `tb/test_simple_cpu_axi_lite.py` | Reads AXI-Lite-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `axi_lite_response_holds_until_ready` | `tb/test_simple_cpu_axi_lite.py` | Protocol-focused check that `BVALID` remains asserted until `BREADY`. |
| `SimpleCpuMmioUvmSmokeTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | Minimal pyuvm wrapper smoke/reference-model check over the MMIO shell. |
| `SimpleCpuMmioUvmRandomizedTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | Minimal pyuvm randomized wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuMmioUvmControlStatusTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | pyuvm wrapper sequence that explicitly observes `LOAD` then `RUN` through the MMIO control register. |
| `SimpleCpuMmioUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | pyuvm direct-bus proof that shadow writes during `RUN` only affect the next reload. |
| `run-mmio-uvm` | `scripts/run-mmio-uvm.*` | Runs the dedicated MMIO pyuvm regression on Icarus using the reusable Python MMIO bus helper. |
| `run-mmio-wait-uvm` | `scripts/run-mmio-wait-uvm.*` | Runs the same MMIO pyuvm suite against the wait-state wrapper variant with delayed handshakes. |
| `SimpleCpuApbUvmSmokeTest` | `tb/test_simple_cpu_apb_pyuvm.py` | Minimal pyuvm APB-wrapper smoke/reference-model check over the APB shell. |
| `SimpleCpuApbUvmRandomizedTest` | `tb/test_simple_cpu_apb_pyuvm.py` | Minimal pyuvm randomized APB-wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuApbUvmControlStatusTest` | `tb/test_simple_cpu_apb_pyuvm.py` | pyuvm APB-wrapper sequence that explicitly observes `LOAD` then `RUN` through the APB control register. |
| `SimpleCpuApbUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_apb_pyuvm.py` | pyuvm APB proof that shadow writes during `RUN` only affect the next reload. |
| `run-cocotb-apb` | `scripts/run-cocotb-apb.*` | Runs the dedicated APB cocotb regression on Icarus with setup/access handshake checks. |
| `run-apb-uvm` | `scripts/run-apb-uvm.*` | Runs the dedicated APB pyuvm regression on Icarus using the reusable Python APB bus helper. |
| `SimpleCpuWishboneUvmSmokeTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | Minimal pyuvm Wishbone-wrapper smoke/reference-model check over the Wishbone shell. |
| `SimpleCpuWishboneUvmRandomizedTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | Minimal pyuvm randomized Wishbone-wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuWishboneUvmControlStatusTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | pyuvm Wishbone-wrapper sequence that explicitly observes `LOAD` then `RUN` through the Wishbone control register. |
| `SimpleCpuWishboneUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | pyuvm Wishbone proof that shadow writes during `RUN` only affect the next reload. |
| `run-cocotb-wishbone` | `scripts/run-cocotb-wishbone.*` | Runs the dedicated Wishbone cocotb regression on Icarus with `CYC/STB/ACK` handshake checks. |
| `run-wishbone-uvm` | `scripts/run-wishbone-uvm.*` | Runs the dedicated Wishbone pyuvm regression on Icarus using the reusable Python Wishbone bus helper. |
| `SimpleCpuAxiLiteUvmSmokeTest` | `tb/test_simple_cpu_axi_lite_pyuvm.py` | Minimal pyuvm AXI-Lite-wrapper smoke/reference-model check over the coupled-channel shell. |
| `SimpleCpuAxiLiteUvmRandomizedTest` | `tb/test_simple_cpu_axi_lite_pyuvm.py` | Minimal pyuvm randomized AXI-Lite-wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuAxiLiteUvmControlStatusTest` | `tb/test_simple_cpu_axi_lite_pyuvm.py` | pyuvm AXI-Lite-wrapper sequence that explicitly observes `LOAD` then `RUN` through the control register. |
| `SimpleCpuAxiLiteUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_axi_lite_pyuvm.py` | pyuvm AXI-Lite proof that shadow writes during `RUN` only affect the next reload. |
| `SimpleCpuAxiLiteUvmPartialWriteTest` | `tb/test_simple_cpu_axi_lite_pyuvm.py` | pyuvm protocol check that partial `AW`/`W` write-channel attempts are ignored. |
| `run-cocotb-axi-lite` | `scripts/run-cocotb-axi-lite.*` | Runs the dedicated AXI-Lite cocotb regression on Icarus with coupled `AW/W` and response-hold checks. |
| `run-axi-lite-uvm` | `scripts/run-axi-lite-uvm.*` | Runs the dedicated AXI-Lite pyuvm regression on Icarus using the reusable Python AXI-Lite bus helper. |
| `SimpleCpuUvmSmokeTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm (UVM-style) sequence/driver/subscriber smoke check. |
| `SimpleCpuUvmRandomizedTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm randomized program check against reference model. |
| `SimpleCpuUvmBranchStressTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm branch-stress program check against reference model. |
| `SimpleCpuUvmCoverageRegressionTest` | `tb/test_simple_cpu_pyuvm.py` | Deterministic + randomized pyuvm regression with subscriber-based coverage report emission. |
| `SimpleCpuUvmProgramWriteStallTest` | `tb/test_simple_cpu_pyuvm.py` | pyuvm BFM-level proof that asserted `prog_we` stalls architectural state while a future instruction patch is staged. |
| `run-asm-corpus` | `scripts/check_asm_corpus.py` + wrappers | Manifest-driven assembler regression corpus; checks bytes, final state, and coverage signatures. |
| `test_asm_unit` | `tb/test_asm_unit.py` | Pytest checks for assembler labels, `.org`, raw bytes, rejection paths, manifest completeness, and generated corpus docs. |
| `generate-asm-corpus-docs` | `scripts/asm_corpus_report.py` + wrappers | Generates and checks `docs/assembler-regressions.md` from the corpus manifest and reference model. |
| `test_formal_catalog_unit` | `tb/test_formal_catalog_unit.py` | Pytest checks for formal target metadata, `.sby` file references, wrapper target coverage, and generated formal catalog freshness. |
| `generate-formal-catalog` | `scripts/formal_catalog.py` + wrappers | Generates and checks `docs/formal-targets.md` from root-level SymbiYosys target files. |
| `test_script_catalog_unit` | `tb/test_script_catalog_unit.py` | Pytest checks for cross-platform script wrapper symmetry, platform implementation coverage, and generated script catalog freshness. |
| `generate-script-catalog` | `scripts/script_catalog.py` + wrappers | Generates and checks `docs/script-catalog.md` from the cross-platform automation layout. |
| `test_ci_catalog_unit` | `tb/test_ci_catalog_unit.py` | Pytest checks for GitHub Actions job shape, summary fan-in, script references, artifact upload metadata, and generated CI catalog freshness. |
| `generate-ci-catalog` | `scripts/ci_catalog.py` + wrappers | Generates and checks `docs/ci-catalog.md` from `.github/workflows/ci.yml`. |
| `test_tooling_catalog_unit` | `tb/test_tooling_catalog_unit.py` | Pytest checks for Python requirement metadata, installer profiles, GitHub release sources, environment variables, and generated tooling catalog freshness. |
| `generate-tooling-catalog` | `scripts/tooling_catalog.py` + wrappers | Generates and checks `docs/tooling-catalog.md` from `requirements.txt`, installer scripts, and the CI toolchain pin. |
| `test_verification_matrix_unit` | `tb/test_verification_matrix_unit.py` | Pytest checks for verification-lane coverage across native SV, cocotb, pyuvm, assertions, formal targets, artifacts, and mutation benches. |
| `generate-verification-matrix` | `scripts/verification_matrix.py` + wrappers | Generates and checks `docs/verification-matrix.md` from the lane matrix source. |
| `test_artifact_catalog_unit` | `tb/test_artifact_catalog_unit.py` | Pytest checks that generated result artifacts, formal workdirs, CI upload paths, and show-helper wrappers stay aligned. |
| `generate-artifact-catalog` | `scripts/artifact_catalog.py` + wrappers | Generates and checks `docs/artifact-catalog.md` from the verification matrix and GitHub Actions upload metadata. |
| `test_requirements_traceability_unit` | `tb/test_requirements_traceability_unit.py` | Pytest checks that verification requirements reference valid lanes, formal targets, mutation benches, and artifacts. |
| `generate-requirements-traceability` | `scripts/requirements_traceability.py` + wrappers | Generates and checks `docs/requirements-traceability.md` from the requirements-to-evidence map. |
| `test_mutation_unit` | `tb/test_mutation_unit.py` | Pytest checks for mutation definition validity, applicable RTL snippets, and generated mutation catalog freshness. |
| `generate-mutation-catalog` | `scripts/mutation_catalog.py` + wrappers | Generates and checks `docs/mutation-catalog.md` from mutation definitions and bench scopes. |
| `run-mutations` | `scripts/run_mutation_campaign.py` + wrappers | Builds temporary broken RTL variants across the core, APB, Wishbone, AXI-Lite, and wait-state shells, then confirms the native benches kill them. |
| `run-formal --mode cover` | `scripts/run-formal.*` + `formal/*cover*` | Generates witness traces for representative core/MMIO reachable scenarios. |
| `run-equiv` | `scripts/run-equiv.*` + `equiv/simple_cpu.eqy` | Proves the current core matches the tracked golden RTL snapshot. |
| `lint` / `show-static-analysis` | `scripts/static_analysis.py` + wrappers | Aggregates Verilator, Verible lint, Verible format verification, and svlint into repo-friendly logs plus JSON/Markdown summaries. |

## Coverage model (simple functional coverage)

1. Opcode hit bitmap for `NOP..CMP`.
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO/CARRY/NEG/OVERFLOW`.
6. Reachability metadata for ISA-impossible cross bins.
7. Flag bins for `CARRY`, `NEG`, `OVERFLOW` (0 and 1 observed).
8. Explicit closure bins mirrored from the native checker (`JZ x ZERO`, `ADD/SUB x CARRY`, `SUB/CMP x NEG`, `SHL x OVERFLOW`).
9. Program-run and executed-cycle counters.

Coverage artifacts:

1. `sim_build/coverage.json` (machine-readable summary + goals + reachability metadata)
2. `sim_build/coverage.csv` (flat metrics for spreadsheets/CI parsing)
3. `docs/coverage-baseline.json` (repo-tracked lower-bound baseline for regression checks)
4. `docs/coverage-history.json` / `docs/coverage-history.md` (tracked history and rendered trend report)
5. `docs/status/status.json` / `docs/status/status.md` (repo-tracked verification snapshot)
6. `docs/status/badges/*.json` (shields-compatible endpoint payloads)
7. `sim_build/pyuvm_coverage.json` (pyuvm coverage subscriber output)
8. `sim_build/asm_corpus/*.hex` (assembler corpus outputs)
9. `sim_build/mutations/mutation_summary.json` / `sim_build/mutations/mutation_summary.md` (mutation-campaign summaries)
10. `sim_build/mmio_coverage.json` / `sim_build/mmio_coverage.csv` (wrapper transaction coverage)
11. `sim_build/mmio_wait_coverage.json` / `sim_build/mmio_wait_coverage.csv` (wait-state MMIO wrapper transaction coverage)
12. `sim_build/apb_coverage.json` / `sim_build/apb_coverage.csv` (APB wrapper transaction coverage)
13. `sim_build/wishbone_coverage.json` / `sim_build/wishbone_coverage.csv` (Wishbone wrapper transaction coverage)
14. `sim_build/axi_lite_coverage.json` / `sim_build/axi_lite_coverage.csv` (AXI-Lite wrapper transaction coverage)
15. `sim_build/apb_fault_coverage.json` / `sim_build/apb_fault_coverage.csv` (APB fault-injection coverage)
16. `sim_build/wishbone_fault_coverage.json` / `sim_build/wishbone_fault_coverage.csv` (Wishbone fault-injection coverage)
17. `sim_build/axi_lite_fault_coverage.json` / `sim_build/axi_lite_fault_coverage.csv` (AXI-Lite fault-injection coverage)
18. `sim_build/verilator_coverage/summary.json` / `sim_build/verilator_coverage/summary.md` (Verilator structural coverage summary)
19. `sim_build/verilator_coverage/annotated/` (annotated source view for uncovered points)
20. `sim_build/static_analysis/summary.json` / `sim_build/static_analysis/summary.md` (static-analysis aggregate summary)
21. `sim_build/mmio_cocotb_results.xml` (MMIO cocotb regression results)
22. `sim_build/mmio_uvm_results.xml` (MMIO pyuvm regression results)
23. `sim_build/mmio_wait_cocotb_results.xml` (MMIO wait-state cocotb regression results)
24. `sim_build/mmio_wait_uvm_results.xml` (MMIO wait-state pyuvm regression results)
25. `sim_build/verilator_results.xml` (core cocotb-Verilator JUnit results)
26. `sim_build/apb_cocotb_results.xml` (APB cocotb regression results)
27. `sim_build/apb_uvm_results.xml` (APB pyuvm regression results)
28. `sim_build/wishbone_cocotb_results.xml` (Wishbone cocotb regression results)
29. `sim_build/wishbone_uvm_results.xml` (Wishbone pyuvm regression results)
30. `sim_build/axi_lite_cocotb_results.xml` (AXI-Lite cocotb regression results)
31. `sim_build/axi_lite_uvm_results.xml` (AXI-Lite pyuvm regression results)
32. `equiv/simple_cpu_eqy/` (EQY workdir and proof partitions)

Additional outputs:

1. `sim_build/program.hex` (from assembler flow)
2. `docs/mutation-catalog.md` (generated mutation definition and bench-scope catalog)
3. `docs/formal-targets.md` (generated formal target and SymbiYosys metadata catalog)
4. `docs/script-catalog.md` (generated cross-platform automation wrapper catalog)
5. `docs/ci-catalog.md` (generated GitHub Actions workflow catalog)
6. `docs/tooling-catalog.md` (generated open-source dependency and installer catalog)
7. `docs/verification-matrix.md` (generated verification-lane coverage matrix)
8. `docs/artifact-catalog.md` (generated verification artifact and CI upload catalog)
9. `docs/requirements-traceability.md` (generated requirements-to-evidence traceability matrix)

Implementation note:

1. Native `covergroup` syntax is not supported by the open-source simulator combo used here, so coverage is modeled with explicit sampled bins/cross-bins in SV tasks.
2. Formal properties are checked with SymbiYosys (`formal/simple_cpu.sby`, `formal/simple_cpu_mmio.sby`, `formal/simple_cpu_mmio_wait.sby`, `formal/simple_cpu_mmio_wait_faults.sby`, `formal/simple_cpu_apb.sby`, `formal/simple_cpu_apb_faults.sby`, `formal/simple_cpu_wishbone.sby`, `formal/simple_cpu_wishbone_faults.sby`, `formal/simple_cpu_axi_lite.sby`, and `formal/simple_cpu_axi_lite_faults.sby`) in bounded mode.
3. Automation scripts are organized by platform under `scripts/windows` and `scripts/linux`, with top-level wrappers in `scripts/`.
4. The Python `CoverageModel` mirrors the native SV coverage pass/fail conditions, including reachability checks for impossible bins.
5. `rtl/simple_cpu_mmio.sv` adds a tiny wrapper state machine that loads a shadow program image into the core over the existing programming interface before releasing execution.
6. The assembler corpus can replay through the direct core testbench, the MMIO wrapper testbench, the wait-state MMIO wrapper testbench, the APB wrapper testbench, the Wishbone wrapper testbench, or the AXI-Lite-style wrapper testbench.
7. `tb/simple_cpu_wrapper_common_assertions.svh` centralizes the hold/load/run, loader-signal, and control-readback invariants that every wrapper must satisfy.
8. `tb/simple_cpu_mmio_assertions.sv` adds reusable interface assertions around `bus_ready` and instantiates the common checker library.
9. `tb/simple_cpu_mmio_wait_assertions.sv` is the parallel wait-state checker for delayed `bus_ready`, request capture, stable pending transaction fields, and the shared wrapper invariants from the common checker library.
10. `tb/simple_cpu_apb_assertions.sv` is the parallel APB checker for setup/access sequencing, `PREADY` gating, and the shared wrapper invariants from the common checker library.
11. `tb/simple_cpu_axi_lite_assertions.sv` is the parallel AXI-Lite checker for coupled write-channel acceptance, response hold/clear, read-response behavior, and the shared wrapper invariants from the common checker library.
12. `scripts/show-mmio-coverage.ps1` / `scripts/show-mmio-coverage.sh` summarize the MMIO wrapper coverage report without opening JSON manually.
13. `scripts/show-mmio-wait-coverage.ps1` / `scripts/show-mmio-wait-coverage.sh` summarize the wait-state MMIO wrapper coverage report without opening JSON manually.
14. `scripts/show-apb-coverage.ps1` / `scripts/show-apb-coverage.sh` summarize the APB wrapper coverage report without opening JSON manually.
15. `scripts/show-apb-fault-coverage.ps1` / `scripts/show-apb-fault-coverage.sh` summarize the APB fault-injection coverage report without opening JSON manually.
16. `scripts/show-wishbone-fault-coverage.ps1` / `scripts/show-wishbone-fault-coverage.sh` summarize the Wishbone fault-injection coverage report without opening JSON manually.
17. `scripts/show-axi-lite-fault-coverage.ps1` / `scripts/show-axi-lite-fault-coverage.sh` summarize the AXI-Lite fault-injection coverage report without opening JSON manually.
18. `scripts/coverage_history.py` plus wrapper commands track core/MMIO/MMIO-wait/APB coverage snapshots in `docs/coverage-history.json` and render ASCII trend output.
19. CI workflow is in `.github/workflows/ci.yml` and is split into python-model, native-sim, lint, formal, cocotb-verilator, equivalence, pyuvm, mutations, and summary jobs; the `python-model` job checks the executable reference spec before longer simulator jobs, the `native-sim` job runs the direct core, MMIO, MMIO wait-state, APB, Wishbone, AXI-Lite, APB fault, Wishbone fault, and AXI-Lite fault native lanes plus corpus replay through APB, Wishbone, AXI-Lite, and MMIO wait-state, while the `pyuvm` job runs the direct pyuvm, MMIO pyuvm, MMIO cocotb, MMIO wait-state cocotb, MMIO wait-state pyuvm, APB cocotb, APB pyuvm, Wishbone cocotb, Wishbone pyuvm, AXI-Lite cocotb, and AXI-Lite pyuvm regressions.
20. Baseline comparisons are run through `scripts/check-coverage-delta.ps1` and `scripts/check-coverage-delta.sh`.
21. `scripts/show-formal-status.ps1` / `scripts/show-formal-status.sh` summarize formal target health and solver/runtime metadata across core, MMIO, MMIO wait-state, MMIO wait-state fault, APB, APB-fault, Wishbone, Wishbone-fault, AXI-Lite, AXI-Lite-fault, and cover targets.
22. `scripts/export-status.ps1` / `scripts/export-status.sh` export repo-tracked verification status Markdown/JSON plus badge endpoint payloads, including optional suite summaries such as `mmio_wait_coverage`, `pyuvm_coverage`, `cocotb_verilator`, `mmio_cocotb`, `mmio_pyuvm`, `mmio_wait_cocotb`, `mmio_wait_pyuvm`, `apb_coverage`, `apb_fault_coverage`, `apb_cocotb`, `apb_pyuvm`, `wishbone_coverage`, `wishbone_fault_coverage`, `wishbone_cocotb`, `wishbone_pyuvm`, `axi_lite_coverage`, `axi_lite_fault_coverage`, `axi_lite_cocotb`, and `axi_lite_pyuvm`.
23. `tb/protocol_conformance.py` is the shared scenario library that replays the same smoke, logic, loop, branch-stress, and randomized programs across the direct core, MMIO, APB, Wishbone, and AXI-Lite buses.
24. `tb/core_bus.py`, `tb/mmio_bus.py`, `tb/apb_bus.py`, `tb/wishbone_bus.py`, and `tb/axi_lite_bus.py` expose the same high-level load/start/sample interface so the shared conformance suite can verify wrapper parity instead of only per-wrapper local tests.
25. `formal/simple_cpu_mmio.sby` swaps in an abstract `simple_cpu` stub so the wrapper proof focuses on MMIO control/address behavior instead of re-proving CPU internals.
26. `formal/simple_cpu_mmio_wait.sby` swaps in an abstract `simple_cpu_mmio` stub so the wait-state proof focuses on request latching, fixed-cycle delay, and delayed read-data pass-through instead of re-proving MMIO internals.
27. `formal/simple_cpu_mmio_wait_faults.sby` keeps a separate wait-state fault proof focused on captured-request integrity under later external bus glitches and on forbidding early `bus_ready` responses.
28. `formal/simple_cpu_apb.sby` swaps in an abstract `simple_cpu_mmio` stub so the APB proof focuses on setup/access handshake behavior and MMIO read-data pass-through instead of re-proving MMIO internals.
29. `formal/simple_cpu_apb_faults.sby` keeps APB fault proofs separate from the baseline APB shell contract by driving deterministic setup/glitch/reload sequences through a small stateful MMIO stub.
30. The dedicated `formal/*cover_formal.sv` harnesses keep `sby cover` focused on one witness goal per target so trace generation stays fast.
31. `scripts/run-cocotb-verilator.sh` auto-uses a cached Linux OSS CAD Suite Verilator when the distro package is too old for cocotb.
32. `scripts/linux/oss-cad-suite.sh` centralizes Linux OSS CAD Suite release selection, retrying GitHub release queries/downloads and honoring `OSS_CAD_SUITE_RELEASE_TAG` for reproducible CI runs.
33. `scripts/static_analysis.py` is the single entry point behind `lint`, `show-static-analysis`, and `format-sv`.
34. `equiv/simple_cpu_golden.sv` is the tracked golden snapshot; refresh it intentionally with `scripts/update-equivalence-golden.*` only when the new RTL behavior is meant to become the baseline.
35. `formal/simple_cpu_wishbone.sby` swaps in an abstract `simple_cpu_mmio` stub so the Wishbone proof focuses on `CYC/STB/ACK` translation and MMIO read-data pass-through instead of re-proving MMIO internals.
36. `formal/simple_cpu_wishbone_faults.sby` keeps Wishbone fault proofs separate from the baseline Wishbone shell contract by driving deterministic `CYC`-only, `STB`-without-`CYC`, and reload sequences through a small stateful MMIO stub.
37. `formal/simple_cpu_axi_lite.sby` swaps in an abstract `simple_cpu_mmio` stub so the AXI-Lite proof focuses on coupled-channel write acceptance, response hold/clear, partial-write rejection, and registered read-data capture.
38. `formal/simple_cpu_axi_lite_faults.sby` keeps AXI-Lite fault proofs separate from the baseline AXI-Lite shell contract by driving deterministic `AWVALID`-only, `WVALID`-only, split-channel, pending-response, and reload sequences through a small stateful MMIO stub.
39. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, `rtl/simple_cpu_apb.sv`, `rtl/simple_cpu_wishbone.sv`, and `rtl/simple_cpu_axi_lite.sv`; those files remain covered by Verilator lint and svlint.
40. `tb/cpu_lib.py` exposes disassembly and cycle-by-cycle trace helpers so the Python reference model can be used as both a scoreboard oracle and a human-readable debug tool.
41. `docs/isa.md` is generated by `scripts/isa_report.py` and checked in CI so opcode metadata remains aligned across the assembler and Python reference model.
42. `docs/assembler-regressions.md` is generated by `scripts/asm_corpus_report.py` and checked in CI so the tracked assembly corpus has a readable, non-stale summary.
43. `docs/formal-targets.md` is generated by `scripts/formal_catalog.py` and checked in CI so `.sby` target metadata and run-formal wrapper coverage remain aligned.
44. `docs/script-catalog.md` is generated by `scripts/script_catalog.py` and checked in CI so top-level wrappers, platform implementations, and `scripts/README.md` common entrypoints remain aligned.
45. `docs/ci-catalog.md` is generated by `scripts/ci_catalog.py` and checked in CI so GitHub Actions job names, summary fan-in, script references, artifact metadata, and the pinned OSS CAD Suite release remain reviewable and valid.
46. `docs/tooling-catalog.md` is generated by `scripts/tooling_catalog.py` and checked in CI so Python requirements, installer profiles, GitHub release sources, environment variables, and OSS CAD Suite pins remain reviewable and valid.
47. `docs/verification-matrix.md` is generated by `scripts/verification_matrix.py` and checked in CI so native SV, cocotb, pyuvm, formal, assertion, artifact, and mutation-bench coverage remain aligned across lanes.
48. `docs/artifact-catalog.md` is generated by `scripts/artifact_catalog.py` and checked in CI so result files, coverage reports, formal workdirs, CI upload paths, and show-helper wrappers remain aligned.
49. `docs/requirements-traceability.md` is generated by `scripts/requirements_traceability.py` and checked in CI so tutorial verification claims remain connected to executable lanes, formal targets, mutation benches, and artifacts.
50. `docs/mutation-catalog.md` is generated by `scripts/mutation_catalog.py` and checked in CI so mutation definitions, bench scopes, and RTL replacement snippets remain reviewable and valid.
51. `tb/mmio_bus.py` factors the cocotb MMIO reset/read/write/control helpers into a reusable Python bus-functional layer and now waits for delayed `bus_ready`, so the same helper can drive both the always-ready and wait-state wrappers.
52. `tb/apb_bus.py` is the parallel reusable Python bus-functional layer for the APB shell, keeping the higher-level control/status semantics aligned with MMIO while checking a real setup/access handshake.
53. `tb/wishbone_bus.py` is the parallel reusable Python bus-functional layer for the Wishbone shell, keeping the higher-level control/status semantics aligned with MMIO while checking a real `CYC/STB/ACK` handshake.

Formal properties currently checked:

1. Core halted state is sticky (`HALTED` stays high and `PC` stops advancing once halted).
2. Core programming interface stalls execution state updates while `prog_we` is asserted.
3. MMIO `bus_ready` stays asserted for every request.
4. MMIO status, `ACC`, `PC`, control, and representative shadow-window reads return the expected encoded values.
5. MMIO `HOLD`, `LOAD`, and `RUN` transitions follow the intended control-register protocol.
6. MMIO loader signals (`core_rst_n`, `prog_we`, `prog_addr`) stay aligned with wrapper state.
7. Representative shadow-image slots update only on addressed writes and otherwise remain stable across hold/load/run operation.
8. MMIO wait-state `bus_ready` stays low until the fixed wait expires, then mirrors the inner MMIO ready signal.
9. MMIO wait-state request fields (`write`, `addr`, `wdata`) are captured once and stay stable until service.
10. MMIO wait-state read data is exactly the delayed inner MMIO read data.
11. MMIO wait-state fault proofs show a captured read request cannot be replaced by later external bus activity and cannot return ready/data before the configured delay expires.
12. APB `PREADY` stays low outside setup/access completion and matches the translated MMIO handshake during access.
13. APB status, `ACC`, `PC`, control, DMEM-window, and representative shadow-window reads match the abstract MMIO model.
14. APB-side `core_rst_n`, `prog_we`, `prog_addr`, and `prog_data` stay aligned with the translated MMIO programming path.
15. APB fault proofs show setup-only writes are ignored, `PENABLE` glitches without `PSEL` are ignored, and a shadow update made during `RUN` is only reloaded after an explicit stop/start sequence.
16. Wishbone `ACK` stays low when `CYC` is low or when `CYC` is high without `STB`, and matches the translated MMIO ready signal on active Wishbone transfers.
17. Wishbone status, `ACC`, `PC`, control, DMEM-window, and representative shadow-window reads match the abstract MMIO model.
18. AXI-Lite accepts writes only when `AWVALID` and `WVALID` are present together, blocks partial writes, holds `BVALID/RVALID` until ready, and returns the data captured at read-address acceptance.
19. AXI-Lite fault proofs show `AWVALID`-only, `WVALID`-only, and split-channel attempts cannot write shadow state or start execution, a pending `BVALID` blocks a second write, and a shadow update made during `RUN` is only reloaded after an explicit stop/start sequence.
20. Cover mode produces one core witness showing program-write then execute-to-halt, one MMIO witness showing start-to-run-to-halt, one MMIO wait-state witness showing request-to-delay-to-service, one APB witness showing setup-to-access-to-start-to-halt behavior, one Wishbone witness showing cycle-to-strobe-to-run-to-halt behavior, and one AXI-Lite witness showing partial/write/read/start traffic.

Known toolchain notes (non-fatal when runs pass):

1. Icarus may emit `always_*` constant-select warnings.
2. Yosys may emit `$global_clock` and memory-lowering warnings during formal prep.
3. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow remains fast enough for CI without weakening the wrapper-level claims.
4. The Windows equivalence wrapper intentionally routes through WSL because some packaged `eqy.exe` builds are unstable.
5. `scripts/run-cocotb-verilator.sh` may download Linux OSS CAD Suite into `~/tools/oss-cad-suite/oss-cad-suite` when the system Verilator is older than the cocotb minimum.
6. Export `OSS_CAD_SUITE_RELEASE_TAG=YYYY-MM-DD` when reproducing CI exactly; leave it unset for the moving latest daily OSS CAD Suite release during exploratory local runs.
7. If WSL reports `Bash/Service/E_UNEXPECTED` during a long-running bash command, restart WSL or rerun from PowerShell; that is a host-shell failure rather than a DUT/proof failure.
8. WSL formal runs from `/mnt/c/...` can be much slower than GitHub Actions or native Linux because of mounted-filesystem I/O overhead.
9. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, `rtl/simple_cpu_apb.sv`, `rtl/simple_cpu_wishbone.sv`, and `rtl/simple_cpu_axi_lite.sv`; those files are still covered by Verilator lint and svlint.

## Remaining exercises

1. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage over the full 16-byte shadow image.
2. Add a sixth wrapper protocol beyond the current MMIO always-ready, MMIO wait-state, APB, Wishbone, and AXI-Lite shells.
3. Extend the mutation set beyond the current MMIO wait-state, APB, Wishbone, and AXI-Lite shell set, for example with formal-harness or Python-lane regressions.
4. Grow the mutation set further with automatically generated arithmetic/control-flow variants.
5. Extend the reusable Python bus-functional layer beyond this register-mapped interface once the project grows into a distinct protocol family.
