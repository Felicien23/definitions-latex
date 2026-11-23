# definitions-latex

**Canonical repository: [definitions-latex on GitLab](https://gitlab.com/<gitlab-namespace>/definitions-latex).**
The [GitHub repository](https://github.com/<github-owner>/definitions-latex)
is a read-only mirror kept in sync automatically. Please report issues and submit
merge requests on GitLab (see [Contributing](#contributing-and-support)).

`definitions-latex` provides the LaTeX package **`definitions`**: about a
hundred short commands for derivatives, vectors, norms and brackets, statistics
operators, `siunitx` units and `listings` styles for Python, MATLAB and C++,
plus some plasma-physics notation (Z<sub>eff</sub>, loop voltage, sputtering
yields, a confinement-time scaling-law product).

It is meant for people who write physics or engineering documents in LaTeX and
want these shortcuts without redefining them in every project.

## Status and limitations

- Version **2.0.0**. The package started as one author's personal collection
  and is now published as is. The command set is small and stable; changes
  follow [Semantic Versioning](#releases-and-versioning).
- The names are short and generic (`\x`, `\R`, `\dif`, `\var`, ...). Commands
  are defined with `\newcommand`, so a clash stops compilation instead of
  silently replacing another definition. Known clashes: `physics` (`\eval`,
  `\grad`, `\rank`, `\var`), `commath` (`\dif`, `\eval`), `tensor` (`\tensor`).
- Loading the package sets `secnumdepth` to 4 (numbered `\paragraph`s) and
  defines a few colours, three `listings` styles and a counter. See the
  reference manual for the list.
- The plasma-physics commands encode one author's notation; they are kept
  because existing documents use them.
- `\pythoncode`, `\matlabcode` and `\cppcode` take their code as a normal
  argument: no `%`, `#` or unbalanced braces.
- Not on CTAN; distributed through GitLab and GitHub releases.

## Requirements

- A LaTeX kernel from 2021-11-15 or later.
- The packages `amsmath`, `amssymb`, `bm`, `ifthen`, `xcolor`, `listings`,
  `siunitx` and `mhchem`, which `definitions` loads itself. `\iden` also needs
  the `bbold` fonts (not the `bbold` package).
- On Debian or Ubuntu:

  ```sh
  sudo apt install texlive-latex-recommended texlive-latex-extra texlive-science
  sudo apt install texlive-fonts-extra   # only for \iden (bbold font)
  ```

  A full TeX Live or MiKTeX installation already contains everything.

### Compatibility

| | Status |
| --- | --- |
| pdfLaTeX, LuaLaTeX, XeLaTeX on TeX Live 2023 (Debian/Ubuntu packages) | Tested: all compile tests pass with no warnings in the log (the manual and the release archive are built with pdfLaTeX) |
| Classes `article`, `scrartcl` (KOMA-Script), `beamer` | Tested |
| Current TeX Live (`texlive/texlive:latest`) | Covered by a CI job; not yet observed passing |
| MiKTeX, Overleaf, TeX Live 2022 | Expected to work; not tested |
| TeX Live 2021 or older | Not supported (needs LaTeX 2021-11-15) |

## Installation

Download `definitions-latex-<version>.zip` from the
[GitLab releases](https://gitlab.com/<gitlab-namespace>/definitions-latex/-/releases)
(the same files are attached to the GitHub releases). Check it with the
`SHA256SUMS` file from the same release:

```sh
sha256sum -c SHA256SUMS --ignore-missing
```

Then choose one of the following.

**For all your documents** (local TeX Live; recommended). Unzip into your
personal TEXMF tree:

```sh
TEXMFHOME=$(kpsewhich -var-value TEXMFHOME)
mkdir -p "$TEXMFHOME/tex/latex"
unzip definitions-latex-2.0.0.zip -d "$TEXMFHOME/tex/latex"
```

With MiKTeX, add the unzipped folder to a user TEXMF root in the MiKTeX
Console instead.

**For one project**, in a subfolder. Unzip into the project as
`definitions-latex/` (or add the repository as a git submodule with that name)
and tell latexmk where it is with a `.latexmkrc` next to your document:

```perl
ensure_path('TEXINPUTS', './definitions-latex//');
```

`\usepackage{definitions-latex/definitions}` also works without the
`.latexmkrc`, but LaTeX then warns that the package name differs from the
requested path.

**Overleaf or a flat copy.** Upload `definitions.sty`, `Commandes.tex`,
`Operator.tex`, `Units.tex` and `LanguageStyle.tex` next to your main file.

If a project still contains old copies of `Commandes.tex` and friends from
before you used the package, delete them: a file beside the document takes
precedence over the installed one.

## Quick start

Save this as `minimal.tex` (it is `examples/minimal.tex` in the archive):

```latex
\documentclass{article}
\usepackage{definitions}

\begin{document}
The mean of \(X\) over a volume is
\[
  \mean{X} = \frac{1}{V}\intt X(\x)\diftt ,
\]
its rate of change is \(\fracdif{\mean{X}}{t}\), and
\(\esp\Cro{X}\), \(\var X\) and \(\Absfracu{X}\) are equally short to type.
A pressure of \qty{1.2}{\bar}, an energy of \qty{3}{\kilo\eV}, and
some Python: \pythoncode{import numpy as np}.
\end{document}
```

and compile it:

```sh
pdflatex minimal.tex
```

The result is a one-page `minimal.pdf` with ⟨X⟩ = 1/V ∭ X(**x**) dx dy dz as a
displayed equation, a derivative d⟨X⟩/dt, 𝔼[X], Var X, |ΔX/X|, "1.2 bar",
"3 keV" and the Python snippet with `import` highlighted in blue. The log has no
warnings.

## Using the package

```latex
\usepackage[dvipsnames]{xcolor}   % packages that take options: before
\usepackage{definitions}
\usepackage{hyperref}             % hyperref: late, as usual
```

- Load packages that need options (`xcolor`, `amsmath`, `siunitx`, ...)
  **before** `definitions`, and `hyperref` after it. `definitions` does not
  load `hyperref`; `\mail` and `\ftplink` produce links when it is loaded and
  plain text otherwise.
- The reference manual `definitions-doc.pdf`, attached to every release, lists
  every command with its output. Its source is `doc/definitions-doc.tex`.
- To use only part of the package, load the dependencies yourself and
  `\input` the module files you need: `Operator.tex` (operators),
  `Units.tex` (units), `Commandes.tex` (everything else),
  `LanguageStyle.tex` (code listings). `tests/compile/modules-only.tex` shows
  the complete preamble.

### Upgrading from 1.0.0

Version 2.0.0 no longer loads `hyperref`. If a document relied on that (for
`\url`, `\hypersetup`, ...), add `\usepackage{hyperref}` to its preamble. Some output that 1.0.0 had
changed by accident is restored. See [CHANGELOG.md](CHANGELOG.md).

## Development and tests

Requirements: TeX Live with `latexmk` and `chktex`, Python 3, GNU make, `zip`
and `unzip`.

```sh
make            # build build/doc/definitions-doc.pdf and build/examples/minimal.pdf
make lint       # ChkTeX must report nothing
make test       # lint, compile tests with three engines, rendering regression test
make dist       # release files in dist/, then install and test the zip in isolation
```

- `tests/compile/` covers KOMA-Script, beamer, `hyperref` with options and
  `cleveref`, no `hyperref`, the modules without the `.sty`, whole-file
  listings and units. Every log must be free of warnings and bad boxes.
- `tests/rendering/` records TeX's exact box output for every command. On
  TeX Live 2023 `make test` fails if any command's output changes; after an
  intended change, run `make rendering-reference` and explain the diff in the
  merge request. On other TeX Live releases this check is skipped.
- `make dist` installs the zip into a temporary TEXMF tree, a project subfolder
  and a flat folder and compiles the bundled example each time, using nothing
  from the working tree.

GitLab CI runs the same targets on every merge request; see
[.gitlab-ci.yml](.gitlab-ci.yml).

## Releases and versioning

Releases are published on the
[GitLab releases page](https://gitlab.com/<gitlab-namespace>/definitions-latex/-/releases)
(canonical) and mirrored to the
[GitHub releases page](https://github.com/<github-owner>/definitions-latex/releases)
with identical files: the zip, the reference manual and `SHA256SUMS`.

Versions follow [Semantic Versioning](https://semver.org/). The version and
date in `definitions.sty`'s `\ProvidesPackage` line are authoritative; tags are
`vMAJOR.MINOR.PATCH`. A change is **breaking** (major version) if a document
that compiled with the previous version may stop compiling or render
differently: removing or renaming a command or a module file, changing a
command's arguments or intended output, loading fewer packages or loading a
package with document-wide side effects, or requiring a newer LaTeX. New
commands are minor; fixes to output that was clearly wrong are patches.

Maintainers: [doc/RELEASING.md](doc/RELEASING.md) and
[doc/MIRRORING.md](doc/MIRRORING.md).

## Contributing and support

Issues and merge requests go to the
[GitLab project](https://gitlab.com/<gitlab-namespace>/definitions-latex).
GitHub pull requests are not merged, because GitHub is a mirror; see
[CONTRIBUTING.md](CONTRIBUTING.md) for how to send the change to GitLab.

## Licence and attribution

MIT licence; see [LICENSE](LICENSE). The repository contains no third-party
files. A few short macros follow idioms that are widely shared on TeX Stack
Exchange (`\numberthis`, `\rom` via `\@slowromancap`, the `\CC` logo, and
selecting the bbold font with `\usefont` in `\iden`). The `listings` language
definitions used by the code styles come from the `listings` package.

## Repository layout

| Path | Contents |
| --- | --- |
| `definitions.sty`, `Commandes.tex`, `Operator.tex`, `Units.tex`, `LanguageStyle.tex` | the package |
| `doc/` | reference manual source; maintainer guides |
| `examples/minimal.tex` | the quick-start example |
| `tests/` | compile tests and the rendering reference |
| `tools/` | build, test, release and mirroring scripts |
| `.gitlab/`, `.github/` | issue and merge-request templates; mirror notice for GitHub |
