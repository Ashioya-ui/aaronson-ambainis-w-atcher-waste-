# Verification

For the latest release-preparation checks, start with
[`verification/comparator/README.md`](../verification/comparator/README.md#release-preparation).
It records the checked commit and source digest, with the new build, axiom, kernel-replay
and Comparator outputs copied into this repository. Reading those outputs does not require
access to the private staging repository.

This note gives the reproduction commands, explains each check, and retains the additional
checks performed on 22 October 2026 as historical records. What the checks do not establish
is discussed in [`AXIOM_AUDIT.md`](AXIOM_AUDIT.md).

## Pinned versions

| Component | Version | Pinned in |
|---|---|---|
| Lean | 4.33.0 (`lean --version` reports commit `d8b18978322de05a8f3dba51ef03cf5461676c17`) | `lean-toolchain` |
| Mathlib | tag `v4.33.0`, commit `db584cd6d46c92f209a44c0f1c829460d327499d` | `lakefile.toml`, `lake-manifest.json` |
| the dependencies of Mathlib | the revisions in the manifest | `lake-manifest.json` |
| comparator, lean4export, landrun, nanoda | the revisions in `PINS.env` | `comparator/PINS.env` |
| lean4lean | commit `8223d223ed98661882e95d9d6a7126df7097cd76` | this note |

## Commands

```bash
lake exe cache get    # download the compiled Mathlib (otherwise Mathlib is compiled, which takes hours)
make check            # = make imports, make audit, lake build, make axioms
make replay           # kernel replay of the 84 modules of the library
make replay-fresh     # kernel replay of everything behind Main.lean, from an empty environment
make count            # the constants of the compiled library, by kind
make digest           # one SHA-256 digest of the Lean sources and the pins
make comparator       # comparator on the four final theorems (Linux only; see "Comparator" below)
```

| Target | What it runs | What it shows |
|---|---|---|
| `make imports` | `scripts/check_local_imports.py` | every local import resolves, every file of the library is reached from the root file, `Conjecture.lean` imports only `Mathlib`, no file of the library imports a comparator module, and the comparator challenge imports only `Conjecture.lean` |
| `make audit` | `scripts/check_no_placeholders.py` | the source text contains none of the constructs listed in `AXIOM_AUDIT.md`, apart from the four open proofs of the comparator challenge |
| `lake build` | Lean | every file is elaborated and every declaration is accepted by the kernel at that moment |
| `make axioms` | `AxiomReport.lean`, `scripts/check_axioms.py` | the axioms on which 119 named results depend |
| `make replay` | `leanchecker -v AaronsonAmbainis` | every declaration of the 84 compiled modules is accepted again by the kernel, on top of the imports as they are |
| `make replay-fresh` | `leanchecker --fresh AaronsonAmbainis.Main` | every declaration behind `Main.lean` (Lean core, Mathlib and 74 modules of the library) is accepted by the kernel, starting from an empty environment |
| `make count` | `scripts/count_declarations.lean` | how many constants the compiled library has, and of which kinds |
| `make digest` | `scripts/source_digest.py` | a digest that identifies the sources that were checked |
| `make comparator` | `scripts/run_comparator.sh` | comparator, in its sandbox, accepts the four final theorems |
| `make comparator-controls` | `scripts/run_comparator_controls.sh` | comparator, in its sandbox, accepts one small correct solution and rejects four wrong ones |
| `make comparator-unsandboxed` | `scripts/run_comparator_unsandboxed.sh` | the same checks as `make comparator` with the sandbox removed: a test of the setup, not a comparator run |

`make replay-fresh` does not rely on the downloaded Mathlib being honest: the compiled files
are only read, and every declaration in them is checked again.

`make replay` covers 84 modules in a checkout in which only `lake build` has run. A comparator
run also compiles the two comparator modules, and `make replay` then covers 86.

`make replay` starts one replay task for each module, and each task loads the imports of
its module. How many tasks run at a time is left to Lean unless `LEAN_NUM_THREADS` is set,
and the memory grows with that number: on machine A below, which has 8 cores, the replay
used 173.3 GB. On a machine with little memory, replay the modules one after the other:
`LEAN_NUM_THREADS=1 make replay` (7.4 GB on machine A; with four tasks at a time, 28.8 GB on
machine F).

## The source digest

`make digest` computes the SHA-256 digest of each of the 87 files that determine the
library (the 84 `.lean` files, `lakefile.toml`, `lake-manifest.json` and `lean-toolchain`)
and one digest of the list. For this release:

    593eda9c5d897c139e9b797820498b001a6151d2e1d6e19371f6d2bb5b5261bd

The list is [`../verification/source-digest.txt`](../verification/source-digest.txt). Every
run recorded below was made on sources with this digest. A comment counts: after any change
to a `.lean` file the digest changes and the runs have to be repeated.

The two comparator modules are not among the 87 files. No file of the library imports them,
so they cannot change what the library proves.

## Historical runs (22 October 2026)

Commit `4cdf525` and run IDs `39706215016` and `39706217600` below identify runs in
the private development archive. They are historical identifiers, not public links. The
archived commit and this release have the same Lean-source digest above; all 121 inputs in
[`verification/archive-files.txt`](../verification/archive-files.txt) also match this release.
The copied historical outputs and the new release-preparation records are available here
without opening the archive. Matching hashes identify the checked inputs; the outputs record
what the checkers reported.

The runs were made on 22 October 2026: on machines A to G between 01:31 and 02:30 UTC, one
machine for each job and a second machine for each of the jobs B and C, and on machines of
kind H between 01:31 and 01:53 UTC. All times below are UTC.

* **A** to **E**: five rented Linux containers (x86_64, 8 cores), Lean 4.33.0 for
  `x86_64-unknown-linux-gnu`. Each started with no Lean files at all: the toolchain was
  installed by elan, the sources arrived as an archive, the job computed their digest (the
  value above, on each of the five) and fetched the compiled Mathlib with
  `lake exe cache get`. The memory asked for was 128 GB for A and D and 64 GB for B, C and
  E. This is a reservation and not a limit, and one step on A used more.
* **F**, **G**: two more containers of the same kind (8 cores; 96 and 32 GB asked for),
  started from an image that holds Lean 4.33.0 and the four tools of a comparator run, built
  at the revisions of `comparator/PINS.env`. The sources arrived as the same archive.
  Nothing of this repository had been compiled on these machines.
* **H**: machines hosted by GitHub for the workflows of this repository (image
  `ubuntu-24.04`, version `20261018.339.1`, x86_64), a fresh one for each job, working on a
  checkout of commit `4cdf525`. The two machines of the comparator workflow report 2 cores
  and 7 GB of memory.

The platform on which the containers ran stopped the first containers of jobs B and C (a
pre-emption) while the replays of the two jobs were running, and started both jobs again from
the beginning, on new containers of the same kind: job C at 01:54:52 and job B at 01:54:53.
The first starts of jobs B and C had begun at 01:31:42 and had passed `make digest`,
`lake exe cache get` and `lake build` with exit status 0; the two replays had not ended when
the containers were stopped and gave no result. The tables for B and C below show the second
starts.

Machines A to G report the kernel `Linux 4.19.0-gvisor` (gVisor), and their jobs ran as the
user root. "Peak memory" is the largest resident memory that the operating system recorded
for one process of the command, in units of 2^30 bytes.

**Machine A**: the build, the checks and the kernel replay of the library (job from 01:31:40
to 01:57:03).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `lake exe cache get` | 0 | 122 s | |
| `make check` | 0 | 124 s | its four parts are the next four lines |
| `make imports` | | | 84 modules, 2 comparator modules, 0 errors |
| `make audit` | | | 86 files, 0 findings, the 4 permitted open proofs |
| `lake build` | | 117 s | the 84 modules of the library built; no warning, no error |
| `make axioms` | | 7 s | 119 declarations reported, 0 errors; each depends on `propext`, `Classical.choice`, `Quot.sound` and on nothing else |
| `make count` | 0 | 22 s | 761 constants in 84 modules: 113 definitions, 648 theorems, no axiom; none unsafe or partial |
| `make replay` | 0 | 428 s | 84 modules; peak memory 173.3 GB |
| the control | | | see "The control" below |
| `LEAN_NUM_THREADS=1 make replay` | 0 | 656 s | 84 modules; peak memory 7.4 GB |

`make check` stops at the first of its parts that fails, so its exit status 0 is that of each
part; the times of the parts are taken from the time stamps of its output. The file
`notes/source-audit.json` that `make audit` wrote on machine A is identical to the one in
this repository, and the file that `make axioms` wrote there is
`verification/axiom-report.txt`. On the 8 cores of this machine `make replay`, with the
number of replay tasks left to Lean, used more memory than the 128 GB asked for; with one
task at a time it used 7.4 GB.

**Machine B**: the kernel replay from an empty environment (job from 01:54:53 to
02:29:22, the second start of job B).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `lake exe cache get` | 0 | 155 s | |
| `lake build` | 0 | 151 s | the 84 modules of the library built; no warning, no error |
| `make replay-fresh` | 0 | 1742 s | no output from the checker; peak memory 8.7 GB |

**Machine C**: the same replay for the root file `AaronsonAmbainis.lean`. The root file
imports every module of the library, so that the ten modules that `Main.lean` does not
import are replayed from an empty environment as well (job from 01:54:52 to 02:27:52, the
second start of job C).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `lake exe cache get` | 0 | 139 s | |
| `lake build` | 0 | 148 s | the 84 modules of the library built; no warning, no error |
| `lake env leanchecker --fresh AaronsonAmbainis` | 0 | 1677 s | no output; peak memory 8.7 GB |

**Machine D**: the second kernel on every module of the library (job from 01:31:42 to
01:46:17; see "The second kernel" below).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `lake build lean4lean` | 0 | 26 s | |
| the control | | | see "The control" below |
| `lake exe cache get` | 0 | 107 s | |
| `lake build` | 0 | 121 s | the 84 modules of the library built; no warning, no error |
| `LEAN_NUM_THREADS=4 lean4lean -v AaronsonAmbainis` | 0 | 396 s | 84 modules; `checked 761 declarations`; peak memory 60.3 GB |

**Machine E**: the second kernel from an empty environment (job from 01:31:43 to
02:15:40).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `lake build lean4lean` | 0 | 34 s | |
| `lake exe cache get` | 0 | 136 s | |
| `lake build` | 0 | 146 s | the 84 modules of the library built; no warning, no error |
| `lean4lean --fresh AaronsonAmbainis.Main` | 0 | 2299 s | `checked 750881 declarations`; peak memory 9.0 GB |

**Machines F and G**: tests of the comparator setup; see "Comparator" below.

**Machine H**, workflow `build-lean.yml`: run `39706215016` on commit `4cdf525` (from 01:31:53 to
01:45:33, conclusion `success`).

| Command | Exit status | Time | Result |
|---|---|---|---|
| `make imports` | 0 | | 84 modules, 2 comparator modules, 0 errors |
| `make audit` | 0 | | 86 files, 0 findings, the 4 permitted open proofs |
| `lake exe cache get` | 0 | 128 s | |
| `lake build` | 0 | 371 s | the 84 modules of the library built; no warning, no error |
| `make axioms` | 0 | 7 s | 119 declarations reported, 0 errors; the report is identical to `verification/axiom-report.txt` |
| `LEAN_NUM_THREADS=1 make replay` | 0 | 285 s | 84 modules |

The file `notes/source-audit.json` that this run uploaded is identical to the one in this
repository.

**Machine H**, workflow `comparator.yml`: see "Comparator" below.

The seven jobs on machines A to G received the same archive of the sources. `make digest`
gave the value above on machines A to F; machine G ran the controls of the comparator run
only. Those historical workflows did not run `make digest`; the source manifest for
commit `4cdf525` gives the same value.

The archive held the 121 files that the jobs read: the 86 `.lean` files, the three files with
the pins, the Makefile, the 11 files of `scripts/`, `notes/source-audit.json`, two files of
`comparator/` (`config.json` and `PINS.env`) and the 17 files of `verification/control/`. In
this repository these files are the same. The list of the 121 files with their digests is
[`../verification/archive-files.txt`](../verification/archive-files.txt); the SHA-256 digest of
that list is the one that every job prints in its first lines.

The lines of the job reports behind these tables are in
[`../verification/replay-log.txt`](../verification/replay-log.txt).

## The control

A check that cannot fail shows nothing. The directory
[`../verification/control/`](../verification/control/) is a small project in which a constant
of type `False` is added while the kernel is switched off. `lake build` accepts it, and
`#print axioms` reports that it depends on no axiom. The replays reject it:

| Checker | Arguments | Exit status | Output |
|---|---|---|---|
| `leanchecker` | `-v Ctl.Good` | 0 | |
| `leanchecker` | `-v Ctl.Bad` | 1 | `(kernel) declaration type mismatch, 'Ctl.bad' has type True but it is expected to have type False` |
| `leanchecker` | `-v Ctl.Bad.Top` | 0 | |
| `leanchecker` | `--fresh Ctl.Good.Top` | 0 | |
| `leanchecker` | `--fresh Ctl.Bad.Top` | 1 | the same message |
| `lean4lean` | `Ctl.Good` | 0 | `checked 2 declarations` |
| `lean4lean` | `Ctl.Bad` | 1 | a type mismatch for `Ctl.bad`: `True` where `False` is expected |
| `lean4lean` | `--fresh Ctl.Good.Top` | 0 | `checked 63938 declarations` |
| `lean4lean` | `--fresh Ctl.Bad.Top` | 1 | the same mismatch |

The `leanchecker` lines are a run of the committed files on machine A, after the replay of the
library. The `lean4lean` lines were run on machine D, on the same files, in the same job as
the second-kernel replay of the library and before it. On both machines the control was
compiled in its own directory: `verification/control/` is a separate Lake project without
dependencies, its build writes only below the directory `.lake` of that project, and the
replays of the library read the compiled files of the library and of Mathlib and nothing of
the control. Unlike the comparator runs below, these runs did not keep the control on a
separate machine.

The third line shows that without `--fresh` a checker re-checks only the modules whose names
begin with the given prefix and takes their imports as they are: the false declaration sits
in an import of `Ctl.Bad.Top` and goes unnoticed. This is why `make replay` names the whole
library and why `make replay-fresh` exists.

## The second kernel

[lean4lean](https://github.com/digama0/lean4lean) is an implementation of Lean's type checker
written in Lean. It was built at commit `8223d223ed98661882e95d9d6a7126df7097cd76` with the
toolchain of this repository:

```bash
git clone https://github.com/digama0/lean4lean
git -C lean4lean checkout 8223d223ed98661882e95d9d6a7126df7097cd76
echo 'leanprover/lean4:v4.33.0' > lean4lean/lean-toolchain   # the checkout names v4.33.0-rc2
(cd lean4lean && lake build lean4lean)
```

Then, in this repository, after `lake build`:

```bash
ulimit -s unlimited
lake env /path/to/lean4lean/.lake/build/bin/lean4lean -v AaronsonAmbainis
lake env /path/to/lean4lean/.lake/build/bin/lean4lean --fresh AaronsonAmbainis.Main
```

The recorded run of the first command was made with `LEAN_NUM_THREADS=4` and used 60.3 GB of
memory (machine D); the second used 9.0 GB (machine E).

lean4lean reads the compiled files with Lean's own loader and runs on Lean's runtime. It is
independent of Lean's kernel in the type checking and in nothing else.

## Comparator

The setup, and what a comparator run does and does not show, is described in
[`../comparator/README.md`](../comparator/README.md). Two kinds of run have to be kept apart.
A *sandboxed* run (`make comparator`) is a comparator run in the sense of its authors. An
*unsandboxed* run (`make comparator-unsandboxed`) makes the same checks with nothing confined,
and it certifies nothing.

### Historical sandboxed run (machine H, 22 October 2026)

The workflow `comparator.yml` ran on commit `4cdf525` (run `39706217600`, from 01:31:54 to
01:52:04, conclusion `success`), with its two jobs on two machines.

| Job | Step | Result |
|---|---|---|
| `theorems` | `scripts/check_sandbox.sh` | `the sandbox holds`: a write outside the declared directories was refused |
| `theorems` | `make comparator`, 01:39:17 to 01:51:53 | `Nanoda kernel accepts the solution`, `Lean default kernel accepts the solution`, `Your solution is okay!`; exit status 0 |
| `controls` | `scripts/check_sandbox.sh` | `the sandbox holds` |
| `controls` | `make comparator-controls` | all five controls ended as they must: one accepted and four rejected, each with the output that the script requires for it |

The record of this run, with the machines, the revisions of the tools and the outputs, is
[`../verification/comparator/README.md`](../verification/comparator/README.md#historical-sandboxed-run-22-october-2026).

What this run shows is stated in `comparator/README.md` under "What a run shows". One point
of comparator's own assumptions is not met in full: the user of a GitHub-hosted machine is
not root, but it may use `sudo` without a password.

### The runs without the sandbox (machines F and G)

Machines F and G cannot give a comparator run: their kernel has no Landlock, and their jobs
run as root. They were used to test the whole setup with
`landrun` replaced by `scripts/fake_landrun.sh`: F for the four final theorems and G for
the controls, so that the controls, one of which compiles a false declaration, were never
compiled on the machine that judged the theorems. Each job compared the revisions of
comparator, lean4export, landrun and nanoda in its image with `comparator/PINS.env`. Job F
(from 01:31:44 to 01:49:20) ran, in this order:

| Step | Exit status | Time | Result |
|---|---|---|---|
| `make digest`, `make imports`, `make audit` | 0, 0, 0 | | as stated above |
| `scripts/check_sandbox.sh`, with the real `landrun` | 1 | | `a write outside the declared directories SUCCEEDED: there is no sandbox here` |
| `make comparator` | 2 | | `comparator must not be run by a privileged user` |
| `lake exe cache get` | 0 | 144 s | |
| `make comparator-unsandboxed`, started 01:34:12 | 0 | 287 s | `Your solution is okay!` |
| `lake build` | 0 | 42 s | the ten modules of the library that the comparator run had not compiled |
| `LEAN_NUM_THREADS=4 make replay` | 0 | 579 s | 86 modules: the 84 of the library and the two comparator modules; peak memory 28.8 GB |

The parts of the fifth step, in seconds from its start:

| Part | From | To |
|---|---|---|
| build of the challenge | 2 | 27 |
| export of the challenge | 27 | 39 |
| build of the solution (this compiles the modules of the library behind `Main.lean`) | 39 | 173 |
| export of the solution | 173 | 212 |
| nanoda: `Nanoda kernel accepts the solution` | 212 | 241 |
| the Lean kernel: `Lean default kernel accepts the solution` | 241 | 287 |

The largest resident memory of one process, sampled every 3 seconds, was 7.8 GB
(`lean4export` during the export of the solution; `lean` reached 7.7 GB during the build of
the solution).

Job G (from 01:31:44 to 01:32:19) ran `scripts/check_sandbox.sh`, with the same result as on
F, and then `scripts/run_comparator_controls.sh --unsandboxed` (exit status 0, 29 s):

| Configuration | Result | Output that decides |
|---|---|---|
| `accept` | accepted, exit status 0 | `Your solution is okay!` |
| `reject-other-statement` | rejected, exit status 1 | `Challenge and solution theorem statement do not match: 'Ctl.goodTop'` |
| `reject-axiom` | rejected, exit status 1 | `Illegal axiom detected: 'Ctl.extra'` |
| `reject-false-proof` | rejected, exit status 1 | nanoda stops with an error (`Child exited with 101`) |
| `reject-false-proof-lean-kernel` | rejected, exit status 1 | `(kernel) declaration type mismatch, 'Ctl.bad' has type True but it is expected to have type False` |

One more observation from job G. With the real `landrun` on this kernel, comparator on
the configuration `accept` ended with `Your solution is okay!` and exit status 0 as well,
although nothing was confined. This is the reason for `scripts/check_sandbox.sh`: comparator
itself does not notice a missing sandbox.

What these runs show: the setup works, comparator rejects the four wrong solutions at the
intended checks, and on an honest machine the four final theorems pass every check that
comparator makes. The statements of the solution are those of the challenge, the axioms are
the permitted three, and nanoda and the Lean kernel inside comparator accept the proofs.

Why they are no certificate: nothing was sandboxed, and the user was root.

The outputs of these two runs are
[`../verification/comparator/unsandboxed-theorems-output.txt`](../verification/comparator/unsandboxed-theorems-output.txt)
and
[`../verification/comparator/unsandboxed-controls-output.txt`](../verification/comparator/unsandboxed-controls-output.txt).

## Checksums

`SHA256SUMS` lists the SHA-256 digest of every file of the release, and `paper/SHA256SUMS`
those of the paper. Check them with `shasum -a 256 -c SHA256SUMS`.

## Limits of these records

All runs recorded above were made by the author's own tooling, on rented machines, or by the
workflows of this repository. None has been repeated by another party.
