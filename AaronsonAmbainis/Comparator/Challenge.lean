import AaronsonAmbainis.Conjecture

/-!
# Comparator: the challenge

The trusted side of a run of comparator (`https://github.com/leanprover/comparator`). This file
imports `AaronsonAmbainis/Conjecture.lean` and nothing else, and that file imports only Mathlib,
so no proof of this project stands behind the four statements below.

The four theorems have the types of the four final theorems of `AaronsonAmbainis/Main.lean`.
Their proofs are left open here on purpose. Comparator takes the statements from this file and
the proofs from `Solution.lean`, and accepts only if the solution proves exactly these
statements, from the permitted axioms, with proofs that pass the kernel again.

No file of the library imports this file, and the library does not depend on it. The run is
configured in `comparator/config.json` and described in `comparator/README.md`.
-/

namespace AaronsonAmbainisComparator

/-- The statement of `AaronsonAmbainis.aaronson_ambainis`: the conjecture as printed, with the
exponent `7` for `O(1)`. -/
theorem aaronson_ambainis : AaronsonAmbainis.PrintedConjecture := by
  sorry

/-- The statement of `AaronsonAmbainis.aaronson_ambainis_explicit`. -/
theorem aaronson_ambainis_explicit : AaronsonAmbainis.ExplicitBound := by
  sorry

/-- The statement of `AaronsonAmbainis.aaronson_ambainis_pm`. -/
theorem aaronson_ambainis_pm : AaronsonAmbainis.ExplicitBoundPM := by
  sorry

/-- The statement of `AaronsonAmbainis.aaronson_ambainis_of_fbsDegreeBound`. -/
theorem aaronson_ambainis_of_fbsDegreeBound :
    AaronsonAmbainis.FbsDegreeBound → AaronsonAmbainis.ExplicitBoundImproved := by
  sorry

end AaronsonAmbainisComparator
