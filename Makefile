# definitions-latex: developer and release tasks.
#
#   make                 build the reference manual and the minimal example
#   make lint            ChkTeX on every LaTeX source (must report nothing)
#   make test            lint + compile tests + rendering regression test
#   make dist            build dist/ (zip, manual, SHA256SUMS) and test the zip
#   make check-release TAG=v2.0.0   version/changelog consistency for a tag
#   make clean
#
# Requirements: TeX Live (pdflatex, latexmk, chktex), python3, zip, unzip.

SHELL := /bin/sh
.DEFAULT_GOAL := all

PACKAGE_FILES := definitions.sty Commandes.tex Operator.tex Units.tex LanguageStyle.tex
COMPILE_TESTS := $(basename $(notdir $(wildcard tests/compile/*.tex)))
LINT_FILES    := $(PACKAGE_FILES) doc/definitions-doc.tex examples/minimal.tex \
                 $(wildcard tests/compile/*.tex)
RENDERING_REF := tests/rendering/expected-tl2023.txt
VERSION       := $(shell tools/version.sh)

# Unwrapped log lines for tools/check_log.py.
export max_print_line := 10000
LATEXMK := latexmk -pdf -interaction=nonstopmode -halt-on-error

.PHONY: all doc example lint test test-compile test-rendering rendering-reference \
        dist check-release clean

all: doc example

doc: build/doc/definitions-doc.pdf
build/doc/definitions-doc.pdf: doc/definitions-doc.tex doc/listings/example.m $(PACKAGE_FILES)
	cd doc && TEXINPUTS=..: $(LATEXMK) -outdir=../build/doc definitions-doc.tex >/dev/null
	python3 tools/check_log.py build/doc/definitions-doc.log

example: build/examples/minimal.pdf
build/examples/minimal.pdf: examples/minimal.tex $(PACKAGE_FILES)
	cd examples && TEXINPUTS=..: $(LATEXMK) -outdir=../build/examples minimal.tex >/dev/null
	python3 tools/check_log.py build/examples/minimal.log

# ChkTeX reads ./.chktexrc.  All files: default warnings plus 46 ($...$).
# Package sources: additionally every warning except 22 (comments) and
# 30 (multiple spaces), as LaTeX Workshop runs it.
lint:
	@status=0; \
	for f in $(LINT_FILES); do \
	  out=$$(chktex -q -I0 -w46 "$$f" 2>&1) || status=1; \
	  if [ -n "$$out" ]; then printf '%s\n' "$$out"; status=1; fi; \
	done; \
	for f in $(PACKAGE_FILES); do \
	  out=$$(chktex -q -I0 -wall -n22 -n30 "$$f" 2>&1) || status=1; \
	  if [ -n "$$out" ]; then printf '%s\n' "$$out"; status=1; fi; \
	done; \
	if [ $$status -eq 0 ]; then echo "lint: ChkTeX clean ($(words $(LINT_FILES)) files)"; fi; \
	exit $$status

test: lint test-compile test-rendering example doc

test-compile:
	@for t in $(COMPILE_TESTS); do \
	  (cd tests/compile && TEXINPUTS=../..: $(LATEXMK) -outdir=../../build/tests/$$t $$t.tex >/dev/null 2>&1) \
	    || { echo "test-compile: $$t FAILED (build/tests/$$t/$$t.log)"; exit 1; }; \
	  python3 tools/check_log.py build/tests/$$t/$$t.log || exit 1; \
	  echo "ok   $$t"; \
	done

test-rendering:
	python3 tools/boxdump.py check --expected $(RENDERING_REF)

# Re-record the rendering reference after an intended output change
# (on TeX Live 2023 only; review the diff before committing).
rendering-reference:
	python3 tools/boxdump.py dump --out $(RENDERING_REF)

dist:
	tools/build-dist.sh
	tools/test-package.sh dist/definitions-latex-$(VERSION).zip

check-release:
	@test -n "$(TAG)" || { echo "usage: make check-release TAG=vX.Y.Z"; exit 2; }
	tools/check-release.sh $(TAG)

clean:
	rm -rf build dist
