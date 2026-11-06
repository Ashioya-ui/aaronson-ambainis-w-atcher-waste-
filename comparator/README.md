# Comparator

[Comparator](https://github.com/leanprover/comparator) is a judge for Lean proofs. It is given two modules. The *challenge* states theorems and leaves their proofs open. The *solution* proves theorems of the same names. Comparator builds both, and it accepts if, for every theorem named in its configuration,

1. the statement in the solution is the statement in the challenge, down to every constant on which the statement depends;
2. the proof uses no axiom outside a list of permitted axioms;
3. the declarations on which the theorem depends are accepted by the Lean kernel and, if enabled, by [nanoda](https://github.com/ammkrn/nanoda_lib), a type checker for Lean written in Rust.

It does not read compiled Lean files. Each module is built inside a sandbox ([landrun](https://github.com/zouuup/landrun), which uses Linux Landlock), so that building the solution cannot change the challenge or the tools. Each environment is then written out as text by [lean4export](https://github.com/leanprover/lean4export), and comparator works on the two exports.

The point of the tool is the separation of the two sides. A reader who trusts the challenge does not have to read the solution.

## The two sides here

| | file | imports | content |
|---|---|---|---|
| challenge | [`AaronsonAmbainis/Comparator/Challenge.lean`](../AaronsonAmbainis/Comparator/Challenge.lean) | [`AaronsonAmbainis/Conjecture.lean`](../AaronsonAmbainis/Conjecture.lean) and nothing else | the four final theorems, each with `sorry` as its proof |
| solution | [`AaronsonAmbainis/Comparator/Solution.lean`](../AaronsonAmbainis/Comparator/Solution.lean) | `AaronsonAmbainis/Main.lean` | the same four theorems, each proved by the theorem of the same name in `Main.lean` |

`Conjecture.lean` imports Mathlib only. So the challenge side consists of Mathlib, the five definitions of `Conjecture.lean`, and four statements; no proof of the library is on it.

The four theorems, in the namespace `AaronsonAmbainisComparator`:

| theorem | statement |
|---|---|
| `aaronson_ambainis` | `AaronsonAmbainis.PrintedConjecture` |
| `aaronson_ambainis_explicit` | `AaronsonAmbainis.ExplicitBound` |
| `aaronson_ambainis_pm` | `AaronsonAmbainis.ExplicitBoundPM` |
| `aaronson_ambainis_of_fbsDegreeBound` | `AaronsonAmbainis.FbsDegreeBound → AaronsonAmbainis.ExplicitBoundImproved` |

The configuration is [`config.json`](config.json): the two modules, the four names, the permitted axioms `propext`, `Quot.sound`, `Classical.choice`, and nanoda enabled.

No file of the library imports the two comparator modules, and `make imports` checks this. They are not among the 87 files of the source digest. The challenge is the only file under `AaronsonAmbainis/` with open proofs; `make audit` permits exactly its four.

## What a run shows

If a sandboxed run ends with the line `Your solution is okay!`, then each of the four theorems of the solution

- proves the statement written in the challenge, with the definitions of `Conjecture.lean` and of Mathlib that the challenge sees;
- depends on no axiom other than `propext`, `Quot.sound`, `Classical.choice`;
- is accepted, with everything it depends on, by nanoda and by the Lean kernel.

What a run does not show:

- **That the statement is the conjecture.** Comparator compares the solution with the challenge. Whether `PrintedConjecture` says what the conjecture says is for a reader to decide; see [`problem_statement.md`](../problem_statement.md).
- **Anything about declarations outside the four theorems.** Comparator exports and replays the four theorems and what they depend on. The other declarations of the library, among them those of the 10 modules that `Main.lean` does not import, are covered by `make replay`.

What a run takes on trust (the first six items are the assumptions listed in the README of comparator):

- the challenge, the files it imports, and the Lake files of this repository; this includes Mathlib and the other dependencies at the revisions of `lake-manifest.json`, and the compiled Mathlib files fetched by `lake exe cache get`, which comparator's README permits "if you trust the cache";
- that the solution was not compiled on the machine before the run;
- that `landrun` and `lean4export` are the tools on `PATH`;
- that `landrun` confines a process on the machine, and that the solution does not exploit an error in it;
- that at least one of the two checkers, the Lean kernel or nanoda, is correct;
- that the run is not made by a privileged user;
- `lean4export`: both checkers see the solution only through its export, so an export that differs from the environment would not be noticed by them. (The statements are compared on the exports of both sides, which come from the same tool.)

## Pinned tools

The revisions are in [`PINS.env`](PINS.env).

| tool | repository | revision | committed |
|---|---|---|---|
| comparator | `leanprover/comparator` | `71b52ec29e06d4b7d882726553b1ceb99a2499e0` | 29 April 2026 |
| lean4export | `leanprover/lean4export` | `15f6055e299ad5b89345e533cc2192f4cc00f659` | 10 August 2026 |
| landrun | `zouuup/landrun` | `5ed4a3db3a4ad930d577215c6b9abaa19df7f99f` | 1 October 2025 |
| nanoda | `robsimmons/nanoda_lib` | `68d5ca9db226849b41a6fff59d796ff19d0a8840` | 4 March 2026 |

Four facts about these tools that a reader of a run should know.

- **Comparator's kernel is not the kernel that built the library.** Comparator is built with the toolchain named in its own `lean-toolchain` file, which at this revision is `leanprover/lean4:v4.30.0-rc2`, and the Lean libraries are linked into the binary. Its replay therefore runs the kernel of that release on declarations that Lean 4.33.0 elaborated. `make replay` runs the kernel of Lean 4.33.0.
- **lean4export is built with the toolchain of this project**, because it has to load the files that this toolchain compiled.
- **nanoda is taken from a fork.** `robsimmons/nanoda_lib` is a fork of `ammkrn/nanoda_lib`.
- **The comparator revision is not the newest.** Later revisions exist; this setup has not been tried with them. One difference matters for the way comparator is called here and is described under "The sandbox" below.

## How to run it

A run needs Linux with Landlock, a systemd user session, an unprivileged user, and a fresh checkout of this repository in which nothing has been built. Go and Rust are needed to build two of the tools.

```bash
. comparator/PINS.env

go install "github.com/zouuup/landrun/cmd/landrun@${LANDRUN_REV}"        # -> $(go env GOPATH)/bin

git clone https://github.com/leanprover/lean4export.git ../lean4export
git -C ../lean4export checkout "$LEAN4EXPORT_REV"
cp lean-toolchain ../lean4export/lean-toolchain
(cd ../lean4export && lake build lean4export)                            # -> .lake/build/bin

git clone https://github.com/leanprover/comparator.git ../comparator
git -C ../comparator checkout "$COMPARATOR_REV"
(cd ../comparator && lake build comparator)                              # -> .lake/build/bin

git clone https://github.com/robsimmons/nanoda_lib.git ../nanoda_lib
git -C ../nanoda_lib checkout "$NANODA_REV"
(cd ../nanoda_lib && cargo build --release --locked)                     # -> target/release
```

With the four directories on `PATH`:

```bash
lake exe cache get
make comparator
```

`make comparator` runs [`scripts/run_comparator.sh`](../scripts/run_comparator.sh). The run builds the challenge and the solution, so it compiles the library; allow the time of `lake build` on top of the checks.

The workflow [`.github/workflows/comparator.yml`](../.github/workflows/comparator.yml) does all of this on a fresh machine.

## The sandbox

Two things in `scripts/run_comparator.sh` go beyond calling comparator.

**A test that the sandbox exists.** Comparator calls `landrun` with the flag `--best-effort`. With this flag, `landrun` on a kernel without Landlock does not stop: it runs the command unconfined. Comparator then reports success as on any other machine. [`scripts/check_sandbox.sh`](../scripts/check_sandbox.sh) therefore runs first. It calls `landrun` with comparator's flags on two writes, one into a directory declared writable and one into a directory not declared, and it stops the run unless the first succeeds and the second is refused.

**The wrapper `systemd-run --property=RestrictAddressFamilies=~AF_UNIX`.** The README of comparator at the pinned revision does not mention it. The README of its current revision (`fd5d5bcf14177b187f66d4502071268d877887c3`, 24 September 2026) asks for comparator to be started in this way, and gives as the reason a weakness of landrun's sandbox that this property of systemd closes (and that, according to that README, Linux 7.1 will fix). The script follows the current README.

## The controls

A check that never fails shows nothing. [`verification/control/`](../verification/control/) holds five small runs, one that comparator must accept and four that it must reject:

| run | what is wrong | what must reject it |
|---|---|---|
| `accept` | nothing | (accepted) |
| `reject-other-statement` | the solution proves `2 + 2 = 4 ∧ True`, the challenge states `2 + 2 = 5 ∧ True` under the same name | the comparison of the statements |
| `reject-axiom` | the solution proves the statement from a new axiom | the list of permitted axioms |
| `reject-false-proof` | the solution proves `1 = 2` from a constant of type `False` that was added with the kernel switched off | nanoda |
| `reject-false-proof-lean-kernel` | the same, with nanoda disabled | the Lean kernel |

`make comparator-controls` runs them through the sandbox and requires each rejection to come with the message of its own reason, so that a run which merely fails to start does not pass for a rejection. The last two are the comparator form of the control for the kernel replay described in [`verification/control/README.md`](../verification/control/README.md): `lake build` accepts that solution, and its axiom report is empty.

## Without the sandbox

`make comparator-unsandboxed` runs the same comparator, on the same configuration, with `landrun` replaced by [`scripts/fake_landrun.sh`](../scripts/fake_landrun.sh), which runs each step unconfined. Everything else is real: both builds, both exports, the comparison of the statements, the axiom check, nanoda, and the kernel replay. `scripts/run_comparator_controls.sh --unsandboxed` does the same for the controls.

Such a run tests the setup, and it shows that the four theorems pass these checks on an honest machine. It is not what comparator is for: without the sandbox, nothing separates the solution from the challenge while the solution is built. Only a run of `make comparator` counts as a comparator run.

## Recorded runs

The sandboxed run on the four final theorems, and its controls, are recorded in [`verification/comparator/README.md`](../verification/comparator/README.md). All recorded runs, with machines, dates and results, are in [`notes/VERIFICATION.md`](../notes/VERIFICATION.md).
