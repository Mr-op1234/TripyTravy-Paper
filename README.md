# TripyTravy paper

Open [main.pdf](main.pdf) for the compiled IEEE conference-format manuscript. It specifies the intended stable Creator and Viewer workflows and reports the results obtained from the available beta and the standalone Rust container prototype. The entry point is [main.tex](main.tex). The author block is in [sections/authors.tex](sections/authors.tex), and references are in [references.bib](references.bib) and [literature.bib](literature.bib). [Literature analysis](literature-analysis.md) records each scholarly source and its relevance. Replace the three coauthor labels with the confirmed details before submission.

## Build

From this directory, run either command with its corresponding TeX distribution installed.

~~~powershell
latexmk -pdf -halt-on-error main.tex
tectonic main.tex
~~~

On Overleaf, upload the LaTeX sources, bibliography, and figures, then select main.tex as the main document. The build uses the IEEEtran class, BibTeX, and TikZ.

## Reproduce the evaluation

From the TripyTravy application repository, use commit 65db5df with the revision-handling changes present in the evaluated worktree. A clean checkout of that commit alone predates those changes. From a clean checkout, apply evaluation/tripytravy-revisions.patch from the paper directory with git apply. The patch records the exact application worktree changes included in the tests. Install the Dart and Flutter package dependencies before testing.

~~~powershell
Push-Location apps/agent_desktop
flutter test
Pop-Location

Push-Location apps/client_mobile
flutter test
Pop-Location

Push-Location packages/tripytravy_core
dart test
Pop-Location

cargo test --workspace
dart --packages=packages/tripytravy_core/.dart_tool/package_config.json ../TripyTravy-Paper/evaluation/probe.dart Kashmir/Kashmir-Latest.tt
~~~

The probe prints sizes in bytes and runs the metadata mutation check. Omit the Kashmir path to run only the generated fixtures. The original trip export stays in the application workspace. The paper folder includes aggregate results in evaluation/results.json. The SHA-256 of the Kashmir fixture was AED31251054D574A89D3AC1545F41E53A6EB56170C2D51E182A7C0B4677AA8C8.

The measurements were made on Windows 11 with Flutter 3.47.7 and Dart 3.13.5. Mobile functional tests ran through the host test runner.
