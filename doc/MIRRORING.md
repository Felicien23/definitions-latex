# GitHub mirror (maintainers)

GitLab is the single source of truth. GitHub carries a read-only copy so the
package can be found and downloaded there. Nobody develops on GitHub.

| What | GitLab | GitHub |
| --- | --- | --- |
| Branch `main`, tags `v*` | canonical | copied by CI |
| Other branches and tags | yes | never |
| Releases (notes + files) | canonical, created by CI | copy created by CI with the same files |
| Issues, merge requests, CI results | yes | no (issues disabled, PRs closed) |

## How it works

The GitLab CI job `mirror:github` (`tools/ci/mirror-github.sh`) pushes:

- on a pipeline for `main`: that commit to GitHub's `main`;
- on a pipeline for a tag `vX.Y.Z`: that tag (and the history it needs).

It runs only after both test jobs passed, only on protected refs (the token is
a protected variable), and only when `PUBLISH_TO_GITHUB` is `true`. It pushes
exactly one ref, never with `--force` and never deletes anything. If GitHub's
`main` has diverged, git rejects the push and the job fails, leaving GitHub
untouched. If a tag already exists on GitHub with a different object, the job
fails rather than replace it. Re-running a successful job does nothing.

The GitHub release is a separate job (`release:github`, see
[RELEASING.md](RELEASING.md)); pushing a tag alone does not create a release.

### Why not GitLab's built-in push mirroring

GitLab's push mirroring (Settings > Repository > Mirroring repositories) is
simpler to switch on, but according to the GitLab documentation it always
pushes **all tags** (the *Mirror only protected branches* option filters
branches only), propagates deletions, and by default overwrites a diverged
remote. It also pushes every commit before CI has tested it. The CI job gives
an explicit public set and never forces or deletes. If you prefer the built-in
mirror anyway, use it with *Mirror only protected branches* and *Keep
divergent refs*, keep `PUBLISH_TO_GITHUB` false so that the two do not both
push, and make sure the GitLab project only ever has release tags.

## One-time setup

Do these in order. Nothing becomes public before step 6.

The README, release notes and GitHub description send visitors to the GitLab
project for issues, merge requests and canonical releases, so the GitLab
project needs to be public (Settings > General > Visibility) before or when
the mirror is enabled. Changing visibility publishes *everything* in the
project, including branches and tags outside the mirrored set, so do it only
after step 1, and after deleting or reviewing any branch you do not want seen.

1. **Audit what would be published.** In a full clone of the GitLab
   repository, with the preparation branch merged:

   ```sh
   git fetch origin --tags && git checkout main && git pull
   tools/audit-publication.sh            # main + every v* tag
   ```

   It lists the refs, the author/committer names and e-mail addresses, every
   file path that ever existed, large files, credential-like strings (masked)
   and home-directory paths in the **whole history** of `main` and the `v*`
   tags. A credential finding blocks publication: revoke the credential first,
   then see "If the history must be cleaned" below. Also delete or rename any
   tag starting with `v` that is not a release.

2. **Create the GitHub repository** `definitions-latex` under your account,
   **empty** (no README, licence or .gitignore), public.
   - Description: `Read-only mirror of https://gitlab.com/NAMESPACE/definitions-latex — LaTeX shortcuts for maths, units and code listings. Issues and merge requests on GitLab.`
   - Website: the GitLab project URL.
   - Settings > General > Features: untick *Issues*, *Wiki*, *Projects*,
     *Discussions*. Under *Pull requests*, choose "Restrict to collaborators"
     (or disable them); the PR template in `.github/` explains where to go.
   - If a repository of that name already exists with content, do not
     overwrite it: rename or archive it first and review what it contains.

3. **Create a fine-grained personal access token** on GitHub (Settings >
   Developer settings > Fine-grained tokens):
   - Repository access: *Only select repositories* → `definitions-latex`.
   - Permissions: *Contents: Read and write* (Metadata: read is added
     automatically). Nothing else; in particular not *Workflows* (the mirror
     must never push GitHub Actions workflows).
   - Expiry: one year at most; put a reminder in your calendar.

