#!/bin/sh
# Audit everything that publishing would expose: the full history reachable
# from the refs that will be mirrored, not just the current files.
# Read-only; run it in a full clone of the canonical repository.
#
#   tools/audit-publication.sh                # main + all v* tags
#   tools/audit-publication.sh main v2.0.0    # explicit refs
#
# Reports
#   1. all branches and tags, and which of them are in the public set
#   2. commit identities (names and e-mail addresses) that become public
#   3. every path that ever existed in that history, marking paths that are
#      no longer in the current tree
#   4. blobs larger than 1 MiB
#   5. credential-like strings (private keys, GitLab/GitHub/AWS/Slack tokens,
#      password assignments; references such as $TOKEN are ignored): BLOCKER.  Matches are masked; the full value is
#      never printed.
#   6. absolute home-directory paths
# Exit status 1 if section 5 finds anything.
set -eu
git rev-parse --git-dir > /dev/null 2>&1 || { echo "run inside a git repository" >&2; exit 2; }
[ "$(git rev-parse --is-shallow-repository)" = false ] \
    || { echo "shallow clone: run 'git fetch --unshallow' first" >&2; exit 2; }

if [ $# -gt 0 ]; then
    refs="$*"
else
    refs="main $(git tag -l 'v*' | tr '\n' ' ')"
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "== 1. Refs (public set: $refs)"
git for-each-ref --format='%(refname:short)	%(objectname:short)' refs/heads refs/tags | \
while IFS='	' read -r short sha; do
    mark=private
    for r in $refs; do [ "$r" = "$short" ] && mark=PUBLIC; done
    printf '  %-8s %-30s %s\n' "$mark" "$short" "$sha"
done
git for-each-ref --format='%(refname)' refs/remotes | sed 's/^/  (remote-tracking, not pushed) /'

# shellcheck disable=SC2086
git rev-list --objects $refs > "$tmp/objects"
cut -d' ' -f1 "$tmp/objects" | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' \
    | awk '$1 == "blob" {print $2, $3}' | sort -u > "$tmp/blobs"

echo "== 2. Identities in public history"
# shellcheck disable=SC2086
git log --format='  author:    %an <%ae>%n  committer: %cn <%ce>' $refs | sort | uniq -c | sort -rn

echo "== 3. Paths in public history ('gone' = not in the current tree of the first ref)"
first=${refs%% *}
git ls-tree -r --name-only "$first" | sort > "$tmp/current"
awk 'NF > 1 {sub(/^[0-9a-f]+ /, ""); print}' "$tmp/objects" | sort -u > "$tmp/paths"
while IFS= read -r p; do
    if grep -Fqx -- "$p" "$tmp/current"; then printf '        %s\n' "$p"; else printf '  gone  %s\n' "$p"; fi
done < "$tmp/paths"

echo "== 4. Blobs larger than 1 MiB"
awk '$2 > 1048576' "$tmp/blobs" | while read -r sha size; do
    printf '  %10d  %s\n' "$size" "$(grep "^$sha " "$tmp/objects" | head -1 | cut -d' ' -f2-)"
done

echo "== 5. Credential-like strings (BLOCKER if any)"
pattern='-----BEGIN [A-Z ]*PRIVATE KEY-----|glpat-[0-9A-Za-z_-]{20,}|gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{40,}|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}|(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*["'\'']?[^[:space:]"'\''$]{8,}'
found=0
while read -r sha size; do
    git cat-file -p "$sha" | grep -I -n -o -i -E -e "$pattern" > "$tmp/hits" 2>/dev/null || continue
    path=$(grep "^$sha " "$tmp/objects" | head -1 | cut -d' ' -f2-)
    while IFS= read -r hit; do
        line=${hit%%:*} value=${hit#*:}
        masked=$(printf '%s' "$value" | sed -E 's/^(.{6}).*(.{2})$/\1********\2/')
        printf '  %s:%s  %s  (blob %s)\n' "$path" "$line" "$masked" "$(printf '%s' "$sha" | cut -c1-10)"
        found=1
    done < "$tmp/hits"
done < "$tmp/blobs"
[ $found -eq 0 ] && echo "  none found"

echo "== 6. Absolute home-directory paths"
home=0
while read -r sha size; do
    git cat-file -p "$sha" | grep -I -n -o -E '(/home/|/Users/|[A-Za-z]:\\Users\\)[A-Za-z0-9._-]+' > "$tmp/hits" 2>/dev/null || continue
    path=$(grep "^$sha " "$tmp/objects" | head -1 | cut -d' ' -f2-)
    sed "s|^|  $path:|" "$tmp/hits"
    home=1
done < "$tmp/blobs"
[ $home -eq 0 ] && echo "  none found"

if [ $found -ne 0 ]; then
    echo "audit: credential-like strings found; see doc/RELEASING.md before publishing" >&2
    exit 1
fi
echo "audit: no blockers found by this script; review sections 1-4 and 6 by eye"
