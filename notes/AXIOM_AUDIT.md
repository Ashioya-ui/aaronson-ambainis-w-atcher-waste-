# Axiom audit

This note records on which axioms the final theorems depend, how that was checked, and what
the checks do and do not establish. The commands and the recorded runs are in
[`VERIFICATION.md`](VERIFICATION.md).

## Source audit

`make audit` runs `scripts/check_no_placeholders.py`. It reads every `.lean` file below
`AaronsonAmbainis/` and the root file, removes comments and string literals, and searches the
remaining code for

* unfinished proofs: `sorry`, `admit`, `stop`;
* declarations accepted without proof: `axiom`, `opaque`, `constant`;
* ways around the kernel: `native_decide`, `ofReduceBool`, `ofReduceNat`, `implemented_by`,
  `extern`, `unsafe`, `partial`, `csimp`, `skipKernelTC`, `addDeclWithoutChecking`;
* new syntax, and code that runs while a file is elaborated: `run_cmd`, `run_elab`,
  `run_meta`, `elab`, `elab_rules`, `macro`, `macro_rules`, `syntax`, `declare_syntax_cat`,
  `notation`, `infix`, `infixl`, `infixr`, `prefix`, `postfix`, `initialize`,
  `builtin_initialize`;
* changes of an option of Lean: `set_option`.

Result: 86 files, and no occurrence in the 84 files of the library. The other two files are
the comparator modules, and the challenge among them, `Comparator/Challenge.lean`, contains
`sorry` four times. These are the open proofs of which a comparator challenge consists (see
[`../comparator/README.md`](../comparator/README.md)). The script is told to expect exactly
four in that file, and `make imports` checks that no file of the library imports it. The
report is [`source-audit.json`](source-audit.json).

`make count` reads the compiled library instead of the source text. It finds 761 constants
in the 84 modules, counting those that Lean generates itself: 113 definitions and 648
theorems. There is no axiom, no opaque constant, no inductive type, and no constant marked
`unsafe` or `partial`.

## Kernel dependency report

`make axioms` elaborates `AaronsonAmbainis/AxiomReport.lean`, which prints the axioms of 119
named results of the library, and `scripts/check_axioms.py` checks the output. Each of the 119
depends on

    propext, Classical.choice, Quot.sound

and on nothing else. (The script accepts a result whose axioms are among these three; in the
recorded report each of the 119 depends on all three.) They are the three axioms of Lean's
core library on which Mathlib is built: propositional extensionality, the axiom of choice, and the soundness of quotients. For
the four final theorems of `Main.lean`:

| Theorem | Statement | Axioms |
|---|---|---|
| `aaronson_ambainis` | `PrintedConjecture` | `propext`, `Classical.choice`, `Quot.sound` |
| `aaronson_ambainis_explicit` | `ExplicitBound` | `propext`, `Classical.choice`, `Quot.sound` |
| `aaronson_ambainis_pm` | `ExplicitBoundPM` | `propext`, `Classical.choice`, `Quot.sound` |
| `aaronson_ambainis_of_fbsDegreeBound` | `FbsDegreeBound → ExplicitBoundImproved` | `propext`, `Classical.choice`, `Quot.sound` |

No result depends on `sorryAx`, and the library declares no axiom of its own. The output of
the run recorded for this release is
[`../verification/axiom-report.txt`](../verification/axiom-report.txt).

## What an axiom report does not show

An axiom report is only as reliable as the compiled files that it reads. Lean has an option
that switches the kernel off while a declaration is added, and a declaration added in this
way is reported as depending on no axiom. The control described in `VERIFICATION.md` shows
this on a small example: `lake build` accepts a "proof" of `False`, and `#print axioms`
reports no axiom for it. The source audit above excludes that option for this library, but
the source audit is a search of the text.

The stronger check is a replay, in which every declaration is passed again to a kernel that
re-checks its proof term:

* `make replay` runs Lean's `leanchecker` on the 84 modules of the library;
* `make replay-fresh` runs it from an empty environment on everything on which `Main.lean`
  depends, Lean core and Mathlib included;
* the same two replays were run with `lean4lean`, an implementation of the type checker that
  is independent of the one in Lean.

Both checkers reject the control. The results are in `VERIFICATION.md`.

Comparator makes a check of another kind. Its challenge file imports nothing but
`Conjecture.lean` and states the four final theorems without proof. Comparator checks that
the library proves exactly these statements from the three axioms, and it has the proofs
replayed by nanoda, a type checker written in Rust, and by a Lean kernel. A sandboxed run on
a machine hosted by GitHub accepted the four theorems, nanoda included, and a second machine
ran the controls. The runs are recorded in `VERIFICATION.md` and in
[`../verification/comparator/README.md`](../verification/comparator/README.md).

## Verification boundary

The machine checks establish that the terms named in `Main.lean` are proofs, accepted by two
kernels, of the propositions defined in `Conjecture.lean`, from the three axioms above.

They do not establish the following.

1. That `PrintedConjecture` says what the conjecture says. This is decided by reading its
   definition (16 lines, written with Mathlib only) against the printed statement, which is
   quoted in [`../problem_statement.md`](../problem_statement.md).
2. That the kernel of Lean, its file format, and the definitions of Mathlib that occur in
   the statement (`MvPolynomial`, finite sums, the real numbers) are correct. `lean4lean`
   uses Lean's own loader for compiled files and Lean's runtime, so it is independent of
   Lean only in the type checking itself.
3. Anything about the paper. The paper is a separate text. The correspondence in
   [`PAPER_TO_LEAN.md`](PAPER_TO_LEAN.md) is a guide for the reader; no machine has checked
   it.

## A hypothesis that is not an axiom

`aaronson_ambainis_of_fbsDegreeBound : FbsDegreeBound → ExplicitBoundImproved` is an
implication. Its hypothesis is the bound of Agarwal and Ben-David (arXiv:2410.19062, Theorem
1.7). It is not proved in this library, and it is assumed nowhere else: the other three final
theorems do not mention it, and it is not declared as an axiom.
