import AaronsonAmbainis.Dual.Cover
import AaronsonAmbainis.Dual.Row

/-!
# Duality and the row bound

* `coverDuality : CoverDuality`
  (linear-programming duality between fractional packings and rows; it corresponds to
  Proposition 6.7 of the paper, which is `Dual.exists_cover`; file `Cover.lean`, helpers in
  `Sets`, `Functional`, `Core`)
* `rowBoundPM_of_packing : PackingBound → RowBoundPM`
  (the row bound, Theorem 6.8 of the paper, from the packing bound, Lemma 6.5; file `Row.lean`,
  helper in `RowAux`)
-/
