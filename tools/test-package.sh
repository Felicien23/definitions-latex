#!/bin/sh
# Test a release archive in isolation, the way a user would install it:
#   1. the archive contains exactly the expected files;
#   2. no other copy of the package is installed that could mask a problem;
#   3. README quick start: unzip into a personal TEXMF tree, compile the
#      bundled examples/minimal.tex from an empty directory;
#   4. per-project copy in a subfolder, found through .latexmkrc;
#   5. flat copy next to the document (as on Overleaf).
# Nothing from the working tree is used, so a file missing from the archive
# makes this fail.
#
#   tools/test-package.sh dist/definitions-latex-<version>.zip
set -eu
[ $# -eq 1 ] || { echo "usage: $0 ARCHIVE.zip" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
zip=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
name=$(basename "$zip" .zip)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export max_print_line=10000
unset TEXINPUTS 2>/dev/null || true

fail() { echo "test-package: FAIL: $*" >&2; exit 1; }
compile() { # dir file [latexmk]
    if [ "${3:-}" = latexmk ]; then
        (cd "$1" && latexmk -pdf -interaction=nonstopmode -halt-on-error "$2" >/dev/null 2>&1) \
            || fail "latexmk $2 in $1 (see $1/${2%.tex}.log)"
    else
        (cd "$1" && pdflatex -interaction=nonstopmode -halt-on-error "$2" >/dev/null 2>&1) \
            || fail "pdflatex $2 in $1"
    fi
    python3 "$here/check_log.py" "$1/${2%.tex}.log" || fail "warnings in $1/${2%.tex}.log"
}

# 1. Contents
expected=$(printf '%s\n' CHANGELOG.md Commandes.tex LICENSE LanguageStyle.tex \
    Operator.tex README.md Units.tex definitions-doc.pdf definitions.sty \
    examples/minimal.tex | sed "s|^|$name/|" | LC_ALL=C sort)
actual=$(unzip -Z1 "$zip" | LC_ALL=C sort)
[ "$expected" = "$actual" ] || {
    printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
    fail "archive contents differ"
}
echo "ok   archive contains exactly the expected files"

# 2. Nothing else on the search path (checked from an empty directory)
if found=$(cd "$tmp" && kpsewhich definitions.sty); then
    fail "a definitions.sty is already installed ($found); it would mask this test"
fi

# 3. Personal TEXMF tree (README quick start)
mkdir -p "$tmp/texmf/tex/latex" "$tmp/home-work"
unzip -q "$zip" -d "$tmp/texmf/tex/latex"
cp "$tmp/texmf/tex/latex/$name/examples/minimal.tex" "$tmp/home-work/"
TEXMFHOME="$tmp/texmf" compile "$tmp/home-work" minimal.tex
echo "ok   TEXMFHOME install + examples/minimal.tex"

# 4. Subfolder of a project, located through .latexmkrc
mkdir -p "$tmp/project"
unzip -q "$zip" -d "$tmp/project"
mv "$tmp/project/$name" "$tmp/project/definitions-latex"
cp "$tmp/project/definitions-latex/examples/minimal.tex" "$tmp/project/main.tex"
echo "ensure_path('TEXINPUTS', './definitions-latex//');" > "$tmp/project/.latexmkrc"
compile "$tmp/project" main.tex latexmk
echo "ok   project subfolder + .latexmkrc"

# 5. Flat copy beside the document
mkdir -p "$tmp/flat"
unzip -q -j "$zip" "$name/*.sty" "$name/*.tex" -d "$tmp/flat"
mv "$tmp/flat/minimal.tex" "$tmp/flat/main.tex"
compile "$tmp/flat" main.tex
echo "ok   flat copy beside the document"
