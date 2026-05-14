from __future__ import annotations

import argparse
import ast
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class AdapterSpec:
    name: str
    protocol_views: tuple[str, ...]
    path: str
    class_name: str
    wrapper_adapter: bool
    notes: str


@dataclass(frozen=True)
class MethodRequirement:
    name: str
    expected_kind: str
    scope: str
    notes: str


ADAPTERS: tuple[AdapterSpec, ...] = (
    AdapterSpec(
        name="direct-core",
        protocol_views=("Direct RTL programming port",),
        path="tb/core_bus.py",
        class_name="SimpleCpuCoreBus",
        wrapper_adapter=False,
        notes="Direct core adapter uses the CPU programming pins and has no readable shadow program.",
    ),
    AdapterSpec(
        name="mmio",
        protocol_views=("MMIO", "MMIO wait"),
        path="tb/mmio_bus.py",
        class_name="SimpleCpuMmioBus",
        wrapper_adapter=True,
        notes="Shared register-map helper used by the always-ready and wait-state MMIO shells.",
    ),
    AdapterSpec(
        name="apb",
        protocol_views=("APB",),
        path="tb/apb_bus.py",
        class_name="SimpleCpuApbBus",
        wrapper_adapter=True,
        notes="APB setup/access helper over the shared wrapper address map.",
    ),
    AdapterSpec(
        name="wishbone",
        protocol_views=("Wishbone",),
        path="tb/wishbone_bus.py",
        class_name="SimpleCpuWishboneBus",
        wrapper_adapter=True,
        notes="Wishbone CYC/STB/ACK helper over the shared wrapper address map.",
    ),
    AdapterSpec(
        name="axi-lite",
        protocol_views=("AXI-Lite",),
        path="tb/axi_lite_bus.py",
        class_name="SimpleCpuAxiLiteBus",
        wrapper_adapter=True,
        notes="Tutorial AXI-Lite subset helper with coupled AW/W acceptance and one outstanding response.",
    ),
)

COMMON_REQUIREMENTS: tuple[MethodRequirement, ...] = (
    MethodRequirement("reset", "async", "shared conformance", "Put the DUT in a known idle state."),
    MethodRequirement("load_program", "async", "shared conformance", "Load up to 16 instruction bytes."),
    MethodRequirement("begin_execution", "async", "shared conformance", "Release or start execution after programming."),
    MethodRequirement("run_until_halt", "async", "shared conformance", "Wait for HALT with a cycle budget."),
    MethodRequirement("sample_state", "async", "shared conformance", "Return an MmioSnapshot-compatible final state."),
    MethodRequirement("read_dmem", "async", "shared state sampling", "Read one data-memory byte for snapshot construction."),
)

WRAPPER_REQUIREMENTS: tuple[MethodRequirement, ...] = (
    MethodRequirement("read", "async", "register wrappers", "Read one wrapper register."),
    MethodRequirement("write", "async", "register wrappers", "Write one wrapper register."),
    MethodRequirement("load_shadow_program", "async", "register wrappers", "Write shadow instruction memory without starting."),
    MethodRequirement("verify_loaded_program", "async", "register wrappers", "Read back shadow instruction memory."),
    MethodRequirement("wait_for_control_state", "async", "register wrappers", "Poll the control register state bits."),
    MethodRequirement("start_program", "async", "register wrappers", "Set RUN through the control register."),
    MethodRequirement("stop_program", "async", "register wrappers", "Clear RUN through the control register."),
)

DIRECT_CORE_REQUIREMENTS: tuple[MethodRequirement, ...] = (
    MethodRequirement("program_word", "async", "direct-core helpers", "Pulse one programming write."),
    MethodRequirement("start_program_word", "sync", "direct-core helpers", "Hold one programming write active for fault tests."),
    MethodRequirement("stop_program_word", "async", "direct-core helpers", "Release a held programming write."),
)

AXI_LITE_REQUIREMENTS: tuple[MethodRequirement, ...] = (
    MethodRequirement("attempt_partial_write", "async", "axi-lite helpers", "Exercise the rejected partial-write channel cases."),
    MethodRequirement("wait_write_accept", "async", "axi-lite helpers", "Wait for coupled AW/W acceptance."),
    MethodRequirement("wait_write_response", "async", "axi-lite helpers", "Wait for the B channel OKAY response."),
    MethodRequirement("wait_read_accept", "async", "axi-lite helpers", "Wait for AR acceptance."),
    MethodRequirement("wait_read_response", "async", "axi-lite helpers", "Wait for the R channel OKAY response."),
)


def _adapter_path(spec: AdapterSpec) -> Path:
    return PROJECT_ROOT / spec.path


def _class_methods(spec: AdapterSpec) -> dict[str, str]:
    source_path = _adapter_path(spec)
    tree = ast.parse(source_path.read_text(encoding="utf-8"), filename=spec.path)
    for node in tree.body:
        if isinstance(node, ast.ClassDef) and node.name == spec.class_name:
            methods: dict[str, str] = {}
            for item in node.body:
                if isinstance(item, ast.AsyncFunctionDef):
                    methods[item.name] = "async"
                elif isinstance(item, ast.FunctionDef):
                    methods[item.name] = "sync"
            return methods
    return {}


def adapter_methods() -> dict[str, dict[str, str]]:
    return {spec.name: _class_methods(spec) for spec in ADAPTERS}


def _required_methods_for_adapter(spec: AdapterSpec) -> tuple[MethodRequirement, ...]:
    requirements = list(COMMON_REQUIREMENTS)
    if spec.wrapper_adapter:
        requirements.extend(WRAPPER_REQUIREMENTS)
    if spec.name == "direct-core":
        requirements.extend(DIRECT_CORE_REQUIREMENTS)
    if spec.name == "axi-lite":
        requirements.extend(AXI_LITE_REQUIREMENTS)
    return tuple(requirements)


