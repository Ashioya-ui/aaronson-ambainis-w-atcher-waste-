# Comparator verification

The workflows for the publication repository are [Comparator](https://github.com/physical-superintelligence/aaronson-ambainis/actions/workflows/comparator.yml) and [Build Lean formalization](https://github.com/physical-superintelligence/aaronson-ambainis/actions/workflows/build-lean.yml). Each run records the checked commit. A new repository must run its own workflows; verification runs are not transferred with the files.

## Release preparation

The checks below ran on 6 November 2026 (UTC) as preparation for publication.
They checked commit `88bf443cbab819f89680bd617f0538e114eba9e4` in the
private staging repository. The captured outputs below are included in this repository;
readers do not need access to that staging repository or the private development archive.

The Lean-source digest is
`593eda9c5d897c139e9b797820498b001a6151d2e1d6e19371f6d2bb5b5261bd` (87 files).
The 121 inputs in [`archive-files.txt`](../archive-files.txt), including the Comparator
challenge and solution, also match the checked sources. The follow-up commit adds these
records and documentation; it does not change the proof inputs.

| Check | Run | Result | Captured output |
|---|---|---|---|
| Lean build | `42150538176` | Passed, 8790 build jobs | [Build output](../release/build-output.txt) |
| Axiom report | `42150538176` | Passed, 119 declarations; only `propext`, `Classical.choice` and `Quot.sound` | [Axiom report](../release/axiom-report.txt) |
| Kernel replay | `42150538176` | Passed, 84 modules | [Replay output](../release/kernel-replay.txt) |
| Static source audit | `42150538176` | Passed | [Source audit](../release/source-audit.json) |
| Sandboxed Comparator, four final theorems | `42150538313` | Passed: nanoda and Lean kernel accepted | [Theorem output](../release/comparator-theorems.txt) |
| Comparator controls | `42150538313` | Passed: the positive control accepted and all four negative controls rejected | [Control output](../release/comparator-controls.txt) |
| Release files and citation | `42150538274` | Passed on the checked commit | Checksums, publication links, PDF metadata and CFF schema |

The build and Comparator files are copies of the uploaded workflow artifacts. The replay
file is extracted from the kernel-replay step's log, with timestamps retained and GitHub's
runner headers omitted. The recorded step conclusions are in
[`workflow-results.json`](../release/workflow-results.json).

These are the genuine staging run URLs, retained as historical provenance. They remain
private; the captured outputs above are the accessible records. The publication repository
must run its own workflows to produce its own public run URLs and badges.

Private staging run (historical): https://github.com/physical-superintelligence/aaronson-ambainis-work/actions/runs/42150538176

Private staging run (historical): https://github.com/physical-superintelligence/aaronson-ambainis-work/actions/runs/42150538313

Private staging run (historical): https://github.com/physical-superintelligence/aaronson-ambainis-work/actions/runs/42150538274

## Historical sandboxed run (22 October 2026)

This is the record of the run of comparator on the four final theorems. It was made by the
workflow [`.github/workflows/comparator.yml`](../../.github/workflows/comparator.yml) on
machines hosted by GitHub. What comparator checks, and what a run does and does not show, is
described in [`comparator/README.md`](../../comparator/README.md).

| | |
|---|---|
| Workflow run | `39706217600`, started by hand, 22 October 2026, 01:31:54 to 01:52:04 UTC, conclusion `success` |
| Commit | `4cdf5250f41d01a288a1f1c4df084abb899e1abf` |
| Source digest at that commit | `593eda9c5d897c139e9b797820498b001a6151d2e1d6e19371f6d2bb5b5261bd` |
| Machines | two, one for each job, each started fresh for it: image `ubuntu-24.04`, version `20261018.339.1`; `Linux 7.0.0-1017-azure x86_64`; 2 cores; 7 GB of memory; user id 1001 |
| Landlock | among the active security modules: `lockdown,capability,landlock,yama,apparmor,ima,evm` |
| Tools | comparator `71b52ec29e06d4b7d882726553b1ceb99a2499e0`, lean4export `15f6055e299ad5b89345e533cc2192f4cc00f659`, nanoda `68d5ca9db226849b41a6fff59d796ff19d0a8840`, landrun `v0.1.16-0.20251001204025-5ed4a3db3a4a`: the revisions of [`comparator/PINS.env`](../../comparator/PINS.env) |
| Lean | 4.33.0 for the project and for lean4export; comparator itself built with `leanprover/lean4:v4.30.0-rc2` |

The original run is retained in the private development archive under run ID
`39706217600`. Its recorded outputs are included below; the archive URL is not a
public verification link.

### The job `theorems`

1. The test of the sandbox (`scripts/check_sandbox.sh`), before anything of the project was
   built:

       check_sandbox.sh: a write to a directory declared writable succeeded (as it must)
       check_sandbox.sh: a write outside the declared directories was refused (as it must)
       check_sandbox.sh: the sandbox holds

2. `lake exe cache get`, 01:36:05 to 01:39:17.
3. `make comparator`, 01:39:17 to 01:51:53. Comparator built the challenge (8707 jobs) and the
   solution (8780 jobs) in the sandbox, exported both, and ended with

       Running nanoda kernel on solution
       Nanoda kernel accepts the solution
       Running Lean default kernel on solution.
       Lean default kernel accepts the solution
       Your solution is okay!
       Finished with result: success
       Main processes terminated with: code=exited/status=0
       Service runtime: 12min 36.699s
       CPU time consumed: 10min 51.142s

4. The step `Verdict` of the workflow found the line `Your solution is okay!` in the output.

The whole output of step 3 is [`theorems-output.txt`](theorems-output.txt).

### The job `controls`

On the other machine, after the same test of the sandbox (with the same three lines),
`make comparator-controls` gave:

| Configuration | Result | Message |
|---|---|---|
| `accept` | accepted, exit status 0 | `Your solution is okay!` |
| `reject-other-statement` | rejected, exit status 1 | `Challenge and solution theorem statement do not match: 'Ctl.goodTop'` |
| `reject-axiom` | rejected, exit status 1 | `Illegal axiom detected: 'Ctl.extra'` |
| `reject-false-proof` | rejected, exit status 1 | `Running nanoda kernel on solution`, then `Child exited with 101` |
| `reject-false-proof-lean-kernel` | rejected, exit status 1 | `(kernel) declaration type mismatch, 'Ctl.bad' has type True but it is expected to have type False` |

The output is [`controls-output.txt`](controls-output.txt).

### The runs without the sandbox

The same checks were also made without the sandbox, on two rented machines whose kernel has
no Landlock; these are the machines F and G of
[`notes/VERIFICATION.md`](../../notes/VERIFICATION.md), where the two runs are described.
Their outputs are [`unsandboxed-theorems-output.txt`](unsandboxed-theorems-output.txt) and
[`unsandboxed-controls-output.txt`](unsandboxed-controls-output.txt). Such runs test the
setup and certify nothing.

### What to keep in mind

* Each job runs on a machine that is started for it. Before comparator ran, only the four
  tools were built there and the compiled Mathlib was fetched; nothing of this repository had
  been compiled on the machine.
* The user of such a machine is not root, but it may use `sudo` without a password. The
  README of comparator asks that the run be made by an unprivileged user.
* The line `Memory peak` at the end of the outputs is the figure that systemd prints for its
  transient unit. It is far below the memory that Lean needs to load Mathlib and is not a
  measure of the memory of the run.
* The outputs of the sandboxed run were copied from the files that the workflow uploads; they
  contain no terminal escape sequences. The output of the run without the sandbox on the
  theorems was recorded on a pseudo-terminal; escape sequences and the progress lines of
  `lake`, which a terminal overwrites, are removed in it.
