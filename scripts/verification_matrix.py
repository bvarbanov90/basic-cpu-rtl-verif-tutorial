from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.run_mutation_campaign import BENCHES


@dataclass(frozen=True)
class VerificationLane:
    key: str
    title: str
    rtl: tuple[str, ...]
    native_script: str | None
    native_tb: str | None
    cocotb_script: str | None
    cocotb_test: str | None
    pyuvm_script: str | None
    pyuvm_test: str | None
    assertions: tuple[str, ...]
    formal_targets: tuple[str, ...]
    artifacts: tuple[str, ...]
    mutation_benches: tuple[str, ...]
    focus: str


LANES = (
    VerificationLane(
        key="core",
        title="Direct Core",
        rtl=("rtl/simple_cpu.sv",),
        native_script="run",
        native_tb="tb/simple_cpu_tb.sv",
        cocotb_script="run-cocotb-verilator",
        cocotb_test="tb/test_simple_cpu.py",
        pyuvm_script="run-uvm",
        pyuvm_test="tb/test_simple_cpu_pyuvm.py",
        assertions=(),
        formal_targets=("formal/simple_cpu.sby", "formal/simple_cpu_cover.sby"),
        artifacts=(
            "sim_build/coverage.json",
            "sim_build/coverage.csv",
            "sim_build/verilator_results.xml",
            "sim_build/verilator_coverage/summary.json",
            "sim_build/uvm_results.xml",
        ),
        mutation_benches=("core_tb",),
        focus="ISA execution, flags, branching, functional coverage, Verilator cross-check, and pyuvm structure.",
    ),
    VerificationLane(
        key="mmio",
        title="MMIO Wrapper",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv"),
        native_script="run-mmio",
        native_tb="tb/simple_cpu_mmio_tb.sv",
        cocotb_script="run-cocotb-mmio",
        cocotb_test="tb/test_simple_cpu_mmio.py",
        pyuvm_script="run-mmio-uvm",
        pyuvm_test="tb/test_simple_cpu_mmio_pyuvm.py",
        assertions=("tb/simple_cpu_mmio_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_mmio.sby", "formal/simple_cpu_mmio_cover.sby"),
        artifacts=(
            "sim_build/mmio_coverage.json",
            "sim_build/mmio_coverage.csv",
            "sim_build/mmio_cocotb_results.xml",
            "sim_build/mmio_uvm_results.xml",
        ),
        mutation_benches=("mmio_tb",),
        focus="Register-map programming, control/status visibility, shadow image semantics, and wrapper assertions.",
    ),
    VerificationLane(
        key="mmio-wait",
        title="MMIO Wait-State Wrapper",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_mmio_wait.sv"),
        native_script="run-mmio-wait",
        native_tb="tb/simple_cpu_mmio_wait_tb.sv",
        cocotb_script="run-cocotb-mmio-wait",
        cocotb_test="tb/test_simple_cpu_mmio.py",
        pyuvm_script="run-mmio-wait-uvm",
        pyuvm_test="tb/test_simple_cpu_mmio_pyuvm.py",
        assertions=("tb/simple_cpu_mmio_wait_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=(
            "formal/simple_cpu_mmio_wait.sby",
            "formal/simple_cpu_mmio_wait_faults.sby",
            "formal/simple_cpu_mmio_wait_cover.sby",
        ),
        artifacts=(
            "sim_build/mmio_wait_coverage.json",
            "sim_build/mmio_wait_coverage.csv",
            "sim_build/mmio_wait_cocotb_results.xml",
            "sim_build/mmio_wait_uvm_results.xml",
        ),
        mutation_benches=("mmio_wait_tb",),
        focus="Delayed request capture, ready timing, stable pending transactions, and delayed wrapper replay.",
    ),
    VerificationLane(
        key="apb",
        title="APB Wrapper",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_apb.sv"),
        native_script="run-apb",
        native_tb="tb/simple_cpu_apb_tb.sv",
        cocotb_script="run-cocotb-apb",
        cocotb_test="tb/test_simple_cpu_apb.py",
        pyuvm_script="run-apb-uvm",
        pyuvm_test="tb/test_simple_cpu_apb_pyuvm.py",
        assertions=("tb/simple_cpu_apb_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_apb.sby", "formal/simple_cpu_apb_cover.sby"),
        artifacts=(
            "sim_build/apb_coverage.json",
            "sim_build/apb_coverage.csv",
            "sim_build/apb_cocotb_results.xml",
            "sim_build/apb_uvm_results.xml",
        ),
        mutation_benches=("apb_tb",),
        focus="APB setup/access sequencing, PREADY gating, readback, and shared MMIO control semantics.",
    ),
    VerificationLane(
        key="apb-fault",
        title="APB Fault Lane",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_apb.sv"),
        native_script="run-apb-fault",
        native_tb="tb/simple_cpu_apb_fault_tb.sv",
        cocotb_script=None,
        cocotb_test=None,
        pyuvm_script=None,
        pyuvm_test=None,
        assertions=("tb/simple_cpu_apb_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_apb_faults.sby",),
        artifacts=("sim_build/apb_fault_coverage.json", "sim_build/apb_fault_coverage.csv"),
        mutation_benches=("apb_fault_tb",),
        focus="Setup-only writes, PENABLE glitches, and run-time shadow updates that require explicit reload.",
    ),
    VerificationLane(
        key="wishbone",
        title="Wishbone Wrapper",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_wishbone.sv"),
        native_script="run-wishbone",
        native_tb="tb/simple_cpu_wishbone_tb.sv",
        cocotb_script="run-cocotb-wishbone",
        cocotb_test="tb/test_simple_cpu_wishbone.py",
        pyuvm_script="run-wishbone-uvm",
        pyuvm_test="tb/test_simple_cpu_wishbone_pyuvm.py",
        assertions=("tb/simple_cpu_wishbone_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_wishbone.sby", "formal/simple_cpu_wishbone_cover.sby"),
        artifacts=(
            "sim_build/wishbone_coverage.json",
            "sim_build/wishbone_coverage.csv",
            "sim_build/wishbone_cocotb_results.xml",
            "sim_build/wishbone_uvm_results.xml",
        ),
        mutation_benches=("wishbone_tb",),
        focus="Classic CYC/STB/ACK translation, read/write polarity, and MMIO-compatible control behavior.",
    ),
    VerificationLane(
        key="wishbone-fault",
        title="Wishbone Fault Lane",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_wishbone.sv"),
        native_script="run-wishbone-fault",
        native_tb="tb/simple_cpu_wishbone_fault_tb.sv",
        cocotb_script=None,
        cocotb_test=None,
        pyuvm_script=None,
        pyuvm_test=None,
        assertions=("tb/simple_cpu_wishbone_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_wishbone_faults.sby",),
        artifacts=("sim_build/wishbone_fault_coverage.json", "sim_build/wishbone_fault_coverage.csv"),
        mutation_benches=("wishbone_fault_tb",),
        focus="CYC-only writes, STB-without-CYC glitches, and reload-gated shadow updates.",
    ),
    VerificationLane(
        key="axi-lite",
        title="AXI-Lite Wrapper",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_axi_lite.sv"),
        native_script="run-axi-lite",
        native_tb="tb/simple_cpu_axi_lite_tb.sv",
        cocotb_script="run-cocotb-axi-lite",
        cocotb_test="tb/test_simple_cpu_axi_lite.py",
        pyuvm_script="run-axi-lite-uvm",
        pyuvm_test="tb/test_simple_cpu_axi_lite_pyuvm.py",
        assertions=("tb/simple_cpu_axi_lite_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_axi_lite.sby", "formal/simple_cpu_axi_lite_cover.sby"),
        artifacts=(
            "sim_build/axi_lite_coverage.json",
            "sim_build/axi_lite_coverage.csv",
            "sim_build/axi_lite_cocotb_results.xml",
            "sim_build/axi_lite_uvm_results.xml",
        ),
        mutation_benches=("axi_lite_tb",),
        focus="Coupled AW/W writes, response hold behavior, registered reads, partial-write rejection, and readback.",
    ),
    VerificationLane(
        key="axi-lite-fault",
        title="AXI-Lite Fault Lane",
        rtl=("rtl/simple_cpu.sv", "rtl/simple_cpu_mmio.sv", "rtl/simple_cpu_axi_lite.sv"),
        native_script="run-axi-lite-fault",
        native_tb="tb/simple_cpu_axi_lite_fault_tb.sv",
        cocotb_script=None,
        cocotb_test=None,
        pyuvm_script=None,
        pyuvm_test=None,
        assertions=("tb/simple_cpu_axi_lite_assertions.sv", "tb/simple_cpu_wrapper_common_assertions.svh"),
        formal_targets=("formal/simple_cpu_axi_lite_faults.sby",),
        artifacts=("sim_build/axi_lite_fault_coverage.json", "sim_build/axi_lite_fault_coverage.csv"),
        mutation_benches=("axi_lite_fault_tb",),
        focus="AW-only/W-only/split writes, B-response backpressure, and reload-gated shadow updates.",
    ),
)


