# Contributing

Corrections are welcome as focused pull requests.

For a change to the Lean sources:

1. say which declaration, and which statement of the paper, is affected;
2. keep the pinned toolchain and the pinned Mathlib revision, unless the pull request is an
   upgrade of the toolchain and nothing else;
3. do not change `AaronsonAmbainis/Conjecture.lean` together with anything else: that file is the
   statement of what is proved, and a change to it needs a review of its own;
4. run `make check` (imports, static audit, build, axiom report) and `make replay`;
5. include the new axiom report if the dependencies of a theorem have changed.

For a change to the paper or to the notes: keep the attributions of results to their sources, keep
the numbers of the paper that are quoted in `notes/PAPER_TO_LEAN.md`, in the other notes and in the
docstrings of the Lean files in step with the paper, and rebuild the PDF with `make paper`.
