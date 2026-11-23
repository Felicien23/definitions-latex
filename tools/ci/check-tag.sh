#!/bin/sh
# CI, tag pipelines only: a release tag must be consistent with the sources
# (tools/check-release.sh) and must point at a commit on the default branch,
# so that a tag can never publish history that was not merged and reviewed.
set -eu
cd "$(dirname "$0")/../.."
: "${CI_COMMIT_TAG:?}" "${CI_COMMIT_SHA:?}" "${CI_DEFAULT_BRANCH:?}"

tools/check-release.sh "$CI_COMMIT_TAG"

git fetch --quiet origin "+refs/heads/$CI_DEFAULT_BRANCH:refs/remotes/origin/$CI_DEFAULT_BRANCH"
if git merge-base --is-ancestor "$CI_COMMIT_SHA" "origin/$CI_DEFAULT_BRANCH"; then
    echo "check-tag: $CI_COMMIT_TAG is on $CI_DEFAULT_BRANCH"
else
    echo "check-tag: $CI_COMMIT_TAG ($CI_COMMIT_SHA) is not on $CI_DEFAULT_BRANCH; refusing to release" >&2
    exit 1
fi
