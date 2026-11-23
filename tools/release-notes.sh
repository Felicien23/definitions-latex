#!/bin/sh
# Print the release notes for VERSION: its CHANGELOG.md section, followed by
# a pointer to the canonical GitLab release when CANONICAL_URL is given.
#
#   tools/release-notes.sh 2.0.0 [CANONICAL_URL]
set -eu
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { echo "usage: $0 VERSION [CANONICAL_URL]" >&2; exit 2; }
version=$1
notes=$(awk -v v="$version" '
    index($0, "## [" v "]") == 1 { on = 1; next }
    on && /^## \[/ { exit }
    on && /^\[[^]]*\]: / { exit }
    on { print }
' CHANGELOG.md | sed -e '/./,$!d')
[ -n "$notes" ] || { echo "release-notes: no CHANGELOG section for $version" >&2; exit 1; }
printf '%s\n' "$notes"
if [ $# -ge 2 ]; then
    printf '\n---\nCanonical release: %s\n' "$2"
    # shellcheck disable=SC2016  # literal backticks for Markdown
    printf '%s\n' 'Verify downloads with SHA256SUMS: `sha256sum -c SHA256SUMS`'
fi
