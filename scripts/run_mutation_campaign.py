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
    target_file: str
    bench_names: tuple[str, ...]
    replacements: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class Bench:
    name: str
    sources: tuple[str, ...]
    binary_name: str


def make_mutation(
    *,
    name: str,
    category: str,
    description: str,
    target_file: str,
    bench_names: tuple[str, ...],
    replacements: tuple[tuple[str, str], ...],
) -> Mutation:
    return Mutation(
        name=name,
        category=category,
        description=description,
        target_file=target_file,
        bench_names=bench_names,
        replacements=replacements,
    )


def make_assign_mutation(
    *,
    name: str,
    description: str,
    target_file: str,
    bench_names: tuple[str, ...],
    lhs: str,
    old_rhs: str,
    new_rhs: str,
) -> Mutation:
    return make_mutation(
        name=name,
        category="protocol",
        description=description,
        target_file=target_file,
        bench_names=bench_names,
        replacements=((f"    assign {lhs} = {old_rhs};", f"    assign {lhs} = {new_rhs};"),),
    )


def make_port_mutation(
    *,
    name: str,
    description: str,
    target_file: str,
    bench_names: tuple[str, ...],
    port_name: str,
    old_expr: str,
    new_expr: str,
) -> Mutation:
    return make_mutation(
        name=name,
        category="protocol",
        description=description,
        target_file=target_file,
        bench_names=bench_names,
        replacements=((f"        .{port_name}({old_expr}),", f"        .{port_name}({new_expr}),"),),
    )


def make_localparam_mutation(
    *,
    name: str,
    description: str,
    target_file: str,
    bench_names: tuple[str, ...],
    declaration: str,
    old_value: str,
    new_value: str,
) -> Mutation:
    return make_mutation(
        name=name,
        category="protocol",
        description=description,
        target_file=target_file,
        bench_names=bench_names,
        replacements=((f"    localparam {declaration} = {old_value};", f"    localparam {declaration} = {new_value};"),),
    )


def build_core_mutations() -> tuple[Mutation, ...]:
    common = {
        "target_file": "rtl/simple_cpu.sv",
        "bench_names": ("core_tb", "mmio_tb", "mmio_wait_tb", "apb_tb", "wishbone_tb", "axi_lite_tb"),
    }
    return (
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
        make_mutation(
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
            **common,
        ),
    )


def build_apb_protocol_mutations() -> tuple[Mutation, ...]:
    common = {
        "target_file": "rtl/simple_cpu_apb.sv",
        "bench_names": ("apb_tb", "apb_fault_tb"),
    }
    return (
        make_assign_mutation(
            name="apb_setup_acts_like_access",
            description="Drive the inner MMIO bus during APB setup instead of waiting for PENABLE.",
            lhs="mmio_valid",
            old_rhs="psel && penable",
            new_rhs="psel",
            **common,
        ),
        make_assign_mutation(
            name="apb_pready_ignores_valid",
            description="Let PREADY ignore the APB valid phase.",
            lhs="pready",
            old_rhs="mmio_valid && mmio_ready",
            new_rhs="mmio_ready",
            **common,
        ),
        make_assign_mutation(
            name="apb_readback_zeroed",
            description="Break APB readback by forcing PRDATA low.",
            lhs="prdata",
            old_rhs="mmio_rdata",
            new_rhs="8'h00",
            **common,
        ),
        make_port_mutation(
            name="apb_write_polarity_inverted",
            description="Invert APB write polarity before it reaches the MMIO shell.",
            port_name="bus_write",
            old_expr="pwrite",
            new_expr="~pwrite",
            **common,
        ),
    )


