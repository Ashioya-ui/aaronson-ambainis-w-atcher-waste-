import AaronsonAmbainis.TwoSided.Antipodal
import AaronsonAmbainis.TwoSided.AllPairs
import AaronsonAmbainis.TwoSided.RemoveWeights

/-!
# From the determinant inequality to the two-sided inequality: the three implications

* `AaronsonAmbainis.antipodal_of_det : DetInequality → AntipodalInequality`
  (the antipodal inequality, Theorem 4.3 of the paper, from the determinant inequality,
  Corollary 3.2);
* `AaronsonAmbainis.allPairs_of_antipodal : AntipodalInequality → AllPairsInequality`
  (the all-pairs inequality, Proposition 5.2, from the antipodal inequality);
* `AaronsonAmbainis.twoSided_of_allPairs : AllPairsInequality → TwoSidedInequality`
  (the two-sided inequality, Theorem 5.4, from the all-pairs inequality and the lemma that
  removes the weights, Lemma 5.3).
-/
