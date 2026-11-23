#!/bin/sh
# Replace the <gitlab-namespace> and <github-owner> placeholders in the
# documentation, templates and .gitlab-ci.yml with the real names.
#
#   tools/set-project-urls.sh GITLAB_NAMESPACE GITHUB_OWNER
#   tools/set-project-urls.sh jdoe jdoe
#
# GITLAB_NAMESPACE is the user or group path in
# https://gitlab.com/GITLAB_NAMESPACE/definitions-latex.  Review the result
# with `git diff` before committing.
set -eu
[ $# -eq 2 ] || { sed -n '2,10p' "$0" >&2; exit 2; }
case "$1$2" in *[!A-Za-z0-9._/-]*) echo "unexpected characters in names" >&2; exit 2 ;; esac
cd "$(dirname "$0")/.."
git ls-files -z -co --exclude-standard -- . ':!tools/' \
    | xargs -0 grep -l -Z -e '<gitlab-namespace>' -e '<github-owner>' 2>/dev/null \
    | xargs -0 -r sed -i -e "s|<gitlab-namespace>|$1|g" -e "s|<github-owner>|$2|g"
git grep -n -e "gitlab.com/$1/" -e "github.com/$2/" -e "\"$2/definitions-latex\"" -- . ':!tools/' | sed 's/^/  /'
