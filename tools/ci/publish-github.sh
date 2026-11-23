#!/bin/sh
# CI, tag pipelines only: publish the GitHub release for the tag, with the
# same files that were uploaded to GitLab.
#
#   1. The tag must already be on GitHub (pushed by the mirror job) and must
#      point at the commit this pipeline built.
#   2. Create the release if it does not exist; otherwise upload only the
#      assets that are missing.  Existing assets are never replaced.
#   3. Download every asset back from GitHub and from the GitLab package
#      registry and compare them byte for byte with dist/.
#
# Needs GITHUB_TOKEN, GITHUB_REPOSITORY and VERSION, plus the dist/ and
# build/release-notes-github.md artefacts of the build job.
set -eu
cd "$(dirname "$0")/../.."
: "${GITHUB_TOKEN:?}" "${GITHUB_REPOSITORY:?}" "${VERSION:?}"
: "${CI_COMMIT_TAG:?}" "${CI_COMMIT_SHA:?}" "${CI_API_V4_URL:?}" "${CI_PROJECT_ID:?}" "${CI_JOB_TOKEN:?}"
export GH_TOKEN="$GITHUB_TOKEN" GH_REPO="$GITHUB_REPOSITORY"
tag=$CI_COMMIT_TAG
assets="definitions-latex-$VERSION.zip definitions-doc-$VERSION.pdf SHA256SUMS"
notes=build/release-notes-github.md
fail() { echo "publish-github: $*" >&2; exit 1; }

(cd dist && sha256sum -c SHA256SUMS)
[ -s "$notes" ] || fail "missing $notes"

commit=$(gh api "repos/$GITHUB_REPOSITORY/commits/$tag" --jq .sha) \
    || fail "tag $tag is not on GitHub yet; re-run after the mirror job has succeeded"
[ "$commit" = "$CI_COMMIT_SHA" ] || fail "GitHub $tag points at $commit, not $CI_COMMIT_SHA"

if gh release view "$tag" > /dev/null 2>&1; then
    echo "publish-github: release $tag exists; adding any missing assets"
    present=$(gh release view "$tag" --json assets --jq '.assets[].name')
    for a in $assets; do
        if printf '%s\n' "$present" | grep -Fqx "$a"; then
            echo "  present: $a"
        else
            gh release upload "$tag" "dist/$a"   # without --clobber: never replaces
            echo "  uploaded: $a"
        fi
    done
else
    prerelease=
    case "$VERSION" in *-*) prerelease=--prerelease ;; esac
    # shellcheck disable=SC2086  # $prerelease is empty or one word
    gh release create "$tag" "dist/definitions-latex-$VERSION.zip" \
        "dist/definitions-doc-$VERSION.pdf" dist/SHA256SUMS \
        --verify-tag --title "definitions-latex $VERSION" --notes-file "$notes" $prerelease
fi

check=$(mktemp -d)
trap 'rm -rf "$check"' EXIT
gh release download "$tag" --dir "$check/github"
mkdir -p "$check/gitlab"
base="$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/definitions-latex/$VERSION"
for a in $assets; do
    curl --silent --show-error --fail --location --header "JOB-TOKEN: $CI_JOB_TOKEN" \
         --output "$check/gitlab/$a" "$base/$a"
    cmp "dist/$a" "$check/github/$a" || fail "GitHub asset $a differs from the build"
    cmp "dist/$a" "$check/gitlab/$a" || fail "GitLab asset $a differs from the build"
done
for f in "$check"/github/*; do
    case " $assets " in
        *" ${f##*/} "*) ;;
        *) echo "publish-github: note: unexpected extra asset on GitHub: ${f##*/}" ;;
    esac
done
echo "publish-github: GitHub and GitLab assets for $tag are identical to the build"
