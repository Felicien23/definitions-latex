# Releasing (maintainers)

## Versions

- Single source of truth: the `\ProvidesPackage` line of `definitions.sty`,
  `[YYYY/MM/DD vMAJOR.MINOR.PATCH description]`. `tools/version.sh` reads it.
  The `VERSION` file repeats the number and must match (checked).
- Tags are `vMAJOR.MINOR.PATCH`, or `vMAJOR.MINOR.PATCH-rc.N` for a
  prerelease, annotated, on a commit of `main`.
- `CHANGELOG.md` has a heading `## [MAJOR.MINOR.PATCH] - YYYY-MM-DD` with the
  same date as `definitions.sty`.
- `tools/check-release.sh vX.Y.Z` checks all of this and that no placeholder
  links remain; the tag pipeline runs it and also refuses a tag that is not
  on `main`.

[Semantic Versioning](https://semver.org/) applies to what a document sees:

| Change | Version |
| --- | --- |
| Removing or renaming a command, an environment, a colour, a `listings` style, or a module file (`Commandes.tex`, ...) | major |
| Changing a command's arguments or its intended output | major |
| Loading fewer packages, or a new package with document-wide side effects | major |
| Requiring a newer LaTeX kernel | major |
| New commands, styles or units; new optional behaviour | minor |
| Restoring output that was clearly wrong; documentation; tests; tooling | patch |

When unsure whether a change is a "clear fix" or a change of intended output,
treat it as major. `tests/rendering/` shows exactly which commands' output a
change affects.

## What makes content public

| Action | Effect |
| --- | --- |
| Merge to `main` (with `PUBLISH_TO_GITHUB=true`) | `main` is pushed to GitHub after the tests pass |
| Push a tag `vX.Y.Z` | GitLab release with its files; with `PUBLISH_TO_GITHUB=true` also the tag and a GitHub release |
| Making the GitLab project public | everything in it, including all branches, tags and history |

Merge requests, other branches and other tags publish nothing.

## Release procedure

Prerequisites: the one-time setup in [MIRRORING.md](MIRRORING.md) is done, and
`main` is green.

1. On a branch, update:
   - `definitions.sty`: date and version in `\ProvidesPackage`, and `VERSION`;
   - `CHANGELOG.md`: rename `## [Unreleased]` to
     `## [X.Y.Z] - YYYY-MM-DD`, add a new empty `## [Unreleased]` above it,
     and update the link definitions at the bottom;
   - the version in the README's install example, if it changed.
2. Check locally:

   ```sh
   make clean test dist
   make check-release TAG=vX.Y.Z
   ```

3. Open a merge request, wait for its pipeline, merge it.
4. Wait for the `main` pipeline to pass, then tag the merged commit:

   ```sh
   git checkout main && git pull
   git tag -a vX.Y.Z -m "definitions-latex X.Y.Z"
   git push origin vX.Y.Z        # this publishes
   ```

5. The tag pipeline then runs, in order:
   - `test-and-package:tl2023`: tests, builds `dist/` once, checks the tag;
   - `test:texlive-latest`;
   - `release:gitlab-files`: uploads the files to the package registry;
   - `release:gitlab`: creates the GitLab release linking to them;
   - `mirror:github`: pushes the tag to GitHub;
   - `release:github`: creates the GitHub release with the same files and
     checks that GitHub and GitLab serve byte-identical files.
6. Verify:

   ```sh
   tools/verify-mirror.sh git@gitlab.com:NAMESPACE/definitions-latex.git \
                          git@github.com:OWNER/definitions-latex.git
   ```

   Download the zip and `SHA256SUMS` from both release pages and run
   `sha256sum -c SHA256SUMS`.

## Retries and failures

Every publishing job can be re-run from the pipeline page. Each one checks
what already exists, skips identical files, uploads only what is missing and
never replaces a published file, tag or release. A job that finds a published
file with *different* content stops with an error: investigate instead of
deleting the file.

`release:gitlab` uses the `release:` keyword; re-running it rewrites the same
name, notes and links.

## Never

- Move, delete or re-create a published tag.
- Replace a published release file. If a release is broken, publish
  `X.Y.(Z+1)` and say in its notes what was wrong with the previous one.
- Push to GitHub by hand, except for the recovery steps in MIRRORING.md.

## Building the files by hand

`make dist` builds `dist/definitions-latex-X.Y.Z.zip`,
`dist/definitions-doc-X.Y.Z.pdf` and `dist/SHA256SUMS` from the checked-out
commit, then installs the zip in three ways and compiles the bundled example
each time. Timestamps come from the commit date, so building the same commit
again gives byte-identical files. CI builds them once per tag pipeline; the
publishing jobs use those files, not new builds.
