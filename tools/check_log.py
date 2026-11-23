#!/usr/bin/env python3
"""Fail if a LaTeX log contains errors, warnings or bad boxes.

  check_log.py FILE.log [FILE.log ...]

Run pdflatex with the environment variable max_print_line=10000 so that
messages are not wrapped across lines.
"""
import re
import sys
from pathlib import Path

PATTERNS = [
    (re.compile(r"^! "), "error"),
    (re.compile(r"LaTeX( Font)? Warning:"), "LaTeX warning"),
    (re.compile(r"(Package|Class) \S+ Warning:"), "package/class warning"),
    (re.compile(r"^(Overfull|Underfull) \\[hv]box"), "bad box"),
    (re.compile(r"Missing character:"), "missing glyph"),
]


def check(path: Path) -> list[str]:
    problems = []
    for number, line in enumerate(path.read_text(encoding="latin-1").splitlines(), 1):
        for pattern, kind in PATTERNS:
            if pattern.search(line):
                problems.append(f"{path}:{number}: {kind}: {line.strip()}")
    return problems


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    problems = [p for arg in sys.argv[1:] for p in check(Path(arg))]
    for problem in problems:
        print(problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
