# Recorded outputs of the checks

Start with the [release-preparation checks](comparator/README.md#release-preparation)
for the latest build, axiom, kernel-replay and Comparator results and their copied outputs.
The October 22 records described below are retained as historical evidence.

The files in this directory are the outputs of checks on this release's Lean sources.
They are records, not inputs: nothing in the library reads them. The first three can be
produced again with the command in the second column; the others are the list of the files
that the recorded runs received, the reports of these runs, and the files of the control. How to read them, and what each check
establishes, is explained in [`../notes/VERIFICATION.md`](../notes/VERIFICATION.md) and
[`../notes/AXIOM_AUDIT.md`](../notes/AXIOM_AUDIT.md).

| File | Produced by | Content |
|---|---|---|
| [`source-digest.txt`](source-digest.txt) | `python3 scripts/source_digest.py . AaronsonAmbainis --list` | the SHA-256 digest of each of the 87 files that determine the library, and one digest of the list |
| [`axiom-report.txt`](axiom-report.txt) | `make axioms` | the types of the final theorems, of the links of the proof and of the implications between them (47 lines), and the axioms of 119 named results |
| [`declaration-count.txt`](declaration-count.txt) | `make count` | the constants of the 84 compiled modules, by kind |
| [`archive-files.txt`](archive-files.txt) | written when the archive for the recorded runs was made | the SHA-256 digest of each of the 121 files that the recorded runs received |
| [`replay-log.txt`](replay-log.txt) | copied from the reports of the recorded runs | for every recorded run: the machine, the commands, the exit statuses and the times; for the long replays also the peak memory |
| [`comparator/`](comparator/) | the workflow `.github/workflows/comparator.yml` | the record of the sandboxed comparator run on the four final theorems and of its controls, with the two outputs; also the two outputs of the runs without the sandbox |
| [`control/`](control/) | | a small project that a build accepts and a replay must reject, and five small comparator runs, of which comparator must reject four |

The report of the static audit of the sources is
[`../notes/source-audit.json`](../notes/source-audit.json); `make audit` writes it there.

All records belong to the sources with the digest

    593eda9c5d897c139e9b797820498b001a6151d2e1d6e19371f6d2bb5b5261bd