4. **Store it in GitLab** (Settings > CI/CD > Variables > Add variable):
   - Key `GITHUB_TOKEN`, value the token.
   - Visibility *Masked and hidden*; tick *Protect variable*; leave *Expand
     variable reference* unticked.

5. **Protect the release refs** (Settings > Repository): `main` is protected
   by default; add a protected tag `v*` that only Maintainers may create.
   Merge-request pipelines from forks never receive protected variables. Do
   not use "Run pipeline in parent project" for a fork's merge request that
   changes `.gitlab-ci.yml` or `tools/` without reviewing it first.

6. **Enable publishing**: run `tools/set-project-urls.sh NAMESPACE OWNER`,
   which fills in the GitLab and GitHub names in the documentation, the
   templates and `GITHUB_REPOSITORY` in `.gitlab-ci.yml`; review `git diff`
   and merge it through a merge request.  Then add the project variable
   `PUBLISH_TO_GITHUB` = `true` (not protected, not masked).
   The next pipeline on `main` pushes `main` to GitHub. Run one manually with
   Build > Pipelines > Run pipeline > `main` if nothing else is pending.

7. **Verify the initial synchronisation**:

   ```sh
   tools/verify-mirror.sh git@gitlab.com:NAMESPACE/definitions-latex.git \
                          git@github.com:OWNER/definitions-latex.git
   ```

   It compares `main` and every `v*` tag, including the commits the tags
   point at, and reports refs on GitHub outside that set.

   Existing release tags (for example `v1.0.0` if it was tagged) are not
   pushed by `main` pipelines. Decide whether they should be public; if so,
   re-run the tag's pipeline or push them once by hand
   (`git push github v1.0.0` with a remote you configured locally). They
   will have no GitHub release unless their tag pipeline runs `release:github`.

## When something fails

- **`mirror:github` fails with "rejected (fetch first)" or "non-fast-forward"**:
  someone changed GitHub directly. Inspect GitHub, decide what to keep, and
  bring the change into GitLab through a merge request if it is wanted. Only
  then, and only deliberately, reset GitHub's `main` to GitLab's (a manual
  `git push --force-with-lease` that you type yourself). The CI job never
  does this.
- **"exists on GitHub as ..., not ..."**: a tag was moved or recreated in
  GitLab after it was published. Published tags must not move; restore the
  original tag in GitLab and release a new version instead.
- **Authentication errors (401/403)**: the token expired or lost access.
  Create a new one (step 3), replace the variable (step 4), re-run the job.
- Every mirror and release job can simply be re-run from the pipeline page;
  each checks what already exists and only adds what is missing.

GitLab shows failed jobs on the pipeline page and, by default, e-mails the
person who triggered the pipeline.

## Deletions

Nothing is ever deleted on GitHub automatically.

- Branches other than `main` are never mirrored, so there is nothing to clean
  up when they are deleted on GitLab.
- A published tag or release should not be deleted. If it must be (for
  example a credential was published), delete it on **both** sides by hand
  (`git push origin :refs/tags/vX.Y.Z` and `git push github :refs/tags/vX.Y.Z`,
  then delete both releases), and say so in the changelog.

## If the history must be cleaned

Do not rewrite history in place. If the audit finds something that must not
become public:

1. Revoke the credential or remove the data at its source first.
2. Make a full backup: `git clone --mirror git@gitlab.com:NAMESPACE/definitions-latex.git backup.git`.
3. Rewrite a *copy* with `git filter-repo` (for example `--path FILE
   --invert-paths` or `--replace-text`), rerun the audit on the copy, and
   compare the result with the backup.
4. Pushing the rewritten history to GitLab changes every commit ID after the
   first changed commit: open merge requests must be recreated, every clone
   must be re-cloned, and existing tags must be recreated (they will point to
   new commits). Agree this with everyone who has a clone, unprotect `main`
   temporarily, force-push, re-protect it, and only then enable the mirror.
   GitHub must not have received the old history; if it has, delete and
   recreate the GitHub repository rather than force-pushing over it.

## Rotating the token

Before it expires: create a new token (step 3), replace `GITHUB_TOKEN`
(step 4), run a pipeline on `main`, then revoke the old token on GitHub.
