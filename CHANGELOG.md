# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change is defined in `doc/RELEASING.md`.

## [Unreleased]

## [2.0.0] - 2026-11-20

First public release.

### Changed (breaking)
- `definitions.sty` no longer loads `hyperref`. Loading it inside the package
  forced it early and without options, so `\usepackage[colorlinks]{hyperref}`
  after `definitions` failed with "Option clash for package hyperref".
  `\mail` and `\ftplink` now make links when `hyperref` is loaded and print
  plain text otherwise. Documents that relied on the package loading
  `hyperref` (for `\url`, `\hypersetup`, ...) must load it themselves.
- `\pythoncode`, `\matlabcode` and `\cppcode` no longer change the default
  `listings` style: 1.0.0 called `\lstset`, so every later listing in the
  same group inherited the last inline style.

### Fixed
- Output that 1.0.0 changed without listing it is restored to the original
  files: the spacing of `\Cro` (spaced like an ordinary symbol again) and
  `\diftt` (no thin spaces between the differentials), and the MATLAB
  listing style (bold keywords, dvipsnames Blue and Purple colours).
  (`\intt` was already restored in 1.0.1.)
- `\CC` and `\GoldstoneScalinglaw` used the obsolete font commands `\bf` and
  `\rm`, which KOMA-Script classes reject; output in the standard classes is
  unchanged.
- `\usepackage{<dir>/definitions}`, recommended for git submodules in 1.0.0,
  did not find the module files.  They are now loaded from the package's own
  directory.  This replaces the unreleased `\input@path` change made after
  1.0.1, which also changed where every later `\input` of the document was
  searched and still preferred a stale `Commandes.tex` beside the document.
- The package sources are also clean under `chktex -wall`.  The empty groups
  `{}` added in 1.0.1 to silence ChkTeX are replaced by forms that need none
  (output unchanged).
- `\angstrom` is declared with `\AA` instead of a literal UTF-8 character.

### Added
- Reference manual `definitions-doc.pdf` listing every command with its
  output, attached to releases (replaces `demo.tex`).
- `examples/minimal.tex`, the README quick start.
- Tests: compile tests with pdfLaTeX, LuaLaTeX and XeLaTeX, a rendering
  regression test, and a test that installs the release archive in isolation.
- `Makefile`, `.chktexrc`, release and mirroring scripts, GitLab CI that
  publishes releases on GitLab and mirrors them to GitHub.
- `CONTRIBUTING.md`, maintainer guides, issue and merge-request templates.

### Removed
- `demo.tex` and the tracked `demo.pdf`; see the reference manual instead.

## [1.0.1] - 2026-05-08

- Made some modifications inside `Commandes.tex` and `LanguageStyle.tex` to remove the warnings that were left inside.
- Remove arrows inside the [`README.md`](README.md), there were non-ASCII characters.

## [1.0.0] - 2026-05-06

First packaged version (distributed privately).

### Added
- `definitions.sty` master file that loads the four modules below and pulls in
  every required dependency (`amsmath`, `amssymb`, `bm`, `ifthen`, `xcolor`,
  `listings`, `hyperref`, `siunitx`, `mhchem`, `bbold`).
- `Commandes.tex` — math shortcuts, vectors, brackets, integrals, identity
  matrix, plasma-physics macros, Goldstone scaling-law helper, custom appendices.
- `Operator.tex` — math operators (`\sgn`, `\esp`, `\rank`, `\rmse`, `\pvalue`, …).
- `Units.tex` — custom `siunitx` units (`\calorie`, `\bar`, `\angstrom`, `\eV`).
- `LanguageStyle.tex` — `listings` styles for Python, MATLAB, C++.
- `demo.tex` — minimal example exercising a representative subset of the macros.
- GitLab CI configuration that builds the demo on every push and publishes the
  PDF as a job artifact.

### Fixed
- `\et` macro: was `\bm{e_}{\theta}` (subscript escaped from the bold group);
  now `\bm{e}_{\theta}`.
- `\matlabcode`: referenced an undefined style `Matlab`; now uses `matlabstyle`,
  matching the surrounding listing styles.
- `\CC` was declared twice — once with `\newcommand`, once with `\def` (the
  `\def` silently won). The `\newcommand` form has been removed.
- Removed stray `~` (non-breaking space) characters inside math-mode `\frac`
  arguments — they were rendering as visible gaps inside derivatives.
- `\nor`: switched from `\left|\left| ... \right|\right|` to the proper
  `\left\| ... \right\|` primitive.
- `\pvalue`: hyphen now lives inside `\text{...}` so it isn't typeset as a
  binary minus sign.
- MATLAB listing style: `morecomment` was registered for the macro `\ldots`
  rather than the literal string `...`, which broke `\matlabcode` whenever
  it appeared near other macros. Now matches MATLAB's real line-continuation
  syntax.

[Unreleased]: https://gitlab.com/<gitlab-namespace>/definitions-latex/-/compare/v2.0.0...main
[2.0.0]: https://gitlab.com/<gitlab-namespace>/definitions-latex/-/releases/v2.0.0
