# Contributing

Thank you for helping. The canonical repository is the
[GitLab project](https://gitlab.com/Scorptunorone/definitions-latex);
issues, discussion and merge requests happen there only.

## Reporting a problem or requesting a command

Open an issue on GitLab and choose the *Bug* or *Command request* template.
For a bug, include a minimal document that shows it, the first error or
warning from the `.log` file, and the output of `pdflatex --version`.

## Coming from GitHub

The [GitHub repository](https://github.com/Felicien23/definitions-latex) is a
read-only mirror: it is overwritten from GitLab and nothing merged there would
survive. Pull requests opened on GitHub are not merged; they are closed with a
link back here. To send a change:

1. Sign in to GitLab (an existing GitHub account can be used to sign in).
2. Fork the GitLab project, push your branch to the fork and open a merge
   request.
3. If you cannot use GitLab, attach a patch (`git format-patch`) to an issue
   and the maintainer will apply it with you as the author.

## Making a change

Requirements: TeX Live with `latexmk` and `chktex`, Python 3, GNU make,
`zip` and `unzip`.

```sh
make test     # must pass before you open a merge request
make dist     # if you changed packaging, the README or examples
```

Conventions:

- Define new commands with `\newcommand` or `\DeclareMathOperator`, never
  `\def` or `\renewcommand`, so that clashes are reported instead of hidden.
- Keep `make lint` silent: ChkTeX must report nothing. Use `\( \)` for inline
  math, not `$ $`. An inline `% chktex N` suppression needs a reason in the
  same comment.
- Logs must stay free of warnings and bad boxes (`tools/check_log.py`).
- For a new command, add a row to the reference manual
  (`doc/definitions-doc.tex`) and a case to `tests/rendering/cases.tex`.
- If you change a command's output on purpose, run `make rendering-reference`
  (TeX Live 2023) and explain the diff in the merge request. An unexplained
  change to `tests/rendering/expected-tl2023.txt` will not be merged.
- Add a line under `## [Unreleased]` in `CHANGELOG.md`.
- Say in the merge request whether the change is breaking; the definition is
  in [doc/RELEASING.md](doc/RELEASING.md).

By contributing you agree that your contribution is released under the
project's MIT licence.
