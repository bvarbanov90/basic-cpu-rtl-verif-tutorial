# Basic CPU RTL Verification Tutorial (Open Source Only)

This project is a from-scratch tutorial for verifying a tiny CPU using only open-source tooling.

[![overall](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/overall.json)](docs/status/status.md)
[![core coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/core-coverage.json)](docs/status/status.md)
[![mmio coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-coverage.json)](docs/status/status.md)
[![mmio wait coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-wait-coverage.json)](docs/status/status.md)
[![apb coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/apb-coverage.json)](docs/status/status.md)
[![apb fault coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/apb-fault-coverage.json)](docs/status/status.md)
[![formal](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/formal.json)](docs/status/status.md)
[![equivalence](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/equivalence.json)](docs/status/status.md)
[![static analysis](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/static-analysis.json)](docs/status/status.md)
[![mutations](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mutations.json)](docs/status/status.md)
[![cocotb verilator](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/cocotb-verilator.json)](docs/status/status.md)
[![mmio cocotb](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-cocotb.json)](docs/status/status.md)
[![mmio pyuvm](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-pyuvm.json)](docs/status/status.md)
[![mmio wait cocotb](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-wait-cocotb.json)](docs/status/status.md)
[![mmio wait pyuvm](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/mmio-wait-pyuvm.json)](docs/status/status.md)
[![apb cocotb](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/apb-cocotb.json)](docs/status/status.md)
[![apb pyuvm](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/apb-pyuvm.json)](docs/status/status.md)
[![verilator coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/bvarbanov90/basic-cpu-rtl-verif-tutorial/main/docs/status/badges/verilator-coverage.json)](docs/status/status.md)

## What you will build

1. A tiny 8-bit CPU in SystemVerilog.
2. A simulator-native self-checking testbench (`tb/simple_cpu_tb.sv`).
3. Directed tests plus dataflow and branch-stress randomized regressions with reference-model comparison.
4. Waveform debug flow with open-source tools.
5. Assembler-corpus regressions with expected machine code, final state, and coverage signatures.
6. Wrapper-protocol flows that verify interface-level programming and observability on top of the core, including MMIO always-ready, MMIO wait-state, and APB-style shells.
7. Optional cocotb/pyuvm Python verification extensions.
8. A mutation campaign that proves the regressions kill representative RTL bugs.
9. A repo-tracked verification status export with Markdown, JSON, and badge-ready endpoints.
10. A multi-tool static-analysis lane with Verilator, Verible lint/format, and svlint.

## Core tooling (all open source)

1. Icarus Verilog (`iverilog` + `vvp`)
2. GTKWave (optional waveform viewer)
3. Verilator (lint plus cocotb cross-simulator regression)
4. SymbiYosys (`sby`) for bounded proofs and witness traces
5. EQY for RTL equivalence checks against a golden snapshot
6. Verible for SystemVerilog lint and formatting
7. svlint as a second open-source RTL checker

## Optional tooling (advanced step)

1. Python + cocotb + pyuvm
2. GNU Make (or WSL Ubuntu for Python simulator flows)

Use Python 3.13 for the cocotb flow in this tutorial setup. On Windows, `.\scripts\run-uvm.ps1`, `.\scripts\run-mmio-uvm.ps1`, `.\scripts\run-cocotb-verilator.ps1`, `.\scripts\run-cocotb-mmio.ps1`, `.\scripts\run-cocotb-mmio-wait.ps1`, `.\scripts\run-mmio-wait-uvm.ps1`, `.\scripts\run-cocotb-apb.ps1`, and `.\scripts\run-apb-uvm.ps1` fall back to WSL automatically if native GNU build tooling is unavailable.

## Project layout

