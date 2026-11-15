# TripyTravy paper

Open [main.pdf](main.pdf) for the compiled IEEE conference-format manuscript. It describes passphrase-protected exports in the current Creator and Viewer, reports the beta evaluation, and specifies the remaining stable workflows. The entry point is [main.tex](main.tex). The author block is in [sections/authors.tex](sections/authors.tex), and references are in [references.bib](references.bib) and [literature.bib](literature.bib). [Literature analysis](literature-analysis.md) records each scholarly source and its relevance. Replace the remaining coauthor label with the confirmed name before submission.

## Build

From this directory, run either command with its corresponding TeX distribution installed.

~~~powershell
latexmk -pdf -halt-on-error main.tex
tectonic main.tex
~~~

On Overleaf, upload the LaTeX sources, bibliography, and figures, then select main.tex as the main document. The build uses the IEEEtran class, BibTeX, and TikZ.

## Evaluation materials

TripyTravy's application source is proprietary. This repository contains the manuscript, aggregate results, and a synthetic attachment-size probe. Running the probe or application test suites requires authorized access to the applicable beta build and its Dart or Flutter dependencies.

The [size probe](evaluation/probe.dart) uses generated document payloads and a temporary passphrase to measure protected package sizes. The [aggregate results](evaluation/results.json) also record the host test counts and observations from earlier legacy tests.

The measurements were made on Windows 11 with Flutter 3.47.7 and Dart 3.13.5. Mobile functional tests ran through the host test runner.
