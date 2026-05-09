from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.artifact_catalog import artifact_entries
from scripts.run_mutation_campaign import BENCHES
from scripts.verification_matrix import LANES


@dataclass(frozen=True)
class Requirement:
    req_id: str
    title: str
    claim: str
    lanes: tuple[str, ...]
    formal_targets: tuple[str, ...]
    mutation_benches: tuple[str, ...]
    artifacts: tuple[str, ...]
    notes: str


REQUIREMENTS = (
    Requirement(
        req_id="REQ-CORE-ISA",
        title="Core ISA Execution",
        claim="The direct CPU implements the documented 4-bit opcode ISA and halts safely.",
        lanes=("core",),
        formal_targets=("formal/simple_cpu.sby", "formal/simple_cpu_cover.sby"),
        mutation_benches=("core_tb",),
        artifacts=("sim_build/coverage.json", "sim_build/verilator_results.xml", "sim_build/uvm_results.xml"),
        notes="Covers directed, randomized, cocotb/Verilator, and pyuvm direct-core execution.",
    ),
    Requirement(
        req_id="REQ-CORE-FLAGS",
        title="ALU Flags And Branches",
        claim="Arithmetic, shift, compare, jump, and zero-branch behavior update architectural state and flags correctly.",
        lanes=("core",),
        formal_targets=("formal/simple_cpu.sby",),
        mutation_benches=("core_tb",),
        artifacts=("sim_build/coverage.json", "sim_build/verilator_coverage/summary.json"),
        notes="Mutation scopes include branch inversion, add/sub swap, CMP clobber, and shift-carry faults.",
    ),
    Requirement(
        req_id="REQ-MMIO",
        title="MMIO Register Shell",
        claim="The MMIO shell provides deterministic program loading, control, status, and shadow readback behavior.",
        lanes=("mmio",),
        formal_targets=("formal/simple_cpu_mmio.sby", "formal/simple_cpu_mmio_cover.sby"),
        mutation_benches=("mmio_tb",),
        artifacts=("sim_build/mmio_coverage.json", "sim_build/mmio_cocotb_results.xml", "sim_build/mmio_uvm_results.xml"),
        notes="Shared wrapper assertions check hold/load/run and register readback invariants.",
    ),
    Requirement(
        req_id="REQ-MMIO-WAIT",
        title="Delayed MMIO Handshake",
        claim="The wait-state wrapper captures requests, delays readiness, and services the originally latched transaction.",
        lanes=("mmio-wait",),
        formal_targets=(
            "formal/simple_cpu_mmio_wait.sby",
            "formal/simple_cpu_mmio_wait_faults.sby",
            "formal/simple_cpu_mmio_wait_cover.sby",
        ),
        mutation_benches=("mmio_wait_tb",),
        artifacts=(
            "sim_build/mmio_wait_coverage.json",
            "sim_build/mmio_wait_cocotb_results.xml",
            "sim_build/mmio_wait_uvm_results.xml",
        ),
        notes="Fault lane covers early ready, zero delay, dropped write data, and broken readback.",
    ),
    Requirement(
        req_id="REQ-APB",
        title="APB Wrapper",
        claim="The APB wrapper translates setup/access transfers into the shared MMIO register model.",
        lanes=("apb",),
        formal_targets=("formal/simple_cpu_apb.sby", "formal/simple_cpu_apb_cover.sby"),
        mutation_benches=("apb_tb",),
        artifacts=("sim_build/apb_coverage.json", "sim_build/apb_cocotb_results.xml", "sim_build/apb_uvm_results.xml"),
        notes="Native, cocotb, pyuvm, and formal checks cover setup/access sequencing and PREADY gating.",
    ),
    Requirement(
        req_id="REQ-APB-FAULTS",
        title="APB Fault Rejection",
        claim="Malformed APB setup-only and PENABLE-without-PSEL traffic does not create hidden side effects.",
        lanes=("apb-fault",),
        formal_targets=("formal/simple_cpu_apb_faults.sby",),
        mutation_benches=("apb_fault_tb",),
        artifacts=("sim_build/apb_fault_coverage.json",),
        notes="Also proves run-time shadow writes affect execution only after an explicit reload.",
    ),
    Requirement(
        req_id="REQ-WISHBONE",
        title="Wishbone Wrapper",
        claim="The Wishbone wrapper translates valid CYC/STB traffic into the shared MMIO register model.",
        lanes=("wishbone",),
        formal_targets=("formal/simple_cpu_wishbone.sby", "formal/simple_cpu_wishbone_cover.sby"),
        mutation_benches=("wishbone_tb",),
        artifacts=(
            "sim_build/wishbone_coverage.json",
            "sim_build/wishbone_cocotb_results.xml",
            "sim_build/wishbone_uvm_results.xml",
        ),
        notes="Covers ACK timing, DAT_O readback, write polarity, and wrapper control/status replay.",
    ),
    Requirement(
        req_id="REQ-WISHBONE-FAULTS",
        title="Wishbone Fault Rejection",
        claim="CYC-only and STB-without-CYC traffic is ignored and cannot corrupt state.",
        lanes=("wishbone-fault",),
        formal_targets=("formal/simple_cpu_wishbone_faults.sby",),
        mutation_benches=("wishbone_fault_tb",),
        artifacts=("sim_build/wishbone_fault_coverage.json",),
        notes="Fault checks also cover reload-gated shadow updates.",
    ),
    Requirement(
        req_id="REQ-AXI-LITE",
        title="AXI-Lite Wrapper",
        claim="The AXI-Lite wrapper accepts coupled AW/W writes, holds responses, and returns registered read data.",
        lanes=("axi-lite",),
        formal_targets=("formal/simple_cpu_axi_lite.sby", "formal/simple_cpu_axi_lite_cover.sby"),
        mutation_benches=("axi_lite_tb",),
        artifacts=(
            "sim_build/axi_lite_coverage.json",
            "sim_build/axi_lite_cocotb_results.xml",
            "sim_build/axi_lite_uvm_results.xml",
        ),
        notes="Native, cocotb, pyuvm, and formal lanes cover the tutorial's intentionally small AXI-Lite subset.",
    ),
    Requirement(
        req_id="REQ-AXI-LITE-FAULTS",
        title="AXI-Lite Fault Rejection",
        claim="Partial write channels, split writes, and pending B responses do not create illegal state updates.",
        lanes=("axi-lite-fault",),
        formal_targets=("formal/simple_cpu_axi_lite_faults.sby",),
        mutation_benches=("axi_lite_fault_tb",),
        artifacts=("sim_build/axi_lite_fault_coverage.json",),
        notes="Fault checks also cover reload-gated shadow updates.",
    ),
    Requirement(
        req_id="REQ-CROSS-SIM",
        title="Cross-Simulator Replay",
        claim="The same reference-model semantics are replayed through native SV, cocotb, and pyuvm lanes.",
        lanes=("core", "mmio", "mmio-wait", "apb", "wishbone", "axi-lite"),
        formal_targets=(),
        mutation_benches=(),
        artifacts=(
            "sim_build/verilator_results.xml",
            "sim_build/uvm_results.xml",
            "sim_build/apb_cocotb_results.xml",
            "sim_build/wishbone_cocotb_results.xml",
            "sim_build/axi_lite_cocotb_results.xml",
        ),
        notes="This is a portability and scoreboard-consistency requirement rather than a single protocol proof.",
    ),
    Requirement(
        req_id="REQ-MUTATION",
        title="Mutation Detection",
        claim="Representative RTL and wrapper faults are killed by the scoped regression campaign.",
        lanes=tuple(lane.key for lane in LANES),
        formal_targets=(),
        mutation_benches=tuple(bench.name for bench in BENCHES),
        artifacts=("sim_build/mutations",),
        notes="Mutation definitions are generated and validated separately in `docs/mutation-catalog.md`.",
    ),
    Requirement(
        req_id="REQ-CI-ARTIFACTS",
        title="CI Artifact Reviewability",
        claim="Generated verification outputs are uploaded or tracked so failures can be inspected after CI.",
        lanes=tuple(lane.key for lane in LANES),
        formal_targets=tuple(target for lane in LANES for target in lane.formal_targets),
        mutation_benches=(),
        artifacts=tuple(entry.path for entry in artifact_entries() if entry.path.startswith(("sim_build/", "formal/"))),
        notes="Artifact upload coverage is generated and checked in `docs/artifact-catalog.md`.",
    ),
)