```text
basic-cpu-rlt--verif-tutorial/
|- rtl/
|  |- simple_cpu.sv
|  |- simple_cpu_mmio.sv
|  |- simple_cpu_mmio_wait.sv
|  |- simple_cpu_apb.sv
|- .github/
|  |- workflows/
|     |- ci.yml
|- .rules.verible_lint
|- .svlint.toml
|- formal/
|  |- simple_cpu.sby
|  |- simple_cpu_cover.sby
|  |- simple_cpu_formal.sv
|  |- simple_cpu_mmio.sby
|  |- simple_cpu_mmio_cover.sby
|  |- simple_cpu_mmio_formal.sv
|  |- simple_cpu_mmio_wait.sby
|  |- simple_cpu_mmio_wait_cover.sby
|  |- simple_cpu_mmio_wait_formal.sv
|  |- simple_cpu_mmio_wait_cover_formal.sv
|  |- simple_cpu_mmio_wait_stub.sv
|  |- simple_cpu_apb.sby
|  |- simple_cpu_apb_faults.sby
|  |- simple_cpu_apb_cover.sby
|  |- simple_cpu_apb_formal.sv
|  |- simple_cpu_apb_fault_formal.sv
|  |- simple_cpu_apb_cover_formal.sv
|  |- simple_cpu_apb_mmio_stub.sv
|  |- simple_cpu_apb_fault_mmio_stub.sv
|  |- simple_cpu_cover_formal.sv
|  |- simple_cpu_mmio_cover_formal.sv
|- equiv/
|  |- simple_cpu.eqy
|  |- simple_cpu_golden.sv
|- programs/
|  |- branch_taken.asm
|  |- counter_loop.asm
|  |- logic_flags.asm
|  |- memory_roundtrip.asm
|  |- raw_illegal.asm
|  |- sparse_jump.asm
|- tb/
|  |- coverage_utils.py
|  |- cpu_lib.py
|  |- apb_bus.py
|  |- mmio_bus.py
|  |- simple_cpu_apb_assertions.sv
|  |- simple_cpu_apb_fault_tb.sv
|  |- simple_cpu_apb_tb.sv
|  |- simple_cpu_mmio_assertions.sv
|  |- simple_cpu_mmio_wait_assertions.sv
|  |- simple_cpu_mmio_tb.sv
|  |- simple_cpu_mmio_wait_tb.sv
|  |- simple_cpu_tb.sv
|  |- test_simple_cpu.py
|  |- test_simple_cpu_mmio.py
|  |- test_simple_cpu_mmio_pyuvm.py
|  |- test_simple_cpu_apb.py
|  |- test_simple_cpu_apb_pyuvm.py
|  |- test_simple_cpu_pyuvm.py
|- scripts/
|  |- asm.py
|  |- README.md
|  |- check_asm_corpus.py
|  |- export_status.py
|  |- run_mutation_campaign.py
|  |- show_formal_status.py
|  |- static_analysis.py
|  |- status_lib.py
|  |- verilator_coverage_report.py
|  |- windows/
|  |  |- install-tools.ps1
|  |  |- run.ps1
|  |  |- run-asm.ps1
|  |  |- run-asm-corpus.ps1
|  |  |- run-mmio.ps1
|  |  |- run-mmio-wait.ps1
|  |  |- run-apb.ps1
|  |  |- run-apb-fault.ps1
|  |  |- run-mutations.ps1
|  |  |- run-uvm.ps1
|  |  |- run-mmio-uvm.ps1
|  |  |- run-cocotb-verilator.ps1
|  |  |- run-cocotb-mmio.ps1
|  |  |- run-cocotb-mmio-wait.ps1
|  |  |- run-mmio-wait-uvm.ps1
|  |  |- run-cocotb-apb.ps1
|  |  |- run-apb-uvm.ps1
|  |  |- run-equiv.ps1
|  |  |- check-all.ps1
|  |  |- format-sv.ps1
|  |  |- lint.ps1
|  |  |- run-formal.ps1
|  |  |- export-status.ps1
|  |  |- open-waves.ps1
|  |  |- open-waves.cmd
|  |  |- show-coverage.ps1
|  |  |- show-apb-coverage.ps1
|  |  |- show-apb-fault-coverage.ps1
|  |  |- show-mmio-wait-coverage.ps1
|  |  |- show-verilator-coverage.ps1
|  |  |- show-formal-status.ps1
|  |  |- show-static-analysis.ps1
|  |- linux/
|  |  |- install-tools-ubuntu.sh
|  |  |- run.sh
|  |  |- run-asm.sh
|  |  |- run-asm-corpus.sh
|  |  |- run-mmio.sh
|  |  |- run-mmio-wait.sh
|  |  |- run-apb.sh
|  |  |- run-apb-fault.sh
|  |  |- run-mutations.sh
|  |  |- run-uvm.sh
|  |  |- run-mmio-uvm.sh
|  |  |- run-cocotb-verilator.sh
|  |  |- run-cocotb-mmio.sh
|  |  |- run-cocotb-mmio-wait.sh
|  |  |- run-mmio-wait-uvm.sh
|  |  |- run-cocotb-apb.sh
|  |  |- run-apb-uvm.sh
|  |  |- run-equiv.sh
|  |  |- check-all.sh
|  |  |- format-sv.sh
|  |  |- lint.sh
|  |  |- run-formal.sh
|  |  |- export-status.sh
|  |  |- open-waves.sh
|  |  |- show-coverage.sh
|  |  |- show-apb-coverage.sh
|  |  |- show-apb-fault-coverage.sh
|  |  |- show-mmio-wait-coverage.sh
|  |  |- show-verilator-coverage.sh
|  |  |- show-formal-status.sh
|  |  |- show-static-analysis.sh
|  |- run.ps1 (wrapper)
|  |- run.sh (wrapper)
|  |- run-asm-corpus.ps1 / run-asm-corpus.sh (wrappers)
|  |- check-native.ps1 / check-native.sh (wrappers)
|  |- run-mmio.ps1 / run-mmio.sh (wrappers)
|  |- run-mmio-wait.ps1 / run-mmio-wait.sh (wrappers)
|  |- run-apb.ps1 / run-apb.sh (wrappers)
|  |- run-apb-fault.ps1 / run-apb-fault.sh (wrappers)
|  |- run-mutations.ps1 / run-mutations.sh (wrappers)
|  |- run-uvm.ps1 / run-uvm.sh (wrappers)
|  |- run-mmio-uvm.ps1 / run-mmio-uvm.sh (wrappers)
|  |- run-cocotb-verilator.ps1 / run-cocotb-verilator.sh (wrappers)
|  |- run-cocotb-mmio.ps1 / run-cocotb-mmio.sh (wrappers)
|  |- run-cocotb-mmio-wait.ps1 / run-cocotb-mmio-wait.sh (wrappers)
|  |- run-mmio-wait-uvm.ps1 / run-mmio-wait-uvm.sh (wrappers)
|  |- run-cocotb-apb.ps1 / run-cocotb-apb.sh (wrappers)
|  |- run-apb-uvm.ps1 / run-apb-uvm.sh (wrappers)
|  |- run-equiv.ps1 / run-equiv.sh (wrappers)
|  |- format-sv.ps1 / format-sv.sh (wrappers)
|  |- check-coverage-delta.ps1 / check-coverage-delta.sh (wrappers)
|  |- update-equivalence-golden.ps1 / update-equivalence-golden.sh (wrappers)
|  |- update-coverage-baseline.ps1 / update-coverage-baseline.sh (wrappers)
|  |- check-all.ps1 / check-all.sh (wrappers)
|  |- export-status.ps1 / export-status.sh (wrappers)
|  |- show-apb-coverage.ps1 / show-apb-coverage.sh (wrappers)
|  |- show-apb-fault-coverage.ps1 / show-apb-fault-coverage.sh (wrappers)
|  |- show-mmio-wait-coverage.ps1 / show-mmio-wait-coverage.sh (wrappers)
|  |- show-formal-status.ps1 / show-formal-status.sh (wrappers)
|  |- show-static-analysis.ps1 / show-static-analysis.sh (wrappers)
|  |- ... (compat wrappers for old paths)
|- docs/
|  |- assembler-regressions.json
|  |- coverage-baseline.json
|  |- status/
|  |  |- status.json
|  |  |- status.md
|  |  |- badges/*.json
|  |- verification-plan.md
|- Makefile
|- requirements.txt
|- README.md
```

