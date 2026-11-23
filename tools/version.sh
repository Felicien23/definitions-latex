#!/bin/sh
# Print the package version (e.g. 2.0.0) or, with --date, the release date
# (YYYY-MM-DD).  The \ProvidesPackage line in definitions.sty is the single
# source of truth for both.
set -eu
cd "$(dirname "$0")/.."
line=$(grep '^\\ProvidesPackage{definitions}\[' definitions.sty)
date=$(printf '%s\n' "$line" | sed -n 's/.*\[\([0-9]\{4\}\)\/\([0-9]\{2\}\)\/\([0-9]\{2\}\) v.*/\1-\2-\3/p')
version=$(printf '%s\n' "$line" | sed -n 's/.*\[[0-9/]* v\([^ ]*\) .*/\1/p')
if [ -z "$date" ] || [ -z "$version" ]; then
    echo "version.sh: cannot parse \\ProvidesPackage line: $line" >&2
    exit 1
fi
case "${1:-}" in
    --date) echo "$date" ;;
    *) echo "$version" ;;
esac
