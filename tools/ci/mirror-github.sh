#!/bin/sh
# CI: push the tested default-branch commit, or the tested release tag, to
# the read-only GitHub mirror.
#
#   - Only that one ref is pushed (never --mirror, never --all).
#   - Never forced: if GitHub's branch has diverged, the push is rejected and
#     the job fails; an existing tag with a different object is an error.
#   - Never deletes anything on GitHub.
#   - Idempotent: re-running after success does nothing.
#
# Needs GITHUB_TOKEN (fine-grained token, Contents: read and write, on the
# mirror repository only) and GITHUB_REPOSITORY (owner/name).  The token is
# handed to git through GIT_ASKPASS, so it never appears in a URL, a command
# line or the job log.
set -eu
: "${GITHUB_TOKEN:?}" "${GITHUB_REPOSITORY:?}" "${CI_COMMIT_SHA:?}"
remote=${GITHUB_REMOTE_URL:-https://github.com/$GITHUB_REPOSITORY.git}  # override only for testing

askpass=$(mktemp)
trap 'rm -f "$askpass"' EXIT
cat > "$askpass" <<'EOF'
#!/bin/sh
case "$1" in
    Username*) echo x-access-token ;;
    *) printf '%s\n' "$GITHUB_TOKEN" ;;
esac
EOF
chmod 700 "$askpass"
export GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0

remote_ref() { git ls-remote "$remote" "$1" | cut -f1; }

if [ -n "${CI_COMMIT_TAG:-}" ]; then
    ref="refs/tags/$CI_COMMIT_TAG"
    git rev-parse --verify --quiet "$ref" > /dev/null \
        || git fetch --quiet origin "+$ref:$ref"
    want=$(git rev-parse "$ref")
    have=$(remote_ref "$ref")
    if [ "$have" = "$want" ]; then
        echo "mirror: GitHub already has $CI_COMMIT_TAG"
        exit 0
    elif [ -n "$have" ]; then
        echo "mirror: $CI_COMMIT_TAG already exists on GitHub as $have, not $want; not overwriting" >&2
        exit 1
    fi
    git push "$remote" "$ref:$ref"
else
    branch=${CI_COMMIT_BRANCH:?}
    ref="refs/heads/$branch"
    want=$CI_COMMIT_SHA
    have=$(remote_ref "$ref")
    if [ "$have" = "$want" ]; then
        echo "mirror: GitHub $branch is already at $want"
        exit 0
    fi
    if [ -n "$have" ] && git cat-file -e "$have^{commit}" 2>/dev/null \
            && git merge-base --is-ancestor "$want" "$have"; then
        echo "mirror: GitHub $branch ($have) already contains $want; nothing to do"
        exit 0
    fi
    git push "$remote" "$want:$ref"
fi

have=$(remote_ref "$ref")
if [ "$have" != "$want" ]; then
    echo "mirror: verification failed: GitHub $ref is '$have', expected $want" >&2
    exit 1
fi
echo "mirror: verified GitHub $ref = $want"