Script organization note:

1. `scripts/windows/*` and `scripts/linux/*` are the platform-specific implementations.
2. `scripts/*.ps1` and `scripts/*.sh` at the top level are compatibility wrappers.
3. Existing commands from earlier tutorial steps continue to work.

## CPU summary

1. `imem[16]`: 16-byte instruction memory.
2. `dmem[16]`: 16-byte data memory.
3. Registers: `ACC` (8-bit accumulator), `PC` (4-bit), flags `ZERO/CARRY/NEG/OVERFLOW`, `HALTED`.
4. Instruction format: `[7:4] opcode`, `[3:0] operand`.

### ISA

| Opcode | Mnemonic | Behavior |
|---|---|---|
| `0x0` | `NOP` | no operation |
| `0x1` | `LDI imm4` | `ACC = imm4` |
| `0x2` | `ADD addr4` | `ACC = ACC + DMEM[addr4]` |
| `0x3` | `SUB addr4` | `ACC = ACC - DMEM[addr4]` |
| `0x4` | `STA addr4` | `DMEM[addr4] = ACC` |
| `0x5` | `LDA addr4` | `ACC = DMEM[addr4]` |
| `0x6` | `JMP addr4` | `PC = addr4` |
| `0x7` | `JZ addr4` | if `ZERO`, `PC = addr4` |
| `0x8` | `HLT` | halt execution |
| `0x9` | `AND addr4` | `ACC = ACC & DMEM[addr4]` |
| `0xA` | `OR addr4` | `ACC = ACC \| DMEM[addr4]` |
| `0xB` | `XOR addr4` | `ACC = ACC ^ DMEM[addr4]` |
| `0xC` | `SHL` | `ACC = ACC << 1` |
| `0xD` | `SHR` | `ACC = ACC >> 1` |
| `0xE` | `CMP addr4` | update flags from `ACC - DMEM[addr4]` (no write to `ACC`) |
| `0xF` | `ILLEGAL` | default trap-to-halt behavior |

## Quick start (recommended path)

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\run.ps1
```

To run without dumping waveforms:

```powershell
.\scripts\run.ps1 -NoWaves
```

To run with an external assembled program:

```powershell
.\scripts\run.ps1 -ProgramHex sim_build\program.hex
```

To assemble and run in one step:

```powershell
.\scripts\run-asm.ps1 -Source programs\logic_flags.asm
```

To run the MMIO wrapper regression:

```powershell
.\scripts\run-mmio.ps1 -NoWaves
```

To run the APB wrapper regression:

```powershell
.\scripts\run-apb.ps1 -NoWaves
```

To run the APB fault-injection native regression:

```powershell
.\scripts\run-apb-fault.ps1 -NoWaves
```

To summarize the wrapper coverage report:

```powershell
.\scripts\show-mmio-coverage.ps1
```

To summarize the APB wrapper coverage report:

```powershell
.\scripts\show-apb-coverage.ps1
```

To summarize the APB fault-coverage report:

```powershell
.\scripts\show-apb-fault-coverage.ps1
```

To run the tracked assembler corpus:

```powershell
.\scripts\run-asm-corpus.ps1
```

To replay the tracked assembler corpus through the MMIO wrapper:

```powershell
.\scripts\run-asm-corpus.ps1 -Runner mmio
```

To replay the tracked assembler corpus through the APB wrapper:

```powershell
.\scripts\run-asm-corpus.ps1 -Runner apb
```

To run the cocotb regression on Verilator and collect structural coverage:

```powershell
.\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage
```

To run the cocotb MMIO wrapper regression:

```powershell
.\scripts\run-cocotb-mmio.ps1 -NoWaves
```

To summarize the Verilator coverage report:

```powershell
.\scripts\show-verilator-coverage.ps1
```

To summarize the static-analysis lane:

```powershell
.\scripts\show-static-analysis.ps1
```

To summarize the formal targets:

```powershell
.\scripts\show-formal-status.ps1
```

To run the RTL equivalence check against the tracked golden snapshot:

```powershell
.\scripts\run-equiv.ps1
```

To export a repo-tracked status snapshot:

```powershell
.\scripts\export-status.ps1 -Label tutorial-regression
```

To open the generated waveform:

```powershell
.\scripts\open-waves.ps1
```

Alternative (cmd wrapper):

```cmd
scripts\open-waves.cmd
```

## WSL Ubuntu (bash)

Install Linux tools once:

```bash
cd /mnt/c/Users/bvarb/vscode_ws/basic-cpu-rlt--verif-tutorial
bash scripts/install-tools-ubuntu.sh
```

Run simulation:

```bash
bash scripts/run.sh --no-waves
```

Run with an assembled program:

```bash
bash scripts/run-asm.sh --source programs/logic_flags.asm --no-waves
```

Run lint:

```bash
bash scripts/lint.sh
```

Run formal:

```bash
bash scripts/run-formal.sh
```

Run formal proof plus cover-witness targets:

```bash
bash scripts/run-formal.sh --mode all
```

Run minimal pyuvm tests:

```bash
bash scripts/run-uvm.sh --no-waves
```

Run the assembler regression corpus:

```bash
bash scripts/run-asm-corpus.sh
```

Run the MMIO wrapper regression:

```bash
bash scripts/run-mmio.sh --no-waves
```

Run the APB wrapper regression:

```bash
bash scripts/run-apb.sh --no-waves
```

Run the APB fault-injection native regression:

```bash
bash scripts/run-apb-fault.sh --no-waves
```

Run the cocotb regression on Verilator and collect structural coverage:

```bash
bash scripts/run-cocotb-verilator.sh --no-waves --coverage
```

Run the cocotb MMIO wrapper regression:

```bash
bash scripts/run-cocotb-mmio.sh --no-waves
```

Show the Verilator coverage summary:

```bash
bash scripts/show-verilator-coverage.sh
```

Show the static-analysis summary:

```bash
bash scripts/show-static-analysis.sh
```

Run the RTL equivalence check:

```bash
bash scripts/run-equiv.sh
```

Show the wrapper coverage report:

```bash
bash scripts/show-mmio-coverage.sh
```

Show the APB wrapper coverage report:

```bash
bash scripts/show-apb-coverage.sh
```

Show the APB fault-coverage report:

```bash
bash scripts/show-apb-fault-coverage.sh
```

Show the formal target summary:

```bash
bash scripts/show-formal-status.sh
```

Export the repo-tracked status snapshot:

```bash
bash scripts/export-status.sh --label tutorial-regression
```

Notes:

1. `scripts/run-formal.sh` auto-selects `cvc5` first, then `z3`, then `boolector`.
2. `.\scripts\run-formal.ps1` follows the same rule and accepts `-Solver cvc5`, `-Solver z3`, or `-Solver boolector`.
3. `scripts/run-cocotb-verilator.sh` auto-installs and uses a Linux OSS CAD Suite Verilator under `~/tools/oss-cad-suite/oss-cad-suite` when the distro package is older than the cocotb minimum.
4. `scripts/lint.sh` resolves Verible from `~/tools/verible` and svlint from `~/tools/svlint` when they are not already on `PATH`.
5. `.\scripts\run-equiv.ps1` routes the EQY flow through WSL for stability; the native Windows `eqy.exe` shipped in some OSS CAD Suite builds is unreliable.
6. Open waves in WSLg with: `bash scripts/open-waves.sh`.
7. Use `bash scripts/run-asm-corpus.sh --no-simulate` when you want manifest checking without overwriting the main regression coverage report.
8. Use `bash scripts/run-asm-corpus.sh --runner mmio` to replay the corpus through the wrapper instead of the direct core testbench.
9. Use `bash scripts/run-asm-corpus.sh --runner apb` to replay the same corpus through the APB shell.
10. The MMIO cocotb runner uses Icarus and the dedicated `tb/test_simple_cpu_mmio.py` bus-level suite.
11. If you want WSL formal timings closer to GitHub Actions, keep the repo under the Linux filesystem (for example `~/basic-cpu-rlt--verif-tutorial`) instead of `/mnt/c/...`.

If you saw `libcairo-2.dll` or GTK `libpixbufloader-svg.dll` errors before, these launcher scripts apply a compatibility workaround automatically.

Direct implementation paths (optional):

1. Windows PowerShell: `.\scripts\windows\run.ps1`
2. Linux bash: `bash scripts/linux/run.sh`

## Lint

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\lint.ps1
```

