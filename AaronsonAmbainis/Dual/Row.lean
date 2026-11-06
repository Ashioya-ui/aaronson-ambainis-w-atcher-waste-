import AaronsonAmbainis.Dual.RowAux
import AaronsonAmbainis.Dual.Cover

/-!
# The row bound from the packing bound

`rowBoundPM_of_packing : PackingBound → RowBoundPM` (Theorem 6.8 of the paper from Lemma 6.5), by
`Dual.rowBoundPM_of_packing_of_cover` and `coverDuality`.
-/

namespace AaronsonAmbainis

theorem rowBoundPM_of_packing : PackingBound → RowBoundPM :=
  fun hPB => Dual.rowBoundPM_of_packing_of_cover hPB coverDuality

end AaronsonAmbainis
