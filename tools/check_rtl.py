#!/usr/bin/env python3
"""Syntax/elaboration check of all SystemVerilog sources using pyslang.

This is not a simulator: it proves the sources parse and elaborate (module
instantiations resolve, parameters are legal, packages load).  Simulation
and co-simulation remain Vivado/Verilator-gated (see EXECUTION_STATUS.md).

Usage: python3 tools/check_rtl.py [file|dir ...]
Default: rtl/ recursively, .sv files.
"""

import sys
from pathlib import Path

import pyslang

ROOT = Path(__file__).resolve().parent.parent

DEFAULT_DIRS = [ROOT / "rtl"]


def collect(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for p in paths:
        if p.is_dir():
            files.extend(sorted(p.rglob("*.sv")))
        elif p.suffix == ".sv":
            files.append(p)
    return files


def main() -> int:
    args_list = sys.argv[1:]
    paths = [Path(a) for a in args_list] or DEFAULT_DIRS
    files = collect(paths)
    if not files:
        print("no SystemVerilog files found")
        return 1

    driver = pyslang.driver.Driver()
    driver.addStandardArgs()
    cmd = f"-q -I{ROOT / 'rtl'} --single-unit " + " ".join(str(f) for f in files)
    if not driver.parseCommandLine(cmd):
        print("command line parse failed")
        return 1
    driver.processOptions()
    if not driver.parseAllSources():
        print("FAIL: parse errors")
        driver.reportParseDiags()
        return 1
    compilation = driver.createCompilation()
    driver.reportCompilation(compilation, False)
    diags = compilation.getAllDiagnostics()
    errors = [d for d in diags if d.isError()]
    if errors:
        print(f"FAIL: {len(errors)} elaboration error(s)")
        return 1
    print(f"OK: {len(files)} file(s) parse and elaborate cleanly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
