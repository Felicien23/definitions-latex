#!/usr/bin/env python3
"""Rendering regression test for definitions-latex.

Typesets every macro listed in tests/rendering/cases.tex and records TeX's
exact box contents (fonts, kerns, glue, colour specials).  Two dumps can be
compared case by case, which shows whether an edit to the sources changed
the typeset output at all.

  boxdump.py dump    --source DIR [--mode package|modules] --out FILE
  boxdump.py compare EXPECTED ACTUAL
  boxdump.py check   --source DIR --expected FILE [--mode package]

The exact dump depends on the TeX Live release (font metrics, amsmath,
siunitx internals), so the committed reference file is only meaningful for
the TeX Live release named in its header.  `check` skips (exit 0) when the
installed TeX Live year differs from the reference.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
RENDER_DIR = HERE.parent / "tests" / "rendering"
CASE_RE = re.compile(r"^BEGIN-CASE (\S+)$")


def tex_live_year(text: str) -> str | None:
    m = re.search(r"TeX Live (\d{4})", text)
    return m.group(1) if m else None


def tex_version() -> str:
    out = subprocess.run(["pdflatex", "--version"], capture_output=True, text=True)
    return out.stdout.splitlines()[0].strip() if out.stdout else "unknown"


def run_harness(source: Path, mode: str) -> str:
    """Compile the harness against SOURCE and return the log text."""
    with tempfile.TemporaryDirectory(prefix="boxdump-") as tmp:
        tmpdir = Path(tmp)
        for name in ("harness.tex", "cases.tex"):
            shutil.copy(RENDER_DIR / name, tmpdir / name)
        src = str(source.resolve()).rstrip("/") + "/"
        env = dict(os.environ, max_print_line="100000")
        cmd = [
            "pdflatex", "-interaction=nonstopmode",
            rf"\def\SourceDir{{{src}}}\def\LoadMode{{{mode}}}\input{{harness}}",
        ]
        subprocess.run(cmd, cwd=tmpdir, env=env, capture_output=True, text=True)
        log = tmpdir / "harness.log"
        if not log.exists():
            sys.exit("boxdump: pdflatex produced no log; is TeX installed?")
        return log.read_text(encoding="latin-1")


def parse_cases(log: str) -> dict[str, list[str]]:
    """Extract normalised per-case records from a harness log."""
    cases: dict[str, list[str]] = {}
    current: str | None = None
    body: list[str] = []
    for line in log.splitlines():
        m = CASE_RE.match(line)
        if m:
            current, body = m.group(1), []
            continue
        if current is None:
            continue
        if line == f"END-CASE {current}":
            cases[current] = body
            current = None
            continue
        if line.startswith("> \\box"):
            continue  # register number is irrelevant
        if line.startswith("! ") and line != "! OK.":
            body.append("ERROR " + line[2:])
        elif line.startswith(("\\", ".", "secnumdepth=")):
            body.append(line)
    if "secnumdepth" not in cases:
        sys.exit("boxdump: harness did not finish; see a manual run for errors")
    return cases


def dump(source: Path, mode: str) -> str:
    cases = parse_cases(run_harness(source, mode))
    lines = [f"# definitions-latex rendering dump ({mode} mode)", f"# {tex_version()}"]
    for name, body in cases.items():
        lines.append(f"=== {name}")
        lines.extend(body)
    return "\n".join(lines) + "\n"


def load(path: Path) -> dict[str, list[str]]:
    cases: dict[str, list[str]] = {}
    current = None
    for line in path.read_text().splitlines():
        if line.startswith("#"):
            continue
        if line.startswith("=== "):
            current = line[4:]
            cases[current] = []
        elif current is not None:
            cases[current].append(line)
    return cases


def compare(a: dict[str, list[str]], b: dict[str, list[str]]) -> list[str]:
    report = []
    for name in sorted(set(a) | set(b), key=lambda n: (n not in a, n)):
        if name not in a:
            report.append(f"NEW      {name}")
        elif name not in b:
            report.append(f"MISSING  {name}")
        elif a[name] != b[name]:
            err = any(x.startswith("ERROR") for x in b[name])
            report.append(f"{'ERROR   ' if err else 'CHANGED '} {name}")
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("dump")
    d.add_argument("--source", type=Path, default=HERE.parent)
    d.add_argument("--mode", choices=("package", "modules"), default="package")
    d.add_argument("--out", type=Path, required=True)
    c = sub.add_parser("compare")
    c.add_argument("expected", type=Path)
    c.add_argument("actual", type=Path)
    k = sub.add_parser("check")
    k.add_argument("--source", type=Path, default=HERE.parent)
    k.add_argument("--mode", choices=("package", "modules"), default="package")
    k.add_argument("--expected", type=Path, required=True)
    args = ap.parse_args()

    if args.cmd == "dump":
        args.out.write_text(dump(args.source, args.mode))
        return 0
    if args.cmd == "compare":
        report = compare(load(args.expected), load(args.actual))
    else:
        ref_year = tex_live_year(args.expected.read_text().split("\n", 2)[1])
        here_year = tex_live_year(tex_version())
        if ref_year != here_year:
            print(f"boxdump: SKIPPED: reference is for TeX Live {ref_year}, "
                  f"this is TeX Live {here_year}")
            return 0
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as fh:
            fh.write(dump(args.source, args.mode))
            actual = Path(fh.name)
        report = compare(load(args.expected), load(actual))
        if report:
            print(f"boxdump: full actual dump kept at {actual}")
        else:
            actual.unlink()
    for line in report:
        print(line)
    if report:
        print(f"boxdump: {len(report)} case(s) differ")
        return 1
    print("boxdump: all cases identical")
    return 0


if __name__ == "__main__":
    sys.exit(main())
