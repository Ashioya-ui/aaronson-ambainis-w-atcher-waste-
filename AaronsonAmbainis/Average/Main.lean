import AaronsonAmbainis.Average.Influence

/-!
# Averaging over coordinates: from the mean absolute increments to the influences

Section 8 of the paper.

* `AaronsonAmbainis.influence_of_meanIncrement : MeanIncrementBound → InfluenceBound`
  (the bound for the influences of a function with rows of cost at most `K`, Theorem 8.3 of the
  paper, from the bound for the mean absolute increments, Theorem 7.10, applied to the average
  of the function over a set of coordinates; file `Influence.lean`, helpers in `Coordinate`,
  `Iterate`)
-/