def script_paths(stem: str) -> tuple[str, str, str, str]:
    return (
        f"scripts/{stem}.ps1",
        f"scripts/{stem}.sh",
        f"scripts/windows/{stem}.ps1",
        f"scripts/linux/{stem}.sh",
    )


def lane_paths(lane: VerificationLane) -> tuple[str, ...]:
    paths: list[str] = []
    paths.extend(lane.rtl)
    if lane.native_tb:
        paths.append(lane.native_tb)
    if lane.cocotb_test:
        paths.append(lane.cocotb_test)
    if lane.pyuvm_test:
        paths.append(lane.pyuvm_test)
    paths.extend(lane.assertions)
    paths.extend(lane.formal_targets)
    for script in (lane.native_script, lane.cocotb_script, lane.pyuvm_script):
        if script:
            paths.extend(script_paths(script))
    return tuple(paths)


def existing_formal_targets() -> set[str]:
    return {path.relative_to(PROJECT_ROOT).as_posix() for path in (PROJECT_ROOT / "formal").glob("*.sby")}


def validate_verification_matrix() -> list[str]:
    failures: list[str] = []
    keys = [lane.key for lane in LANES]
    if len(keys) != len(set(keys)):
        failures.append("verification matrix contains duplicate lane keys")

    benches_by_name = {bench.name: bench for bench in BENCHES}
    covered_benches: set[str] = set()
    covered_formal: set[str] = set()

    for lane in LANES:
        if not lane.key or not lane.title:
            failures.append("verification matrix lane has an empty key/title")
        if not lane.rtl:
            failures.append(f"{lane.key}: lane must reference at least one RTL file")
        if not lane.native_script or not lane.native_tb:
            failures.append(f"{lane.key}: lane must have a native simulation script and SV testbench")
        if not lane.mutation_benches:
            failures.append(f"{lane.key}: lane must name at least one mutation bench")

        for path in lane_paths(lane):
            if not (PROJECT_ROOT / path).exists():
                failures.append(f"{lane.key}: referenced path does not exist: {path}")

        for bench_name in lane.mutation_benches:
            bench = benches_by_name.get(bench_name)
            if bench is None:
                failures.append(f"{lane.key}: unknown mutation bench `{bench_name}`")
                continue
            covered_benches.add(bench_name)
            if lane.native_tb and lane.native_tb not in bench.sources:
                failures.append(f"{lane.key}: native testbench `{lane.native_tb}` is not compiled by `{bench_name}`")

        for target in lane.formal_targets:
            covered_formal.add(target)

    for bench in BENCHES:
        if bench.name not in covered_benches:
            failures.append(f"mutation bench `{bench.name}` is not represented in verification matrix")

    for target in sorted(existing_formal_targets()):
        if target not in covered_formal:
            failures.append(f"formal target `{target}` is not represented in verification matrix")

    full_stack = [lane for lane in LANES if not lane.key.endswith("-fault")]
    for lane in full_stack:
        if not lane.cocotb_script or not lane.cocotb_test:
            failures.append(f"{lane.key}: non-fault lane must include cocotb coverage")
        if not lane.pyuvm_script or not lane.pyuvm_test:
            failures.append(f"{lane.key}: non-fault lane must include pyuvm coverage")
        if len(lane.formal_targets) < 2:
            failures.append(f"{lane.key}: non-fault lane should include prove and cover formal targets")

    return failures