def build_wait_protocol_mutations() -> tuple[Mutation, ...]:
    common = {
        "target_file": "rtl/simple_cpu_mmio_wait.sv",
        "bench_names": ("mmio_wait_tb",),
    }
    return (
        make_localparam_mutation(
            name="mmio_wait_zero_delay",
            description="Remove the intended one-cycle wait from the delayed MMIO wrapper.",
            declaration="logic [1:0] WAIT_CYCLES",
            old_value="2'd1",
            new_value="2'd0",
            **common,
        ),
        make_assign_mutation(
            name="mmio_wait_ready_early",
            description="Assert bus_ready as soon as a request is pending instead of waiting for service.",
            lhs="bus_ready",
            old_rhs="inner_bus_valid && inner_bus_ready",
            new_rhs="pending && inner_bus_ready",
            **common,
        ),
        make_assign_mutation(
            name="mmio_wait_readback_zeroed",
            description="Force delayed MMIO reads to return zero instead of the inner wrapper data.",
            lhs="bus_rdata",
            old_rhs="inner_bus_rdata",
            new_rhs="8'h00",
            **common,
        ),
        make_port_mutation(
            name="mmio_wait_write_data_zeroed",
            description="Drop captured write data before it reaches the inner MMIO shell.",
            port_name="bus_wdata",
            old_expr="req_wdata",
            new_expr="8'h00",
            **common,
        ),
    )


def build_wishbone_protocol_mutations() -> tuple[Mutation, ...]:
    common = {
        "target_file": "rtl/simple_cpu_wishbone.sv",
        "bench_names": ("wishbone_tb", "wishbone_fault_tb"),
    }
    return (
        make_assign_mutation(
            name="wishbone_cycle_acts_like_strobe",
            description="Drive the inner MMIO bus when CYC is high even if STB is low.",
            lhs="mmio_valid",
            old_rhs="wb_cyc_i && wb_stb_i",
            new_rhs="wb_cyc_i",
            **common,
        ),
        make_assign_mutation(
            name="wishbone_ack_ignores_valid",
            description="Let ACK ignore the Wishbone valid phase.",
            lhs="wb_ack_o",
            old_rhs="mmio_valid && mmio_ready",
            new_rhs="mmio_ready",
            **common,
        ),
        make_assign_mutation(
            name="wishbone_readback_zeroed",
            description="Break Wishbone readback by forcing DAT_O low.",
            lhs="wb_dat_o",
            old_rhs="mmio_rdata",
            new_rhs="8'h00",
            **common,
        ),
        make_port_mutation(
            name="wishbone_write_polarity_inverted",
            description="Invert Wishbone write polarity before it reaches the MMIO shell.",
            port_name="bus_write",
            old_expr="wb_we_i",
            new_expr="~wb_we_i",
            **common,
        ),
    )


def build_axi_lite_protocol_mutations() -> tuple[Mutation, ...]:
    common = {
        "target_file": "rtl/simple_cpu_axi_lite.sv",
        "bench_names": ("axi_lite_tb",),
    }
    return (
        make_assign_mutation(
            name="axi_lite_aw_only_write_accept",
            description="Accept an AXI-Lite write when only AWVALID is present.",
            lhs="write_accept",
            old_rhs="mmio_ready && !write_resp_valid && axi_awvalid && axi_wvalid",
            new_rhs="mmio_ready && !write_resp_valid && axi_awvalid",
            **common,
        ),
        make_assign_mutation(
            name="axi_lite_bvalid_stuck_low",
            description="Drop AXI-Lite write responses.",
            lhs="axi_bvalid",
            old_rhs="write_resp_valid",
            new_rhs="1'b0",
            **common,
        ),
        make_assign_mutation(
            name="axi_lite_readback_zeroed",
            description="Break AXI-Lite readback by forcing RDATA low.",
            lhs="axi_rdata",
            old_rhs="read_data_q",
            new_rhs="8'h00",
            **common,
        ),
        make_port_mutation(
            name="axi_lite_write_polarity_inverted",
            description="Invert AXI-Lite write polarity before it reaches the MMIO shell.",
            port_name="bus_write",
            old_expr="mmio_write",
            new_expr="~mmio_write",
            **common,
        ),
    )


MUTATIONS = (
    build_core_mutations()
    + build_apb_protocol_mutations()
    + build_wait_protocol_mutations()
    + build_wishbone_protocol_mutations()
    + build_axi_lite_protocol_mutations()
)