This lane now runs:

1. `verilator --lint-only` on the synthesizable RTL
2. `verible-verilog-lint` on the hand-written SV sources
3. `verible-verilog-format --verify` on the same tracked source set
4. `svlint` on `rtl/simple_cpu.sv`, `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, and `rtl/simple_cpu_apb.sv`

Scope notes:

1. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, and `rtl/simple_cpu_apb.sv`. The current Verible release used here does not parse that wrapper family cleanly enough in this tutorial setup, so those files stay covered by Verilator lint and svlint instead.
2. `svlint` intentionally stays scoped to synthesizable RTL instead of benches/formal harnesses.

Outputs:

1. `sim_build/static_analysis/summary.json`
2. `sim_build/static_analysis/summary.md`
3. `sim_build/static_analysis/*.log`

Readable summary command:

```powershell
.\scripts\show-static-analysis.ps1
```

Reformat the tracked SystemVerilog sources in place:

```powershell
.\scripts\format-sv.ps1
```

## Formal checks

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\run-formal.ps1
```

Override the solver on Windows if needed:

```powershell
.\scripts\run-formal.ps1 -Solver cvc5
```

Run both proof and cover-witness targets:

```powershell
.\scripts\run-formal.ps1 -Mode all
```

Show the target-level formal summary:

```powershell
.\scripts\show-formal-status.ps1
```

The formal proof flow now runs:

1. `formal/simple_cpu.sby`
2. `formal/simple_cpu_mmio.sby`
3. `formal/simple_cpu_mmio_wait.sby`
4. `formal/simple_cpu_apb.sby`
5. `formal/simple_cpu_apb_faults.sby`

The formal cover flow runs:

1. `formal/simple_cpu_cover.sby`
2. `formal/simple_cpu_mmio_cover.sby`
3. `formal/simple_cpu_mmio_wait_cover.sby`
4. `formal/simple_cpu_apb_cover.sby`

Current formal properties cover:

1. core halted-state stickiness and programming-interface execution stalling,
2. MMIO `bus_ready` always-ready behavior,
3. MMIO address-map readback for status, `ACC`, `PC`, control, and boundary shadow slots,
4. MMIO `HOLD/LOAD/RUN` state transitions and loader sequencing,
5. representative shadow-image update/stability rules during hold, load, and run phases,
6. MMIO wait-state request capture, fixed delay, request stability, and delayed read-data pass-through,
7. APB setup/access gating (`PREADY` low unless `PSEL && PENABLE`),
8. APB pass-through mapping of the MMIO readback model onto the APB shell,
9. targeted APB fault scenarios for setup-only writes, aborted writes, `PENABLE`-without-`PSEL` glitches, and run-time shadow updates that only take effect after explicit reload.

The MMIO formal target uses an abstract debug-core stub instead of the full CPU implementation. Core behavior is already proved separately in `formal/simple_cpu.sby`; the wrapper proof focuses on MMIO loader/control/address-map logic so the CI formal step stays short.

The MMIO wait-state formal target uses an abstract MMIO stub instead of the full MMIO wrapper. MMIO semantics are already proved in `formal/simple_cpu_mmio.sby`; the wait-state proof focuses on request latching, fixed-cycle delay, and delayed read-data pass-through so the extra protocol target stays cheap.

The APB formal target uses an abstract MMIO stub instead of the full MMIO wrapper. MMIO semantics are already proved in `formal/simple_cpu_mmio.sby`; the APB proof focuses on setup/access handshake behavior and read-data pass-through so the extra protocol target stays cheap.

The APB fault formal target is split out intentionally. `formal/simple_cpu_apb_faults.sby` uses a small stateful MMIO stub and a deterministic APB stimulus harness so the setup/glitch/reload corner cases are proved directly without slowing down the baseline APB shell proof.

The cover targets use dedicated witness harnesses so `sby cover` produces fast, readable example traces instead of spending time trying to satisfy every proof-harness cover statement in one run.

## Full project sanity check

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\check-all.ps1
```

WSL/bash equivalent:

```bash
cd /mnt/c/Users/bvarb/vscode_ws/basic-cpu-rlt--verif-tutorial
bash scripts/check-all.sh
```

Native simulation only, without formal:

```powershell
.\scripts\check-native.ps1
```

```bash
bash scripts/check-native.sh
```

## CI

GitHub Actions workflow `main`/PR checks are defined in `.github/workflows/ci.yml` and are split into focused jobs:

1. `native-sim`: `bash scripts/check-native.sh` plus MMIO corpus replay
2. `lint`: `bash scripts/lint.sh`
3. `formal`: `bash scripts/run-formal.sh --mode all`
4. `cocotb-verilator`: `bash scripts/run-cocotb-verilator.sh --no-waves --coverage`
5. `equivalence`: `bash scripts/run-equiv.sh`
6. `pyuvm`: `bash scripts/run-uvm.sh --no-waves`, `bash scripts/run-mmio-uvm.sh --no-waves`, `bash scripts/run-cocotb-mmio.sh --no-waves`, `bash scripts/run-cocotb-mmio-wait.sh --no-waves`, `bash scripts/run-mmio-wait-uvm.sh --no-waves`, `bash scripts/run-cocotb-apb.sh --no-waves`, and `bash scripts/run-apb-uvm.sh --no-waves`
7. `mutations`: `bash scripts/run-mutations.sh`
8. `summary`: workflow-level pass/fail table in the GitHub Actions summary page

Uploaded artifacts include:

1. `sim_build/coverage.json`
2. `sim_build/coverage.csv`
3. `sim_build/mmio_coverage.json`
4. `sim_build/mmio_coverage.csv`
5. `sim_build/apb_coverage.json`
6. `sim_build/apb_coverage.csv`
7. `sim_build/apb_fault_coverage.json`
8. `sim_build/apb_fault_coverage.csv`
9. `sim_build/static_analysis/`
10. `sim_build/pyuvm_coverage.json`
11. `sim_build/uvm_results.xml`
12. `sim_build/mmio_uvm_results.xml`
13. `sim_build/mmio_cocotb_results.xml`
14. `sim_build/mmio_wait_cocotb_results.xml`
15. `sim_build/mmio_wait_uvm_results.xml`
16. `sim_build/apb_cocotb_results.xml`
17. `sim_build/apb_uvm_results.xml`
18. `sim_build/verilator_results.xml`
19. `sim_build/verilator_coverage/`
20. `sim_build/asm_corpus/`
21. `sim_build/mutations/`
22. `formal/simple_cpu_cover/`
23. `formal/simple_cpu_mmio_cover/`
24. `formal/simple_cpu_mmio_wait/`
25. `formal/simple_cpu_mmio_wait_cover/`
26. `formal/simple_cpu_apb/`
27. `formal/simple_cpu_apb_cover/`
28. `equiv/simple_cpu_eqy/`

## If tools are not installed yet

Recommended on Windows:

1. Run:

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\install-tools.ps1
```

2. Open a new PowerShell terminal.
3. Re-run `.\scripts\run.ps1`.

## Optional cocotb flow

Use this after the simulator-native flow works.

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
make SIM=icarus WAVES=1
```

Run the minimal pyuvm/UVM-style example:

```powershell
.\scripts\run-uvm.ps1 -NoWaves
```

```bash
bash scripts/run-uvm.sh --no-waves
```

Run the MMIO wrapper pyuvm/UVM-style example:

```powershell
.\scripts\run-mmio-uvm.ps1 -NoWaves
```

```bash
bash scripts/run-mmio-uvm.sh --no-waves
```

Run the wait-state MMIO variants on the same Python suites:

```powershell
.\scripts\run-cocotb-mmio-wait.ps1 -NoWaves
.\scripts\run-mmio-wait-uvm.ps1 -NoWaves
```

```bash
bash scripts/run-cocotb-mmio-wait.sh --no-waves
bash scripts/run-mmio-wait-uvm.sh --no-waves
```

Run the APB wrapper Python suites:

```powershell
.\scripts\run-cocotb-apb.ps1 -NoWaves
.\scripts\run-apb-uvm.ps1 -NoWaves
```

```bash
bash scripts/run-cocotb-apb.sh --no-waves
bash scripts/run-apb-uvm.sh --no-waves
```

The cocotb layer now also includes an assembler-corpus regression in `tb/test_simple_cpu.py`, and the pyuvm example in `tb/test_simple_cpu_pyuvm.py` now includes:

1. sequence-item driven smoke/random/branch tests,
2. deterministic corner-case sequences for `ADD/SUB/SHL/CMP` coverage closure,
3. a subscriber-based coverage collector that writes `sim_build/pyuvm_coverage.json`,
4. a program-port stall-and-retarget test that holds `prog_we` across multiple cycles, proves architectural state stops advancing, and confirms a future instruction patch is honored once execution resumes.

The MMIO pyuvm layer in `tb/test_simple_cpu_mmio_pyuvm.py` adds:

1. a sequence/driver/scoreboard wrapper environment over `tb/mmio_bus.py`,
2. reference-model checks for wrapper programming and randomized replay,
3. explicit `LOAD` then `RUN` state observation through the MMIO control register,
4. a direct pyuvm fault-injection test that proves shadow updates do not affect an in-flight run until reload.

The same MMIO cocotb and MMIO pyuvm suites now also run unchanged against `rtl/simple_cpu_mmio_wait.sv`, which keeps the same register map but inserts an external wait state before every bus handshake. The reusable `tb/mmio_bus.py` helper now waits for `bus_ready` instead of assuming an always-ready shell.

The APB wrapper protocol uses its own reusable Python bus-functional layer in `tb/apb_bus.py`. That keeps the higher-level shadow-program/control/status semantics aligned with MMIO while still checking a real APB-style setup/access handshake with `PSEL/PENABLE/PREADY`.

The same cocotb tests can now run on Verilator:

```powershell
.\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage
```

```bash
bash scripts/run-cocotb-verilator.sh --no-waves --coverage
```

The MMIO cocotb wrapper suite runs separately:

```powershell
.\scripts\run-cocotb-mmio.ps1 -NoWaves
```

```bash
bash scripts/run-cocotb-mmio.sh --no-waves
```

The MMIO cocotb layer in `tb/test_simple_cpu_mmio.py` covers:

1. wrapper programming/readback against the same `ReferenceCPU`,
2. control/status visibility across `HOLD`, `LOAD`, `RUN`, and `HALT`,
3. Python-side shadow fault injection that only takes effect after an explicit reload.

Its bus transactions now live in `tb/mmio_bus.py`, so future wrapper-level Python regressions can reuse the same reset/read/write/start/stop helper instead of duplicating bus logic.

The APB cocotb layer in `tb/test_simple_cpu_apb.py` covers:

1. wrapper programming/readback against the same `ReferenceCPU`,
2. control/status visibility across `HOLD`, `LOAD`, `RUN`, and `HALT`,
3. Python-side shadow fault injection with explicit reload behavior,
4. a protocol-focused check that `PREADY` stays low during the APB setup phase until `PENABLE` is asserted.

The APB pyuvm layer in `tb/test_simple_cpu_apb_pyuvm.py` mirrors the same protocol with sequence/driver/scoreboard structure over `tb/apb_bus.py`.

Generated Verilator artifacts:

1. `sim_build/verilator_results.xml`
2. `sim_build/verilator_coverage/merged.dat`
3. `sim_build/verilator_coverage/*.info`
4. `sim_build/verilator_coverage/annotated/`
5. `sim_build/verilator_coverage/summary.json`
6. `sim_build/verilator_coverage/summary.md`

Quick summary commands:

```powershell
.\scripts\show-verilator-coverage.ps1
```

```bash
bash scripts/show-verilator-coverage.sh
```

## MMIO wrapper flow

`rtl/simple_cpu_mmio.sv` wraps the core behind a tiny always-ready MMIO interface. It is intentionally simple enough to verify with the same open-source tools as the core.

`rtl/simple_cpu_mmio_wait.sv` is the second wrapper variant. It keeps the same address map and inner semantics, but latches each request and inserts a fixed wait state before asserting `bus_ready`. That gives the tutorial a second bus shell without changing the software-visible model.

The wait-state wrapper now also has dedicated SymbiYosys prove/cover targets. Those targets prove the request-capture and fixed-delay contract directly, without re-solving the MMIO semantics already covered by `formal/simple_cpu_mmio.sby`.

`rtl/simple_cpu_apb.sv` is the third wrapper protocol. It exposes the same address map through a minimal APB-style setup/access handshake and translates APB transfers into the internal MMIO transaction model.

Address map:

1. `0x00..0x0F`: shadow instruction image read/write window
2. `0x10`: status bits `{HALTED, OVERFLOW, NEG, CARRY, ZERO}`
3. `0x11`: `ACC`
4. `0x12`: `PC`
5. `0x20..0x2F`: data-memory read window
6. `0x30`: control/status register

Wrapper behavior:

1. Writing the instruction window updates a shadow program image.
2. Writing `0x30 = 0x01` resets the core into a 16-cycle loader phase, copies the shadow image into instruction memory, then starts execution.
3. Writing `0x30 = 0x00` returns the wrapper to hold/reset state for reprogramming.

The native wrapper testbench in `tb/simple_cpu_mmio_tb.sv` checks:

1. MMIO programming and instruction-shadow readback
2. reset/reprogram/run sequencing
3. a focused `SUB/CMP/JMP` sequence to close the wrapper mutation gap
4. assertion-based protocol/loader readback checks via `tb/simple_cpu_mmio_assertions.sv`
5. a shadow-image fault-injection test that proves run-time shadow writes do not perturb the in-flight program until the next explicit reload
6. status/data readback against the same reference-model semantics
7. external `.hex` program replay, so the tracked assembler corpus can run through the wrapper unchanged
8. a matching cocotb MMIO regression in `tb/test_simple_cpu_mmio.py` for Python-side bus-level checking
9. the same cocotb/pyuvm MMIO suites can also run against `rtl/simple_cpu_mmio_wait.sv`, proving the reusable Python bus-functional layer handles delayed `bus_ready`
10. a separate APB cocotb/pyuvm stack in `tb/test_simple_cpu_apb.py` and `tb/test_simple_cpu_apb_pyuvm.py`, proving the same shadow/control semantics under a different bus protocol

It also writes wrapper-specific coverage artifacts:

1. `sim_build/mmio_coverage.json`
2. `sim_build/mmio_coverage.csv`

The native wait-state wrapper testbench in `tb/simple_cpu_mmio_wait_tb.sv` checks:

1. the same programming, reprogramming, illegal-opcode, branch/control, and shadow-fault flows as the always-ready MMIO bench
2. assertion-based wait-state protocol checks via `tb/simple_cpu_mmio_wait_assertions.sv`
3. explicit delayed-handshake accounting for every native read/write transaction
4. external `.hex` replay through the delayed wrapper, so the assembler corpus can run through the wait-state shell unchanged

It also writes wait-state-specific coverage artifacts:

1. `sim_build/mmio_wait_coverage.json`
2. `sim_build/mmio_wait_coverage.csv`

Quick summary commands:

```powershell
.\scripts\show-mmio-coverage.ps1
.\scripts\show-mmio-wait-coverage.ps1
```

```bash
bash scripts/show-mmio-coverage.sh
bash scripts/show-mmio-wait-coverage.sh
```

Current MMIO coverage goals:

1. at least 4 wrapper program runs
2. shadow writes/reads cover the full 16-byte image on every run
3. data-memory reads cover the full 16-byte window on every run
4. status, `ACC`, and `PC` reads occur on every run
5. start/stop control writes occur on every run

Current MMIO wait-state coverage goals:

1. the same full-image/readback/control visibility goals as the always-ready MMIO shell
2. every native read/write transaction observes a delayed handshake
3. at least one delayed cycle is observed per transaction
4. the maximum observed wait is at least one cycle

The native APB wrapper testbench in `tb/simple_cpu_apb_tb.sv` checks:

1. APB setup/access handshakes across instruction-window, control, status, and debug-data reads
2. APB-side programming, reprogramming, and loader start/stop sequencing
3. a focused `SUB/CMP/JMP` replay against the same reference model used by the direct and MMIO benches
4. assertion-based protocol checks via `tb/simple_cpu_apb_assertions.sv`
5. a shadow-image fault-injection test that proves APB writes during `RUN` only affect the next explicit reload
6. external `.hex` program replay, so the tracked assembler corpus can run through the APB shell unchanged

The dedicated APB fault-injection testbench in `tb/simple_cpu_apb_fault_tb.sv` checks:

1. setup-only shadow writes have no side effects until a real access phase occurs
2. aborted APB writes do not update the wrapper shadow image
3. setup-only `CONTROL=1` writes do not start the loader
4. `PENABLE` glitches without `PSEL` do not cause hidden writes or starts
5. shadow writes during `RUN` are staged for the next reload and do not perturb the in-flight program

It also writes APB-specific coverage artifacts:

1. `sim_build/apb_coverage.json`
2. `sim_build/apb_coverage.csv`

It also writes APB fault-specific coverage artifacts:

1. `sim_build/apb_fault_coverage.json`
2. `sim_build/apb_fault_coverage.csv`

Quick summary commands:

```powershell
.\scripts\show-apb-coverage.ps1
.\scripts\show-apb-fault-coverage.ps1
```

```bash
bash scripts/show-apb-coverage.sh
bash scripts/show-apb-fault-coverage.sh
```

Current APB coverage goals:

1. at least 4 wrapper program runs
2. shadow writes/reads cover the full 16-byte image on every run
3. status, `ACC`, `PC`, and control reads occur on every run
4. APB setup and access phases are both observed on read and write traffic
5. start/stop control writes occur on every run
6. `HOLD`, `LOAD`, and `RUN` wrapper states are all observed

Current APB fault-coverage goals:

1. at least one setup-only shadow write is proven to be ignored
2. at least one aborted write is proven to be ignored
3. at least one setup-only start command is proven to be ignored
4. at least one `PENABLE`-without-`PSEL` glitch is proven to be ignored
5. a run-time shadow update is observed immediately in shadow readback but only affects execution after an explicit reload

## Assembler regression corpus

The project includes a small tracked corpus of assembly programs with expected outputs in `docs/assembler-regressions.json`.

Run it from PowerShell:

```powershell
.\scripts\run-asm-corpus.ps1
```

Run it from bash/WSL:

```bash
bash scripts/run-asm-corpus.sh
```

Use `.\scripts\run-asm-corpus.ps1 -NoSimulate` or `bash scripts/run-asm-corpus.sh --no-simulate` when you want manifest checks without overwriting the main native-regression coverage report.

What it checks:

1. assembler output bytes match the manifest,
2. reference-model final state matches the manifest,
3. reference-model coverage signature subset matches the manifest,
4. optional RTL replay per corpus program.

The replay target can be either:

1. the direct core testbench (`direct`, default)
2. the MMIO wrapper testbench (`mmio`)
3. the MMIO wait-state wrapper testbench (`mmio_wait`)
4. the APB wrapper testbench (`apb`)

Artifacts:

1. `sim_build/asm_corpus/*.hex`

## Mutation campaign

The project includes an optional mutation campaign that compiles temporary broken RTL variants and confirms the regressions fail.

Run it from PowerShell:

```powershell
.\scripts\run-mutations.ps1
```

Run it from bash/WSL:

```bash
bash scripts/run-mutations.sh
```

Readable summary commands:

```powershell
.\scripts\show-mutations.ps1
```

```bash
bash scripts/show-mutations.sh
```

Current mutants:

1. inverted `JZ` branch condition
2. disabled `STA` writes
3. broken `SHL` carry-out
4. illegal-opcode path that no longer halts
5. `ADD` driven from the subtraction datapath
6. `SUB` driven from the addition datapath
7. `JMP` forced to fall through
8. `CMP` incorrectly clobbers `ACC`
9. `HLT` no longer stops execution
10. APB setup phase incorrectly driving the inner MMIO bus
11. APB `PREADY` incorrectly ignoring the valid phase
12. APB readback forced low
13. APB write polarity inverted before the MMIO shell
14. MMIO-wait zero-delay handshake
15. MMIO-wait `bus_ready` asserted one cycle too early
16. MMIO-wait readback forced low
17. MMIO-wait write data dropped before the inner MMIO shell

Artifacts:

1. `sim_build/mutations/mutation_summary.json`
2. `sim_build/mutations/mutation_summary.md`
3. `sim_build/mutations/<mutant>/*_compile.log`
4. `sim_build/mutations/<mutant>/*_run.log`

The current campaign is expected to be killed by the direct-core, MMIO-wrapper, MMIO wait-state, native APB-wrapper, and APB fault-injection benches. The APB protocol-shell mutants are intentionally scoped so `apb_tb` and `apb_fault_tb` are the deciding benches for setup/access and readback faults, while the MMIO-wait protocol mutants are intentionally scoped so `mmio_wait_tb` is the deciding bench for delayed-handshake faults.

## Suggested learning path

1. Run `.\scripts\run.ps1`.
2. Read `rtl/simple_cpu.sv` and trace opcode decode logic.
3. Read `tb/simple_cpu_tb.sv` and follow helper tasks (`reset_dut`, `load_program`, `run_until_halt`).
4. Study directed tests for branch-taken, branch-not-taken, jump loops, wraparound arithmetic, and illegal opcode handling.
5. Study how `test_randomized_suite` and `test_branch_randomized_suite` compare DUT state to a reference model over multiple seeds.
6. Review `report_and_check_coverage` and the generated `sim_build/coverage.json` cross-bins.
7. Break the RTL intentionally (for example, change `ADD` or `JZ`) and confirm tests/coverage gates fail.

## Functional coverage (simple model)

The SystemVerilog testbench includes sampled functional coverage implemented in portable SV tasks (compatible with Icarus/Verilator in this setup):

1. Opcode hit bitmap (`NOP..CMP`).
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO/CARRY/NEG/OVERFLOW`.
6. Flag bins (`CARRY/NEG/OVERFLOW` each observed as 0 and 1).
7. Reachability annotations for ISA-impossible opcode/flag bins.
8. Specific closure bins mirrored from the native checker (`JZ x ZERO`, `ADD/SUB x CARRY`, `SUB/CMP x NEG`, `SHL x OVERFLOW`).
9. Program-run and total-cycle counters.

Coverage thresholds are checked at end-of-run; unmet goals fail the simulation.

Coverage artifacts written on each run:

1. `sim_build/coverage.json`
2. `sim_build/coverage.csv`

The coverage reports label ISA-unreachable bins explicitly so a zero count does not look like a verification gap when the combination cannot occur by construction.
The repo also tracks a non-regression baseline in `docs/coverage-baseline.json`.

Coverage delta commands:

```powershell
.\scripts\check-coverage-delta.ps1
```

```bash
bash scripts/check-coverage-delta.sh
```

If you intentionally change the regression mix or improve coverage, regenerate the baseline after a clean passing run:

```powershell
.\scripts\update-coverage-baseline.ps1
```

```bash
bash scripts/update-coverage-baseline.sh
```

Quick summary command:

```powershell
.\scripts\show-coverage.ps1
```

```bash
bash scripts/show-coverage.sh
```

## Coverage history and trends

Snapshot the latest core/MMIO coverage into repo-tracked history files:

```powershell
.\scripts\record-coverage-history.ps1 -Label tutorial-regression
```

```bash
bash scripts/record-coverage-history.sh
```

Show the tracked ASCII trend report:

```powershell
.\scripts\show-coverage-trend.ps1
```

```bash
bash scripts/show-coverage-trend.sh
```

Tracked history files:

1. `docs/coverage-history.json`
2. `docs/coverage-history.md`

## Verification status export

After a passing run, export a repo-tracked verification snapshot:

```powershell
.\scripts\export-status.ps1 -Label tutorial-regression
```

```bash
bash scripts/export-status.sh --label tutorial-regression
```

Inspect the formal status without opening `formal/*` manually:

```powershell
.\scripts\show-formal-status.ps1
```

```bash
bash scripts/show-formal-status.sh
```

Generated status files:

1. `docs/status/status.json`
2. `docs/status/status.md`
3. `docs/status/badges/*.json`

The badge JSON files are compatible with shields.io endpoint badges when served from GitHub raw or GitHub Pages.

The status export now includes:

1. proof plus cover formal targets,
2. the EQY equivalence workdir status,
3. the optional Verilator coverage summary,
4. the static-analysis summary from `sim_build/static_analysis/summary.json`,
5. optional suite summaries for `pyuvm_coverage`, `cocotb_verilator`, `mmio_cocotb`, `mmio_pyuvm`, `mmio_wait_cocotb`, `mmio_wait_pyuvm`, `apb_coverage`, `apb_fault_coverage`, `apb_cocotb`, `apb_pyuvm`, and `mutations`.

## Known benign warnings

1. Icarus can print `constant selects in always_* processes are not fully supported`.
2. SymbiYosys/Yosys can print warnings around `$global_clock` in the formal harness.
3. Yosys can print memory lowering notes (`Replacing memory ... with list of registers`).
4. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow stays fast enough for CI without weakening the wrapper-level properties.
5. Verilator structural coverage can report a lower overall percentage than the functional coverage gate because it measures line/toggle/expression activity, not intent-level bins.
6. The Windows equivalence wrapper intentionally prefers WSL because some OSS CAD Suite `eqy.exe` builds are unstable.
7. `svlint` is intentionally scoped to the synthesizable RTL so the secondary checker stays focused on real coding hazards instead of tutorial/testbench naming conventions.
8. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, and `rtl/simple_cpu_apb.sv` because the current release used in this tutorial does not parse that wrapper family cleanly enough.
9. If WSL itself reports `Bash/Service/E_UNEXPECTED` during a long-running command, restart WSL or rerun from PowerShell; that is a host-side shell-service failure, not a proof result.
10. WSL runs from `/mnt/c/...` can be materially slower than native Linux or GitHub Actions due to mounted-filesystem I/O overhead.

These warnings are expected for this toolchain/tutorial and are non-fatal when all checks pass.

## Next extensions

1. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage of the 16-byte shadow image and read windows.
2. Add a fourth wrapper protocol beyond the current MMIO always-ready, MMIO wait-state, and APB shells.
3. Extend the mutation set beyond the current MMIO wait-state and APB shell set, for example with formal-harness or Python-lane regressions.
4. Track lane-level JUnit summaries for more optional suites such as native SV smoke or assembler-corpus replay.

## Publish To GitHub

1. Run both sanity flows before first push:

```powershell
.\scripts\check-all.ps1
```

```bash
bash scripts/check-all.sh
```

2. Initialize and push:

```powershell
git init
git checkout -b main
git add .
git commit -m "Initial commit: basic CPU RTL verification tutorial"
git remote add origin git@github.com:<user-or-org>/<repo-name>.git
git push -u origin main
```
