# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-06

### Added

- Initial public release.
- `definitions.sty` master file that loads the four modules below and pulls in
  every required dependency (`amsmath`, `amssymb`, `bm`, `ifthen`, `xcolor`,
  `listings`, `hyperref`, `siunitx`, `mhchem`).
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
