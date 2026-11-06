import AaronsonAmbainis.DetLow.Main
import AaronsonAmbainis.DetBij.Main

/-!
# The determinant inequality, assembled

The determinant inequality (Corollary 3.2 of the paper), from the two halves of its proof:

* `AaronsonAmbainis.DetLow.lowestUnit`, `AaronsonAmbainis.DetLow.lowestBound`
  (directory `DetLow`),
* `AaronsonAmbainis.DetBij.detInequality_of_lowest` (directory `DetBij`).
-/

namespace AaronsonAmbainis

/-- The determinant inequality (Corollary 3.2 of the paper), with no hypothesis. -/
theorem detInequality : DetInequality :=
  DetBij.detInequality_of_lowest DetLow.lowestUnit DetLow.lowestBound

end AaronsonAmbainis
