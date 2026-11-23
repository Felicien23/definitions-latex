#!/bin/sh
# Compare the public refs of the canonical GitLab repository and the GitHub
# mirror.  Read-only: it only runs `git ls-remote`, with whatever credentials
# your git already uses (SSH keys or a credential helper).
#
#   tools/verify-mirror.sh GITLAB_REMOTE GITHUB_REMOTE [BRANCH]
#   tools/verify-mirror.sh git@gitlab.com:NS/definitions-latex.git \
#                          git@github.com:OWNER/definitions-latex.git
#
# Public refs are BRANCH (default: main) and tags matching v*.  Exit status 1
# if they differ, or if GitHub has refs outside that set.
set -eu
[ $# -ge 2 ] || { sed -n '2,12p' "$0" >&2; exit 2; }
gitlab=$1 github=$2 branch=${3:-main}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

public() { # remote -> "sha ref" lines for the public refs, peeled tags included
    git ls-remote "$1" "refs/heads/$branch" 'refs/tags/v*' | sort -k2
}
public "$gitlab" > "$tmp/gitlab"
public "$github" > "$tmp/github"
git ls-remote "$github" | grep -v '^[0-9a-f]*[[:space:]]HEAD$' | \
    grep -Ev "[[:space:]](refs/heads/$branch|refs/tags/v[^[:space:]]*)$" > "$tmp/extra" || true

status=0
if diff -u "$tmp/gitlab" "$tmp/github" > "$tmp/diff"; then
    echo "verify-mirror: $(wc -l < "$tmp/gitlab" | tr -d ' ') public refs identical on both sides"
else
    echo "verify-mirror: public refs differ (- GitLab, + GitHub):"
    sed -n '3,$p' "$tmp/diff"
    status=1
fi
if [ -s "$tmp/extra" ]; then
    echo "verify-mirror: GitHub has refs outside the public set (review; pull requests appear as refs/pull/*):"
    cat "$tmp/extra"
    grep -qv 'refs/pull/' "$tmp/extra" && status=1
fi
exit $status
