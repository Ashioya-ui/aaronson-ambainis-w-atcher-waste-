import AaronsonAmbainis.Row.Markov
import AaronsonAmbainis.Row.Block

/-!
# The block inequality

`blockInequality : BlockInequality` is the block inequality (Lemma 6.4 of the paper). It follows
from `blockInequality_of_markov` (`Row/Block.lean`) and `markovEndpoint` (`Row/Markov.lean`).
-/

namespace AaronsonAmbainis

/-- The block inequality (`BlockInequality` of `RowDefs.lean`). -/
theorem blockInequality : BlockInequality := blockInequality_of_markov markovEndpoint

end AaronsonAmbainis
