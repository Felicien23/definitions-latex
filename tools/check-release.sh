#!/bin/sh
# Check that a tag may be released:
#   - the tag has the form vMAJOR.MINOR.PATCH[-PRERELEASE];
#   - it matches the version in definitions.sty;
#   - CHANGELOG.md has a section "## [VERSION] - DATE" whose date matches
#     the date in definitions.sty;
#   - no placeholder links remain in the documentation.
#
#   tools/check-release.sh v2.0.0
set -eu
cd "$(dirname "$0")/.."
[ $# -eq 1 ] || { echo "usage: $0 TAG" >&2; exit 2; }
tag=$1
status=0
fail() { echo "check-release: $*" >&2; status=1; }

printf '%s\n' "$tag" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$' \
    || fail "tag '$tag' is not of the form vX.Y.Z or vX.Y.Z-pre"
version=$(tools/version.sh)
date=$(tools/version.sh --date)
[ "$tag" = "v$version" ] || fail "tag $tag does not match definitions.sty version $version"
grep -Fqx "## [$version] - $date" CHANGELOG.md \
    || fail "CHANGELOG.md has no heading '## [$version] - $date'"
if grep -rn --include='*.md' --include='*.yml' --include='*.cff' \
        -e '<gitlab-namespace>' -e '<github-owner>' . 2>/dev/null | grep -v '^./tools/'; then
    fail "placeholder links remain (see above)"
fi
[ $status -eq 0 ] && echo "check-release: $tag is consistent (version $version, $date)"
exit $status
