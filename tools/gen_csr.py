#!/usr/bin/env python3
"""Generate CSR artifacts from the authoritative schema.

Outputs:
  runtime/cpp/csr_defs.h      - C++ constants
  runtime/csr_defs.py         - Python accessors
  rtl/shell/csr_offsets.svh   - SV localparams
  docs/05-csr-map.md          - register documentation
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ABI_MAJOR = 1


def load_schema() -> dict:
    return json.loads((ROOT / "ip/schema/csr_map.json").read_text())


def gen_cpp(schema: dict) -> str:
    lines = [
        "// Generated from ip/schema/csr_map.json - do not edit by hand.",
        "#pragma once",
        "#include <cstdint>",
        "",
        "namespace mgr1 {",
        "",
        "constexpr uint32_t kRegId = 0x4D475231;  // 'MGR1'",
        "constexpr uint8_t kAbiMajor = %d;" % ABI_MAJOR,
        "",
        "enum class State : uint8_t {",
    ]
    for name, val in schema["states"].items():
        lines.append(f"  {name} = {val},")
    lines += ["};", "", "enum class Command : uint8_t {"]
    for name, val in schema["commands"].items():
        lines.append(f"  {name} = {val},")
    lines += ["};", "", "// Register offsets (byte-addressed, 32-bit aligned)."]
    for r in schema["registers"]:
        lines.append(f"constexpr uint32_t k{r['name']} = {r['offset']};")
    lines += [
        "",
        "static_assert(kID == 0x00, \"ID at 0x00\");",
        "static_assert(kCNT_DDR_WR == 0x78, \"last counter at 0x78\");",
        "",
        "}  // namespace mgr1",
        "",
    ]
    return "\n".join(lines)


def gen_py(schema: dict) -> str:
    lines = [
        '"""Generated from ip/schema/csr_map.json - do not edit by hand."""',
        "",
        "ABI_MAJOR = %d" % ABI_MAJOR,
        "",
        "class State:",
    ]
    for name, val in schema["states"].items():
        lines.append(f"    {name} = {val}")
    lines += ["", "class Command:"]
    for name, val in schema["commands"].items():
        lines.append(f"    {name} = {val}")
    lines += ["", "OFFSETS = {"]
    for r in schema["registers"]:
        lines.append(f"    {r['name']!r}: {r['offset']},")
    lines += ["}", ""]
    return "\n".join(lines)


def gen_svh(schema: dict) -> str:
    lines = [
        "// Generated from ip/schema/csr_map.json - do not edit by hand.",
        "`ifndef MGR1_CSR_OFFSETS_SVH",
        "`define MGR1_CSR_OFFSETS_SVH",
        "",
        "package mgr1_csr;",
        "",
    ]

    def fmt(off: str) -> str:
        v = int(off, 16)
        return f"32'h{v >> 16:04X}_{v & 0xFFFF:04X}"

    width = max(len(r["name"]) for r in schema["registers"])
    for r in schema["registers"]:
        lines.append(
            f"  localparam logic [31:0] OFF_{r['name'].ljust(width)}"
            f" = {fmt(r['offset'])};"
        )
    lines += [
        "",
        "  // States",
    ]
    for name, val in schema["states"].items():
        lines.append(f"  localparam logic [2:0] ST_{name} = 3'd{val};")
    lines += ["", "  // Commands"]
    for name, val in schema["commands"].items():
        lines.append(f"  localparam logic [2:0] CMD_{name} = 3'd{val};")
    lines += [
        "",
        "endpackage",
        "",
        "`endif",
        "",
    ]
    return "\n".join(lines)


def gen_md(schema: dict) -> str:
    lines = [
        "# External shell CSR map",
        "",
        "Generated from `ip/schema/csr_map.json`. Byte-addressed, 32-bit aligned.",
        "",
        "| Offset(s) | Access | Field | Behavior software must verify |",
        "| :---- | :---- | :---- | :---- |",
    ]
    for r in schema["registers"]:
        lines.append(
            f"| {r['offset']} | {r['access']} | {r['name']} | {r['desc']} |"
        )
    lines += [
        "",
        "## Commands",
        "",
    ]
    for name, val in schema["commands"].items():
        lines.append(f"- `{name}` = {val}")
    lines += ["", "## Rules", ""]
    for rule in schema["rules"]:
        lines.append(f"- {rule}")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    schema = load_schema()
    (ROOT / "runtime/cpp/csr_defs.h").write_text(gen_cpp(schema))
    (ROOT / "runtime/csr_defs.py").write_text(gen_py(schema))
    (ROOT / "rtl/shell/csr_offsets.svh").write_text(gen_svh(schema))
    (ROOT / "docs/05-csr-map.md").write_text(gen_md(schema))
    print("generated: csr_defs.h, csr_defs.py, csr_offsets.svh, 05-csr-map.md")


if __name__ == "__main__":
    sys.exit(main())
