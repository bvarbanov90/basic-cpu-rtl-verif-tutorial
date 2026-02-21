# Basic CPU RTL Verification Tutorial (Open Source Only)

This project is a from-scratch tutorial for verifying a tiny CPU using only open-source tooling.

## What you will build

1. A tiny 8-bit CPU in SystemVerilog.
2. A simulator-native self-checking testbench (`tb/simple_cpu_tb.sv`).
3. Directed and randomized tests, including a reference-model comparison.
4. Waveform debug flow with open-source tools.
5. Optional cocotb/Python verification extension.

## Core tooling (all open source)

1. Icarus Verilog (`iverilog` + `vvp`)
2. GTKWave (optional waveform viewer)
3. Verilator (optional lint)

## Optional tooling (advanced step)

1. Python + cocotb
2. GNU Make

Use Python 3.13 for the cocotb flow in this tutorial setup.

## Project layout

```text
basic-cpu-rlt--verif-tutorial/
|- rtl/
|  |- simple_cpu.sv
|- .github/
|  |- workflows/
|     |- ci.yml
|- formal/
|  |- simple_cpu.sby
|  |- simple_cpu_formal.sv
|- programs/
|  |- counter_loop.asm
|  |- logic_flags.asm
|- tb/
|  |- simple_cpu_tb.sv
|  |- test_simple_cpu.py
|- scripts/
|  |- asm.py
|  |- README.md
|  |- windows/
|  |  |- install-tools.ps1
|  |  |- run.ps1
|  |  |- run-asm.ps1
|  |  |- check-all.ps1
|  |  |- lint.ps1
|  |  |- run-formal.ps1
|  |  |- open-waves.ps1
|  |  |- open-waves.cmd
|  |  |- show-coverage.ps1
|  |- linux/
|  |  |- install-tools-ubuntu.sh
|  |  |- run.sh
|  |  |- run-asm.sh
|  |  |- check-all.sh
|  |  |- lint.sh
|  |  |- run-formal.sh
|  |  |- open-waves.sh
|  |  |- show-coverage.sh
|  |- run.ps1 (wrapper)
|  |- run.sh (wrapper)
|  |- check-all.ps1 / check-all.sh (wrappers)
|  |- ... (compat wrappers for old paths)
|- docs/
|  |- verification-plan.md
|  |- github-publish-checklist.md
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

Notes:

1. `scripts/run-formal.sh` auto-selects `cvc5` first, then `z3`.
2. Override solver if needed: `bash scripts/run-formal.sh --solver z3`.
3. Open waves in WSLg with: `bash scripts/open-waves.sh`.

If you saw `libcairo-2.dll` or GTK `libpixbufloader-svg.dll` errors before, these launcher scripts apply a compatibility workaround automatically.

Direct implementation paths (optional):

1. Windows PowerShell: `.\scripts\windows\run.ps1`
2. Linux bash: `bash scripts/linux/run.sh`

## Lint

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\lint.ps1
```

## Formal checks

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\run-formal.ps1
```

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

## CI

GitHub Actions workflow `main`/PR checks are defined in `.github/workflows/ci.yml` and run:

1. Simulator regression + coverage gate (`bash scripts/check-all.sh`)
2. Assembled sample program checks (`logic_flags.asm`, `counter_loop.asm`)
3. Coverage artifact upload (`sim_build/coverage.json`, `sim_build/coverage.csv`)

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

## Suggested learning path

1. Run `.\scripts\run.ps1`.
2. Read `rtl/simple_cpu.sv` and trace opcode decode logic.
3. Read `tb/simple_cpu_tb.sv` and follow helper tasks (`reset_dut`, `load_program`, `run_until_halt`).
4. Study directed tests for branch-taken, branch-not-taken, jump loops, wraparound arithmetic, and illegal opcode handling.
5. Study how `test_randomized_suite` compares DUT state to a reference model over 20 seeds.
6. Review `report_and_check_coverage` to understand coverage thresholds and failures.
7. Break the RTL intentionally (for example, change `ADD`) and confirm tests/coverage gates fail.

## Functional coverage (simple model)

The SystemVerilog testbench includes sampled functional coverage implemented in portable SV tasks (compatible with Icarus/Verilator in this setup):

1. Opcode hit bitmap (`NOP..CMP`).
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO`.
6. Flag bins (`CARRY/NEG/OVERFLOW` each observed as 0 and 1).
7. Program-run and total-cycle counters.

Coverage thresholds are checked at end-of-run; unmet goals fail the simulation.

Coverage artifacts written on each run:

1. `sim_build/coverage.json`
2. `sim_build/coverage.csv`

Quick summary command:

```powershell
.\scripts\show-coverage.ps1
```

## Known benign warnings

1. Icarus can print `constant selects in always_* processes are not fully supported`.
2. SymbiYosys/Yosys can print warnings around `$global_clock` in the formal harness.
3. Yosys can print memory lowering notes (`Replacing memory ... with list of registers`).
4. On some WSL setups, `z3` can be unstable; use `bash scripts/run-formal.sh` (defaults to `cvc5`).

These warnings are expected for this toolchain/tutorial and are non-fatal when all checks pass.

## Next extensions

1. Add branch-heavy constrained-random generation with bounded loops.
2. Add full opcode x flag cross coverage for all flag states.
3. Add CI jobs for simulation + coverage + formal.
4. Add a tiny assembler regression corpus and compare coverage drift over time.

## Publish To GitHub

1. Follow `docs/github-publish-checklist.md` for clean init/push steps.
2. Run both sanity flows before first push:

```powershell
.\scripts\check-all.ps1
```

```bash
bash scripts/check-all.sh
```
