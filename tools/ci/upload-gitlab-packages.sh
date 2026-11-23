#!/bin/sh
# CI, tag pipelines only: upload the release files in dist/ to the project's
# generic package registry as definitions-latex/<VERSION>/<file>; the GitLab
# release links to them.
#
# Safe to re-run: a file already published with the same SHA-256 is skipped,
# and a file published with different content is an error, because published
# files are never replaced.
set -eu
cd "$(dirname "$0")/../.."
: "${CI_API_V4_URL:?}" "${CI_PROJECT_ID:?}" "${CI_JOB_TOKEN:?}" "${VERSION:?}"
base="$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/definitions-latex/$VERSION"

(cd dist && sha256sum -c SHA256SUMS)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
for f in "definitions-latex-$VERSION.zip" "definitions-doc-$VERSION.pdf" SHA256SUMS; do
    code=$(curl --silent --show-error --location --output "$tmp" --write-out '%{http_code}' \
                --header "JOB-TOKEN: $CI_JOB_TOKEN" "$base/$f")
    case "$code" in
        200)
            if [ "$(sha256sum < "$tmp")" = "$(sha256sum < "dist/$f")" ]; then
                echo "already published, identical: $f"
                continue
            fi
            echo "ERROR: $f is already published with different content; not replacing it" >&2
            exit 1 ;;
        404) ;;
        *)  echo "ERROR: HTTP $code while checking $base/$f" >&2
            exit 1 ;;
    esac
    curl --silent --show-error --fail --header "JOB-TOKEN: $CI_JOB_TOKEN" \
         --upload-file "dist/$f" "$base/$f" > /dev/null
    echo "uploaded: $f"
done
