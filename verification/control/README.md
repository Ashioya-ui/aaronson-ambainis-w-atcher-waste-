# Controls for the kernel replay and for comparator

This directory is a separate, very small Lake project. It is not part of the library, and
nothing in the library imports it. Its purpose is to show that the replay used in this
repository can fail, and what a build and an axiom report alone would miss. Its second part
does the same for the comparator run.

| File | Content |
|---|---|
| `Ctl/Good/Base.lean`, `Ctl/Good/Top.lean` | two true theorems; the second uses the first |
| `Ctl/Bad/Base.lean` | adds a constant `Ctl.bad` of type `False`, with the "proof" `True.intro`, while the kernel is switched off (`set_option debug.skipKernelTC true`) |
| `Ctl/Bad/Top.lean` | deduces `1 = 2` from `Ctl.bad` |

## What happens

```bash
lake build Ctl.Good.Base Ctl.Good.Top Ctl.Bad.Base Ctl.Bad.Top
```

succeeds, and the four `#print axioms` commands report that `Ctl.good`, `Ctl.goodTop`,
`Ctl.bad` and `Ctl.top` do not depend on any axioms. So a build together with an axiom report
does not detect a declaration that was added without the kernel.

| Command | Result |
|---|---|
| `lake env leanchecker -v Ctl.Good` | exit status 0 |
| `lake env leanchecker -v Ctl.Bad` | exit status 1: `(kernel) declaration type mismatch, 'Ctl.bad' has type True but it is expected to have type False` |
| `lake env leanchecker -v Ctl.Bad.Top` | exit status 0 |
| `lake env leanchecker --fresh Ctl.Good.Top` | exit status 0 |
| `lake env leanchecker --fresh Ctl.Bad.Top` | exit status 1, the same message |

The third line is the reason for the form of the replays in this repository. Without
`--fresh`, the checker re-checks only the modules whose names begin with the given prefix and
takes their imports as they are. `make replay` therefore names the whole library, and
`make replay-fresh` replays every module behind `Main.lean`, Lean core and Mathlib included,
from an empty environment.

`lean4lean` gives the same results in both modes (exit status 0 for the good pair, exit status
1 for the bad pair).

## The same for comparator

Comparator, described in [`../../comparator/README.md`](../../comparator/README.md), judges a
solution against a challenge. Four more files and five configurations make one run that it
must accept and four that it must reject.

| File | Content |
|---|---|
| `Ctl/Challenge/Good.lean` | the statement of `Ctl.goodTop`, its proof left open |
| `Ctl/Challenge/Other.lean` | another statement, `2 + 2 = 5 ∧ True`, under the name `Ctl.goodTop` |
| `Ctl/Challenge/Bad.lean` | the statement of `Ctl.top`, which is `1 = 2`, its proof left open |
| `Ctl/Axiom/Top.lean` | a proof of the statement of `Ctl.goodTop` from a new axiom `Ctl.extra` |

| Configuration in `comparator/` | Challenge | Solution | Result |
|---|---|---|---|
| `accept.json` | `Ctl.Challenge.Good` | `Ctl.Good.Top` | accepted: `Your solution is okay!` |
| `reject-other-statement.json` | `Ctl.Challenge.Other` | `Ctl.Good.Top` | rejected: `Challenge and solution theorem statement do not match: 'Ctl.goodTop'` |
| `reject-axiom.json` | `Ctl.Challenge.Good` | `Ctl.Axiom.Top` | rejected: `Illegal axiom detected: 'Ctl.extra'` |
| `reject-false-proof.json` | `Ctl.Challenge.Bad` | `Ctl.Bad.Top` | rejected: nanoda stops with an error (`Child exited with 101`) |
| `reject-false-proof-lean-kernel.json` | `Ctl.Challenge.Bad` | `Ctl.Bad.Top` | rejected: `(kernel) declaration type mismatch, 'Ctl.bad' has type True but it is expected to have type False` |

In the last two runs the statements agree and no axiom is used, so the first two checks of
comparator pass. Only the replay of the solution stands between the false proof and an
acceptance: by nanoda in the fourth run, and by the Lean kernel in the fifth, where nanoda is
disabled.

`make comparator-controls`, in the root of the repository, makes the five runs and compares
their outcomes with this table. A rejection counts only if the output contains the message of
the table: a run that stops for another reason, such as a missing tool, is reported as wrong.
In the fourth run the failure must come after the line `Running nanoda kernel on solution`,
so that the failing step is nanoda and not an earlier one.

## Recorded runs

The recorded runs of the controls are listed in
[`../../notes/VERIFICATION.md`](../../notes/VERIFICATION.md).
