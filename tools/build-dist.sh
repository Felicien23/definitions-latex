#!/bin/sh
# Build the release artefacts into dist/:
#   definitions-latex-<version>.zip   package, manual, README, licence, changelog
#   definitions-doc-<version>.pdf     the reference manual on its own
#   SHA256SUMS
# Timestamps come from SOURCE_DATE_EPOCH (default: the last commit), so
# rebuilding the same commit gives byte-identical files.
set -eu
cd "$(dirname "$0")/.."

version=$(tools/version.sh)
name="definitions-latex-$version"
: "${SOURCE_DATE_EPOCH:=$(git log -1 --format=%ct 2>/dev/null || date -u -d "$(tools/version.sh --date)" +%s)}"
export SOURCE_DATE_EPOCH FORCE_SOURCE_DATE=1 TZ=UTC

rm -rf build/doc build/stage dist
make --no-print-directory doc

stage="build/stage/$name"
mkdir -p "$stage/examples" dist
cp definitions.sty Commandes.tex Operator.tex Units.tex LanguageStyle.tex \
   README.md LICENSE CHANGELOG.md "$stage/"
cp examples/minimal.tex "$stage/examples/"
cp build/doc/definitions-doc.pdf "$stage/"

# Normalise metadata so the archive depends only on the file contents.
find build/stage -type d -exec chmod 755 {} +
find build/stage -type f -exec chmod 644 {} +
find build/stage -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
(cd build/stage && find "$name" -type f | LC_ALL=C sort | zip -X -D -q "../../dist/$name.zip" -@)

cp build/doc/definitions-doc.pdf "dist/definitions-doc-$version.pdf"
(cd dist && sha256sum "$name.zip" "definitions-doc-$version.pdf" > SHA256SUMS)
cat dist/SHA256SUMS
