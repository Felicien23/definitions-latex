# definitions-latex

A personal collection of LaTeX command shortcuts, math operators, custom `siunitx` units, and `listings` styles for Python, MATLAB, and C++. Drop it into any project and stop redefining the same macros every time.

## Contents

| File                | Purpose                                                                                                                                |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `definitions.sty`   | Master file that loads everything below and pulls in required packages.                                                                |
| `Commandes.tex`     | Math shortcuts, vectors, brackets, integrals, identity matrix, plasma-physics macros, Goldstone scaling-law helper, custom appendices. |
| `Operator.tex`      | `\DeclareMathOperator` definitions (`\sgn`, `\esp`, `\rank`, `\rmse`, etc.).                                                           |
| `Units.tex`         | Custom `siunitx` units (`\calorie`, `\bar`, `\angstrom`, `\eV`, …).                                                                    |
| `LanguageStyle.tex` | `listings` styles + helper commands `\pythoncode`, `\matlabcode`, `\cppcode`, and their script counterparts.                           |
| `demo.tex`          | Minimal example that exercises a representative subset of the macros.                                                                  |

## Required LaTeX packages

`amsmath`, `amssymb`, `bm`, `ifthen`, `xcolor`, `listings`, `hyperref`, `siunitx`, `mhchem`, `bbold`.

All of these are loaded automatically by `definitions.sty`.

## Usage

### Option 1 — Git submodule (recommended)

From the root of the project that needs the definitions:

```bash
git submodule add https://gitlab.com/<your-user>/definitions-latex.git definitions
git submodule update --init
```

Then in your main `.tex` file:

```latex
\usepackage{definitions/definitions}
```

Updating later:

```bash
git submodule update --remote --merge
```

### Option 2 — clone alongside your project

```bash
git clone https://gitlab.com/<your-user>/definitions-latex.git
```

Set `TEXINPUTS` so LaTeX can find the package, or just compile from inside the cloned folder:

```latex
\usepackage{definitions}
```

### Option 3 — pick and choose

Each module is a plain `.tex` file. Pull in only what you need:

```latex
\input{path/to/definitions-latex/Operator.tex}
\input{path/to/definitions-latex/Commandes.tex}
```

## Building the demo

```bash
latexmk -pdf demo.tex
```

The CI pipeline (`.gitlab-ci.yml`) builds `demo.pdf` on every push and publishes it as a job artifact.

## Conventions

- Module files are loaded in this order: `Operator.tex` -> `Units.tex` -> `Commandes.tex` -> `LanguageStyle.tex`.
- Every macro is declared with `\newcommand` so accidental re-definition raises an error rather than silently overwriting.
- Domain-specific (plasma physics, ITER, etc.) macros live in a clearly labelled section of `Commandes.tex`.

## License

MIT — see [`LICENSE`](LICENSE).