def validate_requirements() -> list[str]:
    failures: list[str] = []
    lane_by_key = {lane.key: lane for lane in LANES}
    benches = {bench.name for bench in BENCHES}
    artifact_paths = {entry.path for entry in artifact_entries()}
    requirement_ids = [requirement.req_id for requirement in REQUIREMENTS]

    if len(requirement_ids) != len(set(requirement_ids)):
        failures.append("requirements traceability contains duplicate requirement IDs")

    covered_lanes: set[str] = set()
    for requirement in REQUIREMENTS:
        if not requirement.req_id.startswith("REQ-"):
            failures.append(f"{requirement.req_id}: requirement ID must start with REQ-")
        if not requirement.title or not requirement.claim:
            failures.append(f"{requirement.req_id}: title and claim are required")
        if not requirement.lanes:
            failures.append(f"{requirement.req_id}: at least one verification lane is required")

        for lane_key in requirement.lanes:
            lane = lane_by_key.get(lane_key)
            if lane is None:
                failures.append(f"{requirement.req_id}: unknown lane `{lane_key}`")
                continue
            covered_lanes.add(lane_key)

        for formal_target in requirement.formal_targets:
            if not any(formal_target in lane.formal_targets for lane in LANES):
                failures.append(f"{requirement.req_id}: formal target `{formal_target}` is not in the verification matrix")
            if not (PROJECT_ROOT / formal_target).exists():
                failures.append(f"{requirement.req_id}: formal target `{formal_target}` does not exist")

        for bench in requirement.mutation_benches:
            if bench not in benches:
                failures.append(f"{requirement.req_id}: unknown mutation bench `{bench}`")

        for artifact in requirement.artifacts:
            if artifact not in artifact_paths:
                failures.append(f"{requirement.req_id}: artifact `{artifact}` is not in the artifact catalog")

    for lane_key in lane_by_key:
        if lane_key not in covered_lanes:
            failures.append(f"verification lane `{lane_key}` is not covered by any requirement")

    return failures


