from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = PROJECT_ROOT / "sim_build" / "mutations"


@dataclass(frozen=True)
class Mutation:
    name: str
    category: str
    description: str
    replacements: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class Bench:
    name: str
    sources: tuple[str, ...]
    binary_name: str


MUTATIONS = (
    Mutation(
        name="jz_inverted",
        category="control_flow",
        description="Invert the ZERO-branch decision.",
        replacements=(
            (
                "            OPC_JZ: begin\n"
                "                if (zero) begin\n"
                "                    next_pc = operand;\n"
                "                end\n"
                "            end",
                "            OPC_JZ: begin\n"
                "                if (!zero) begin\n"
                "                    next_pc = operand;\n"
                "                end\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="store_disabled",
        category="memory",
        description="Disable data-memory writes for STA.",
        replacements=(
            (
                "                if (opcode == OPC_STA) begin\n"
                "                    dmem[operand] <= acc;\n"
                "                end",
                "                if (1'b0) begin\n"
                "                    dmem[operand] <= acc;\n"
                "                end",
            ),
        ),
    ),
    Mutation(
        name="shift_carry_stuck_low",
        category="flags",
        description="Break SHL carry-out reporting.",
        replacements=(
            (
                "                next_carry = acc[7];\n"
                "                next_overflow = acc[7] ^ shift_left_result[7];",
                "                next_carry = 1'b0;\n"
                "                next_overflow = acc[7] ^ shift_left_result[7];",
            ),
        ),
    ),
    Mutation(
        name="illegal_opcode_not_halt",
        category="control_flow",
        description="Let illegal opcodes fall through instead of halting.",
        replacements=(
            (
                "            default: begin\n"
                "                next_pc = pc;\n"
                "                next_halted = 1'b1;\n"
                "            end",
                "            default: begin\n"
                "                next_pc = pc + 4'd1;\n"
                "                next_halted = 1'b0;\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="add_uses_sub",
        category="alu",
        description="Drive ADD from the subtraction datapath.",
        replacements=(
            (
                "            OPC_ADD: begin\n"
                "                next_acc = add_result[7:0];\n"
                "                next_zero = (add_result[7:0] == 8'h00);\n"
                "                next_neg = add_result[7];\n"
                "                next_carry = add_result[8];\n"
                "                next_overflow = add_overflow;\n"
                "            end",
                "            OPC_ADD: begin\n"
                "                next_acc = sub_result[7:0];\n"
                "                next_zero = (sub_result[7:0] == 8'h00);\n"
                "                next_neg = sub_result[7];\n"
                "                next_carry = ~sub_result[8];\n"
                "                next_overflow = sub_overflow;\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="sub_uses_add",
        category="alu",
        description="Drive SUB from the addition datapath.",
        replacements=(
            (
                "            OPC_SUB: begin\n"
                "                next_acc = sub_result[7:0];\n"
                "                next_zero = (sub_result[7:0] == 8'h00);\n"
                "                next_neg = sub_result[7];\n"
                "                next_carry = ~sub_result[8];\n"
                "                next_overflow = sub_overflow;\n"
                "            end",
                "            OPC_SUB: begin\n"
                "                next_acc = add_result[7:0];\n"
                "                next_zero = (add_result[7:0] == 8'h00);\n"
                "                next_neg = add_result[7];\n"
                "                next_carry = add_result[8];\n"
                "                next_overflow = add_overflow;\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="jmp_fallthrough",
        category="control_flow",
        description="Make JMP behave like a fall-through instruction.",
        replacements=(
            (
                "            OPC_JMP: begin\n"
                "                next_pc = operand;\n"
                "            end",
                "            OPC_JMP: begin\n"
                "                next_pc = pc + 4'd1;\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="cmp_clobbers_acc",
        category="flags",
        description="Incorrectly update ACC during CMP.",
        replacements=(
            (
                "            OPC_CMP: begin\n"
                "                next_zero = (sub_result[7:0] == 8'h00);\n"
                "                next_neg = sub_result[7];\n"
                "                next_carry = ~sub_result[8];\n"
                "                next_overflow = sub_overflow;\n"
                "            end",
                "            OPC_CMP: begin\n"
                "                next_acc = sub_result[7:0];\n"
                "                next_zero = (sub_result[7:0] == 8'h00);\n"
                "                next_neg = sub_result[7];\n"
                "                next_carry = ~sub_result[8];\n"
                "                next_overflow = sub_overflow;\n"
                "            end",
            ),
        ),
    ),
    Mutation(
        name="hlt_fallthrough",
        category="control_flow",
        description="Allow HLT to advance instead of stopping execution.",
        replacements=(
            (
                "            OPC_HLT: begin\n"
                "                next_pc = pc;\n"
                "                next_halted = 1'b1;\n"
                "            end",
                "            OPC_HLT: begin\n"
                "                next_pc = pc + 4'd1;\n"
                "                next_halted = 1'b0;\n"
                "            end",
            ),
        ),
    ),
)

BENCHES = (
    Bench(
        name="core_tb",
        sources=("tb/simple_cpu_tb.sv",),
        binary_name="simple_cpu_tb.vvp",
    ),
    Bench(
        name="mmio_tb",
        sources=("rtl/simple_cpu_mmio.sv", "tb/simple_cpu_mmio_assertions.sv", "tb/simple_cpu_mmio_tb.sv"),
        binary_name="simple_cpu_mmio_tb.vvp",
    ),
)


def apply_mutation(base_text: str, mutation: Mutation) -> str:
    mutated = base_text
    for old, new in mutation.replacements:
        if old in mutated:
            mutated = mutated.replace(old, new, 1)
            continue

        pattern = re.compile(
            "".join(r"\s+" if part.isspace() else re.escape(part) for part in re.split(r"(\s+)", old)),
            flags=re.MULTILINE,
        )
        mutated, replace_count = pattern.subn(lambda _: new, mutated, count=1)
        if replace_count != 1:
            raise ValueError(f"Mutation '{mutation.name}' could not find expected snippet")
    return mutated


def run_command(cmd: list[str], cwd: Path, log_path: Path) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    log_path.write_text(
        f"$ {' '.join(cmd)}\n\n[stdout]\n{result.stdout}\n[stderr]\n{result.stderr}\n",
        encoding="utf-8",
    )
    return result


def run_bench(mutated_rtl: Path, mutation_dir: Path, bench: Bench) -> dict:
    vvp_path = mutation_dir / bench.binary_name
    compile_log = mutation_dir / f"{bench.name}_compile.log"
    run_log = mutation_dir / f"{bench.name}_run.log"

    compile_cmd = [
        "iverilog",
        "-g2012",
        "-DNO_WAVES",
        "-o",
        str(vvp_path),
        str(mutated_rtl),
    ]
    compile_cmd.extend(str(PROJECT_ROOT / source) for source in bench.sources)

    compile_result = run_command(compile_cmd, PROJECT_ROOT, compile_log)
    if compile_result.returncode != 0:
        return {
            "bench": bench.name,
            "status": "compile_failed",
            "compile_log": str(compile_log.relative_to(PROJECT_ROOT)),
            "run_log": None,
        }

    run_result = run_command(["vvp", str(vvp_path)], PROJECT_ROOT, run_log)
    status = "killed" if run_result.returncode != 0 else "survived"
    return {
        "bench": bench.name,
        "status": status,
        "compile_log": str(compile_log.relative_to(PROJECT_ROOT)),
        "run_log": str(run_log.relative_to(PROJECT_ROOT)),
    }


def render_markdown(campaign_pass: bool, summary: list[dict], bench_kill_counts: dict[str, int]) -> str:
    lines = [
        "# Mutation Campaign Summary",
        "",
        f"Campaign pass: {'PASS' if campaign_pass else 'FAIL'}",
        "",
        "## Bench Kill Counts",
        "",
        "| Bench | Mutants killed |",
        "|---|---|",
    ]
    for bench_name in sorted(bench_kill_counts):
        lines.append(f"| {bench_name} | {bench_kill_counts[bench_name]} |")

    lines.extend(
        [
            "",
            "## Mutation Results",
            "",
            "| Mutation | Category | Result | Killed by | Description |",
            "|---|---|---|---|---|",
        ]
    )
    for mutation in summary:
        lines.append(
            "| {name} | {category} | {result} | {killed_by} | {description} |".format(
                name=mutation["name"],
                category=mutation["category"],
                result="PASS" if mutation["mutation_pass"] else "FAIL",
                killed_by=", ".join(mutation["killed_by"]) if mutation["killed_by"] else "none",
                description=mutation["description"],
            )
        )

    return "\n".join(lines) + "\n"


def main() -> int:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    base_rtl = (PROJECT_ROOT / "rtl" / "simple_cpu.sv").read_text(encoding="utf-8")
    summary: list[dict] = []
    campaign_pass = True
    bench_kill_counts = {bench.name: 0 for bench in BENCHES}

    for mutation in MUTATIONS:
        mutation_dir = OUTPUT_ROOT / mutation.name
        mutation_dir.mkdir(parents=True, exist_ok=True)
        mutated_rtl = mutation_dir / "simple_cpu.sv"
        mutated_rtl.write_text(apply_mutation(base_rtl, mutation), encoding="utf-8")

        results = [run_bench(mutated_rtl, mutation_dir, bench) for bench in BENCHES]
        killed_by = [result["bench"] for result in results if result["status"] == "killed"]
        for bench_name in killed_by:
            bench_kill_counts[bench_name] += 1
        mutation_ok = len(killed_by) > 0 and all(result["status"] != "compile_failed" for result in results)
        if not mutation_ok:
            campaign_pass = False

        summary.append(
            {
                "name": mutation.name,
                "category": mutation.category,
                "description": mutation.description,
                "killed_by": killed_by,
                "killed_by_count": len(killed_by),
                "results": results,
                "mutation_pass": int(mutation_ok),
            }
        )

        if mutation_ok:
            print(f"[MUTATION][PASS] {mutation.name} killed by {', '.join(killed_by)}")
        else:
            print(f"[MUTATION][FAIL] {mutation.name} survived or failed to compile correctly")

    summary_path = OUTPUT_ROOT / "mutation_summary.json"
    markdown_path = OUTPUT_ROOT / "mutation_summary.md"
    summary_path.write_text(
        json.dumps(
            {
                "campaign_pass": int(campaign_pass),
                "total_mutations": len(summary),
                "bench_kill_counts": bench_kill_counts,
                "mutations": summary,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(render_markdown(campaign_pass, summary, bench_kill_counts), encoding="utf-8")

    print(f"[MUTATION] summary written to {summary_path.relative_to(PROJECT_ROOT)}")
    print(f"[MUTATION] summary written to {markdown_path.relative_to(PROJECT_ROOT)}")
    return 0 if campaign_pass else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except FileNotFoundError as exc:
        print(f"[MUTATION][FAIL] Missing tool or file: {exc}", file=sys.stderr)
        raise SystemExit(1)
    except ValueError as exc:
        print(f"[MUTATION][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