def _md_list(values: tuple[str, ...] | list[str], default: str = "-") -> str:
    return "<br>".join(f"`{value}`" for value in values) if values else default


def render_markdown() -> str:
    failures = validate_verification_matrix()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"verification matrix is invalid:\n{joined}")

    lines = [
        "<!-- Generated by scripts/verification_matrix.py. Do not edit by hand. -->",
        "",
        "# Verification Matrix",
        "",
        "This page is generated from `scripts/verification_matrix.py` and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Verification lanes: {len(LANES)}",
        f"- Mutation benches represented: {len({bench for lane in LANES for bench in lane.mutation_benches})}",
        f"- Formal targets represented: {len({target for lane in LANES for target in lane.formal_targets})}",
        "- Full-stack lanes include native SV, cocotb, pyuvm, formal, coverage artifacts, and mutation scope.",
        "",
        "## Lanes",
        "",
        "| Lane | RTL | Native SV | cocotb | pyuvm | Formal targets | Mutation benches | Focus |",
        "|---|---|---|---|---|---|---|---|",
    ]

    for lane in LANES:
        native = _md_list([lane.native_script or "", lane.native_tb or ""])
        cocotb = _md_list([value for value in (lane.cocotb_script, lane.cocotb_test) if value])
        pyuvm = _md_list([value for value in (lane.pyuvm_script, lane.pyuvm_test) if value])
        lines.append(
            "| `{key}` | {rtl} | {native} | {cocotb} | {pyuvm} | {formal} | {benches} | {focus} |".format(
                key=lane.key,
                rtl=_md_list(lane.rtl),
                native=native,
                cocotb=cocotb,
                pyuvm=pyuvm,
                formal=_md_list(lane.formal_targets),
                benches=_md_list(lane.mutation_benches),
                focus=lane.focus,
            )
        )

    lines.extend(
        [
            "",
            "## Assertion And Artifact Map",
            "",
            "| Lane | Assertion files | Result and coverage artifacts |",
            "|---|---|---|",
        ]
    )

    for lane in LANES:
        lines.append(f"| `{lane.key}` | {_md_list(lane.assertions)} | {_md_list(lane.artifacts)} |")

    lines.extend(
        [
            "",
            "Regenerate this page after intentional verification-lane edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-verification-matrix.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-verification-matrix.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the verification matrix.")
    parser.add_argument("--output", type=Path, default=Path("docs/verification-matrix.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Verification matrix is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Verification matrix is stale: {output_path}. "
                "Regenerate with scripts/generate-verification-matrix.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Verification matrix is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