BENCHES = (
    Bench(
        name="core_tb",
        sources=("rtl/simple_cpu.sv", "tb/simple_cpu_tb.sv"),
        binary_name="simple_cpu_tb.vvp",
    ),
    Bench(
        name="mmio_tb",
        sources=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "tb/simple_cpu_mmio_assertions.sv", "tb/simple_cpu_mmio_tb.sv"),
        binary_name="simple_cpu_mmio_tb.vvp",
    ),
    Bench(
        name="apb_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_apb.sv",
            "tb/simple_cpu_apb_assertions.sv",
            "tb/simple_cpu_apb_tb.sv",
        ),
        binary_name="simple_cpu_apb_tb.vvp",
    ),
    Bench(
        name="wishbone_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_wishbone.sv",
            "tb/simple_cpu_wishbone_assertions.sv",
            "tb/simple_cpu_wishbone_tb.sv",
        ),
        binary_name="simple_cpu_wishbone_tb.vvp",
    ),
    Bench(
        name="axi_lite_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_axi_lite.sv",
            "tb/simple_cpu_axi_lite_assertions.sv",
            "tb/simple_cpu_axi_lite_tb.sv",
        ),
        binary_name="simple_cpu_axi_lite_tb.vvp",
    ),
    Bench(
        name="mmio_wait_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_mmio_wait.sv",
            "tb/simple_cpu_mmio_wait_assertions.sv",
            "tb/simple_cpu_mmio_wait_tb.sv",
        ),
        binary_name="simple_cpu_mmio_wait_tb.vvp",
    ),
    Bench(
        name="apb_fault_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_apb.sv",
            "tb/simple_cpu_apb_assertions.sv",
            "tb/simple_cpu_apb_fault_tb.sv",
        ),
        binary_name="simple_cpu_apb_fault_tb.vvp",
    ),
    Bench(
        name="wishbone_fault_tb",
        sources=(
            "rtl/simple_cpu.sv",
            "rtl/simple_cpu_mmio.sv",
            "rtl/simple_cpu_wishbone.sv",
            "tb/simple_cpu_wishbone_assertions.sv",
            "tb/simple_cpu_wishbone_fault_tb.sv",
        ),
        binary_name="simple_cpu_wishbone_fault_tb.vvp",
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


def run_bench(mutated_rtl: Path, mutation: Mutation, mutation_dir: Path, bench: Bench) -> dict:
    vvp_path = mutation_dir / bench.binary_name
    compile_log = mutation_dir / f"{bench.name}_compile.log"
    run_log = mutation_dir / f"{bench.name}_run.log"

    compile_sources: list[str] = []
    for source in bench.sources:
        if source == mutation.target_file:
            compile_sources.append(str(mutated_rtl))
        else:
            compile_sources.append(str(PROJECT_ROOT / source))

    compile_cmd = [
        "iverilog",
        "-g2012",
        "-DNO_WAVES",
        "-o",
        str(vvp_path),
    ]
    compile_cmd.extend(compile_sources)

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

    benches_by_name = {bench.name: bench for bench in BENCHES}
    summary: list[dict] = []
    campaign_pass = True
    bench_kill_counts = {bench.name: 0 for bench in BENCHES}

    for mutation in MUTATIONS:
        mutation_dir = OUTPUT_ROOT / mutation.name
        mutation_dir.mkdir(parents=True, exist_ok=True)
        base_rtl = (PROJECT_ROOT / mutation.target_file).read_text(encoding="utf-8")
        mutated_rtl = mutation_dir / Path(mutation.target_file).name
        mutated_rtl.write_text(apply_mutation(base_rtl, mutation), encoding="utf-8")

        selected_benches = [benches_by_name[name] for name in mutation.bench_names]
        results = [run_bench(mutated_rtl, mutation, mutation_dir, bench) for bench in selected_benches]
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
                "target_file": mutation.target_file,
                "bench_scope": list(mutation.bench_names),
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