def _md_list(values: tuple[str, ...], default: str = "-") -> str:
    return "<br>".join(f"`{value}`" for value in values) if values else default


def render_markdown() -> str:
    failures = validate_requirements()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"requirements traceability is invalid:\n{joined}")

    lines = [
        "<!-- Generated by scripts/requirements_traceability.py. Do not edit by hand. -->",
        "",
        "# Requirements Traceability",
        "",
        "This page maps tutorial verification claims to executable lanes, formal targets, mutation benches, and review artifacts.",
        "",
        "## Summary",
        "",
        f"- Requirements: {len(REQUIREMENTS)}",
        f"- Verification lanes covered: {len({lane for requirement in REQUIREMENTS for lane in requirement.lanes})}",
        f"- Mutation benches covered: {len({bench for requirement in REQUIREMENTS for bench in requirement.mutation_benches})}",
        f"- Referenced artifacts: {len({artifact for requirement in REQUIREMENTS for artifact in requirement.artifacts})}",
        "",
        "## Matrix",
        "",
        "| Requirement | Claim | Lanes | Formal targets | Mutation benches | Artifacts | Notes |",
        "|---|---|---|---|---|---|---|",
    ]

    for requirement in REQUIREMENTS:
        lines.append(
            "| `{req_id}` {title} | {claim} | {lanes} | {formal} | {benches} | {artifacts} | {notes} |".format(
                req_id=requirement.req_id,
                title=requirement.title,
                claim=requirement.claim,
                lanes=_md_list(requirement.lanes),
                formal=_md_list(requirement.formal_targets),
                benches=_md_list(requirement.mutation_benches),
                artifacts=_md_list(requirement.artifacts),
                notes=requirement.notes,
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional requirement or lane edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-requirements-traceability.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-requirements-traceability.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check requirements traceability documentation.")
    parser.add_argument("--output", type=Path, default=Path("docs/requirements-traceability.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Requirements traceability doc is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Requirements traceability doc is stale: {output_path}. "
                "Regenerate with scripts/generate-requirements-traceability.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Requirements traceability doc is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