def _validate_method_kind(
    *,
    spec: AdapterSpec,
    method: MethodRequirement,
    methods: dict[str, str],
    failures: list[str],
) -> None:
    observed = methods.get(method.name)
    if observed is None:
        failures.append(f"{spec.name}: `{spec.class_name}` is missing `{method.name}`")
        return
    if method.expected_kind != "any" and observed != method.expected_kind:
        failures.append(
            f"{spec.name}: `{method.name}` must be {method.expected_kind}, observed {observed}"
        )


def validate_adapter_contract() -> list[str]:
    failures: list[str] = []

    names = [spec.name for spec in ADAPTERS]
    if len(names) != len(set(names)):
        failures.append("adapter contract contains duplicate adapter names")

    for spec in ADAPTERS:
        source_path = _adapter_path(spec)
        if not source_path.exists():
            failures.append(f"{spec.name}: source path does not exist: {spec.path}")
            continue

        methods = _class_methods(spec)
        if not methods:
            failures.append(f"{spec.name}: class `{spec.class_name}` not found in {spec.path}")
            continue

        for method in _required_methods_for_adapter(spec):
            _validate_method_kind(spec=spec, method=method, methods=methods, failures=failures)

    conformance_text = (PROJECT_ROOT / "tb" / "protocol_conformance.py").read_text(encoding="utf-8")
    for method in ("reset", "load_program", "load_shadow_program", "verify_loaded_program", "begin_execution"):
        if method not in conformance_text:
            failures.append(f"tb/protocol_conformance.py must reference `{method}`")

    readme_text = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
    plan_text = (PROJECT_ROOT / "docs" / "verification-plan.md").read_text(encoding="utf-8")
    if "docs/adapter-contract.md" not in readme_text:
        failures.append("README.md must link to docs/adapter-contract.md")
    if "docs/adapter-contract.md" not in plan_text:
        failures.append("docs/verification-plan.md must link to docs/adapter-contract.md")

    return failures


def _all_requirements() -> tuple[MethodRequirement, ...]:
    seen: set[str] = set()
    ordered: list[MethodRequirement] = []
    for group in (
        COMMON_REQUIREMENTS,
        WRAPPER_REQUIREMENTS,
        DIRECT_CORE_REQUIREMENTS,
        AXI_LITE_REQUIREMENTS,
    ):
        for method in group:
            if method.name in seen:
                continue
            seen.add(method.name)
            ordered.append(method)
    return tuple(ordered)


def _method_cell(methods: dict[str, str], method: MethodRequirement) -> str:
    observed = methods.get(method.name)
    if observed is None:
        return "-"
    return f"`{observed}`"


def render_markdown() -> str:
    failures = validate_adapter_contract()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"adapter contract is invalid:\n{joined}")

    methods_by_adapter = adapter_methods()
    lines = [
        "<!-- Generated by scripts/adapter_contract.py. Do not edit by hand. -->",
        "",
        "# Adapter Contract",
        "",
        "This page is generated from the Python bus-functional adapter sources and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Adapter classes: {len(ADAPTERS)}",
        f"- Shared conformance methods: {len(COMMON_REQUIREMENTS)}",
        f"- Register-wrapper helper methods: {len(WRAPPER_REQUIREMENTS)}",
        f"- AXI-Lite-specific helper methods: {len(AXI_LITE_REQUIREMENTS)}",
        "- The direct-core adapter is allowed to omit shadow-program readback because the core programming port is write-only.",
        "",
        "## Adapter Sources",
        "",
        "| Adapter | Protocol views | Class | Source | Notes |",
        "|---|---|---|---|---|",
    ]

    for spec in ADAPTERS:
        lines.append(
            "| `{name}` | {protocol_views} | `{class_name}` | `{path}` | {notes} |".format(
                name=spec.name,
                protocol_views="<br>".join(f"`{view}`" for view in spec.protocol_views),
                class_name=spec.class_name,
                path=spec.path,
                notes=spec.notes,
            )
        )

    header = "| Method | Expected kind | Scope | Notes | " + " | ".join(
        f"`{spec.name}`" for spec in ADAPTERS
    ) + " |"
    separator = "|---|---|---|---|" + "|".join("---" for _ in ADAPTERS) + "|"
    lines.extend(["", "## Method Matrix", "", header, separator])

    for method in _all_requirements():
        cells = [
            f"`{method.name}`",
            f"`{method.expected_kind}`",
            method.scope,
            method.notes,
        ]
        cells.extend(_method_cell(methods_by_adapter[spec.name], method) for spec in ADAPTERS)
        lines.append("| " + " | ".join(cells) + " |")

    lines.extend(
        [
            "",
            "## Contract Rules",
            "",
            "1. Every adapter must expose the shared conformance methods so `tb/protocol_conformance.py` can run unchanged across direct core, MMIO, APB, Wishbone, and AXI-Lite tests.",
            "2. Register-wrapper adapters must expose `read`, `write`, shadow load/readback, and control-state helpers because directed cocotb and pyuvm tests use those methods outside the shared scenario replay.",
            "3. AXI-Lite keeps explicit wait helpers and partial-write probing because the tutorial wrapper intentionally implements a restricted AXI-Lite subset.",
            "4. This catalog parses adapter source files statically, so it does not need cocotb installed to catch missing or synchronous methods in the Python-model lane.",
            "",
            "Regenerate this page after intentional adapter API edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-adapter-contract.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-adapter-contract.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the Python bus-adapter contract catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/adapter-contract.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Adapter contract catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Adapter contract catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-adapter-contract.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Adapter contract catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
