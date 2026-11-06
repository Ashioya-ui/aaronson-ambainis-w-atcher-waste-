import AaronsonAmbainis.Main
import AaronsonAmbainis.Chain
import AaronsonAmbainis.MainTheorem
import AaronsonAmbainis.DetTheorem
import AaronsonAmbainis.DetBij.Main
import AaronsonAmbainis.DetBij.Bijection
import AaronsonAmbainis.DetLow.Corollary
import AaronsonAmbainis.TwoSided.Main
import AaronsonAmbainis.Level.Main
import AaronsonAmbainis.Average.Main
import AaronsonAmbainis.Row.Main
import AaronsonAmbainis.Row.DisjointBlocks
import AaronsonAmbainis.Pack.Main
import AaronsonAmbainis.Dual.Main
import AaronsonAmbainis.Dual.Sanity
import AaronsonAmbainis.Bridge.Fourier
import AaronsonAmbainis.Bridge.Transport
import AaronsonAmbainis.Bridge.ZeroOne
import AaronsonAmbainis.Bridge.PrintedRow
import AaronsonAmbainis.Bridge.PrintedAA
import AaronsonAmbainis.Bridge.Capstone

/-!
# Axiom report

For every named result of the project this file prints the axioms on which it depends
(`#print axioms`) and, for the main links, checks its type (`#check`, `example`). Nothing is
proved here. The expected output of every `#print axioms` line is

  `[propext, Classical.choice, Quot.sound]`

or a subset of it. `make axioms` runs this file and checks the output.
-/

open AaronsonAmbainis

/-! ## The final theorems -/

#check (aaronson_ambainis : PrintedConjecture)
#check (aaronson_ambainis_explicit : ExplicitBound)
#check (aaronson_ambainis_pm : ExplicitBoundPM)
#check (aaronson_ambainis_of_fbsDegreeBound :
  FbsDegreeBound → ExplicitBoundImproved)
#print axioms aaronson_ambainis
#print axioms aaronson_ambainis_explicit
#print axioms aaronson_ambainis_pm
#print axioms aaronson_ambainis_of_fbsDegreeBound

/-! ## The chain of the proof -/

#check (detInequality : DetInequality)
#check (antipodalInequality : AntipodalInequality)
#check (allPairsInequality : AllPairsInequality)
#check (twoSidedInequality : TwoSidedInequality)
#check (integratedAllPairsInequality : IntegratedAllPairsInequality)
#check (thirdMomentInequality : ThirdMomentInequality)
#check (meanIncrementBound : MeanIncrementBound)
#check (influenceBound : InfluenceBound)
#print axioms detInequality
#print axioms antipodalInequality
#print axioms allPairsInequality
#print axioms twoSidedInequality
#print axioms integratedAllPairsInequality
#print axioms thirdMomentInequality
#print axioms meanIncrementBound
#print axioms influenceBound
#check (markovEndpoint : MarkovEndpoint)
#check (blockInequality : BlockInequality)
#check (sensitivityBound : SensitivityBound)
#check (packingBound : PackingBound)
#check (coverDuality : CoverDuality)
#check (rowBoundPM : RowBoundPM)
#print axioms markovEndpoint
#print axioms blockInequality
#print axioms sensitivityBound
#print axioms packingBound
#print axioms coverDuality
#print axioms rowBoundPM
#check (mainTheorem : MainTheorem)
#check (meanIncrementDegreeBound : MeanIncrementDegreeBound)
#check (mainTheoremImproved_of_rowBound : RowBound → MainTheoremImproved)
#print axioms mainTheorem
#print axioms meanIncrementDegreeBound
#print axioms mainTheoremImproved_of_rowBound

/-! ## The determinant inequality -/

example : LowestUnit := DetLow.lowestUnit
example : LowestBound := DetLow.lowestBound
#check (DetLow.lowestUnit : LowestUnit)
#check (DetLow.lowestBound : LowestBound)
#print axioms DetLow.lowestUnit
#print axioms DetLow.lowestBound
#print axioms DetLow.exists_lowest_le_bdry
#print axioms DetLow.exists_monomial_weight_le
#check @DetBij.detInequality_of_lowest
example : LowestUnit → LowestBound → DetInequality :=
  DetBij.detInequality_of_lowest
#print axioms DetBij.detInequality_of_lowest
#print axioms DetBij.exists_perm
#print axioms DetBij.Pmat_mul_agMatrix
#print axioms DetBij.wing_sum
#print axioms DetBij.det_inequality_of_perm
#print axioms DetBij.exists_bijection

/-! ## The antipodal inequality and the two-sided inequality -/

#print axioms antipodal_of_det
#check (antipodal_of_det : DetInequality → AntipodalInequality)
#print axioms allPairs_of_antipodal
#check (allPairs_of_antipodal : AntipodalInequality → AllPairsInequality)
#print axioms twoSided_of_allPairs
#check (twoSided_of_allPairs : AllPairsInequality → TwoSidedInequality)

/-! ## Real functions with a row at every point -/

#print axioms integratedAllPairs_of_allPairs
#check (integratedAllPairs_of_allPairs : AllPairsInequality → IntegratedAllPairsInequality)
#print axioms thirdMoment_of_integratedAllPairs
#check (thirdMoment_of_integratedAllPairs :
  IntegratedAllPairsInequality → ThirdMomentInequality)
#print axioms meanIncrement_of_thirdMoment
#check (meanIncrement_of_thirdMoment : ThirdMomentInequality → MeanIncrementBound)
#print axioms influence_of_meanIncrement
#check (influence_of_meanIncrement : MeanIncrementBound → InfluenceBound)
example : AllPairsInequality → InfluenceBound :=
  fun hAllPairs => influence_of_meanIncrement (meanIncrement_of_thirdMoment
    (thirdMoment_of_integratedAllPairs (integratedAllPairs_of_allPairs hAllPairs)))
#print axioms Level.isRow_levRow
#print axioms Level.level_integration
#print axioms Level.pairSum_pos
#print axioms Level.level_allPairs
#print axioms Level.integrated_four_mul
#print axioms Level.thirdMoment_core
#print axioms Level.thirdMoment_lower
#print axioms Level.separated_sets
#print axioms Level.exists_median
#print axioms Level.sum_sq_cube_le
#print axioms Level.variance_cube_le
#print axioms Level.exists_meanAbsIncr_ge_sqrt
#print axioms Level.meanAbsIncr_sq_le
#print axioms Level.cost_pos
#print axioms Level.sum_meanAbsIncr_le_cost
#print axioms Level.exists_rows_cost
#print axioms Average.variance_avg
#print axioms Average.rows_avg
#print axioms Average.exists_avg_set
#print axioms Average.sum_meanAbsIncr_pos
#print axioms Average.influence_of_incr
#print axioms Average.influence_cost
#print axioms Average.exists_inflR_ge_sqrt

/-! ## The row bound and the sensitivity at every point -/

#check (blockInequality_of_markov : MarkovEndpoint → BlockInequality)
#print axioms blockInequality_of_markov
#check (sensitivity_of_block : BlockInequality → SensitivityBound)
#print axioms sensitivity_of_block
#print axioms Row.disjoint_blocks_of_block
#check (packingBound_of_block : BlockInequality → PackingBound)
#print axioms packingBound_of_block
#check (rowBoundPM_of_packing : PackingBound → RowBoundPM)
#print axioms rowBoundPM_of_packing
#check @Dual.exists_cover
#check @Dual.cover_iff_packing
#check (Dual.packingBound_iff_rowBoundPM : PackingBound ↔ RowBoundPM)
#check (Dual.rowBoundPM_of_rowBound : RowBound → RowBoundPM)
#check (Dual.packingBound_of_rowBound : RowBound → PackingBound)
#print axioms Dual.exists_cover
#print axioms Dual.cover_iff_packing
#print axioms Dual.empty_nonpos_of_packing
#print axioms Dual.packingBound_iff_rowBoundPM
#print axioms Dual.rowBoundPM_of_rowBound
#print axioms Dual.packingBound_of_rowBound

/-! ## The theorems for bounded functions of degree at most `d` -/

#check (mainTheorem_of_influence :
  InfluenceBound → SensitivityBound → RowBoundPM → MainTheorem)
#check (meanIncrementDegree_of_meanIncrement :
  MeanIncrementBound → RowBoundPM → MeanIncrementDegreeBound)
#check (mainTheoremImproved_of_influence :
  InfluenceBound → SensitivityBound → RowBound → MainTheoremImproved)
#print axioms mainTheorem_of_influence
#print axioms meanIncrementDegree_of_meanIncrement
#print axioms rows_of_rowBound
#print axioms mainTheoremImproved_of_influence
example : AllPairsInequality → BlockInequality → PackingBound → MainTheorem :=
  fun hAllPairs hBlock hPacking =>
    mainTheorem_of_influence
      (influence_of_meanIncrement (meanIncrement_of_thirdMoment
        (thirdMoment_of_integratedAllPairs (integratedAllPairs_of_allPairs hAllPairs))))
      (sensitivity_of_block hBlock) (rowBoundPM_of_packing hPacking)

/-! ## The definitions agree with the standard ones; the printed statements -/

#print axioms Bridge.aa_hyps_dict
#print axioms Bridge.aa_hyps_satisfiable
#print axioms Bridge.aa_conclusion_dict
#print axioms Bridge.variance_dict
#print axioms Bridge.inflR_dict_self
#print axioms Bridge.rowBound_conclusion_dict
#print axioms Bridge.hasDegreeLE_zero_iff
#print axioms Bridge.hasDegreeLE_zero_const
#print axioms Bridge.dict_not_hasDegreeLE_zero
#print axioms Bridge.hasDegreeLE_card
#print axioms Bridge.hasDegreeLE_mono
#print axioms Bridge.diffSet_flipSet
#print axioms Bridge.flipSet_diffSet
#print axioms Bridge.hasDegreeLE_iff_fourier
#print axioms Bridge.hasDegreeLE_chi_iff
#print axioms Bridge.parity_not_hasDegreeLE
#print axioms Bridge.rowBound_iff_fin
#print axioms Bridge.hasDegreeLE_iff_01
#print axioms Bridge.hasDegreeLE_iff_poly_zo
#print axioms Bridge.hasDegreeLE_iff_poly_pm
#print axioms Bridge.rowBound_iff_printed
#print axioms Bridge.rowBound_iff_printedML
#print axioms Bridge.weights_nonneg_of_row
#print axioms Bridge.rowBound_nonneg
#print axioms Bridge.aa_hyps_force
#print axioms Bridge.variance_affine
#print axioms Bridge.inflR_affine
#print axioms Bridge.variance_le_quarter
#print axioms Bridge.variance_le_one
#print axioms Bridge.zo_of_mainBound
#print axioms Bridge.pm_of_mainBound
#print axioms Bridge.sqrt_form_iff
#print axioms Bridge.ratio_pow_le
#print axioms Bridge.pm_sq_of_mainTheorem
#print axioms Bridge.pm_sqrt_of_mainTheorem
#print axioms Bridge.zo_sq_of_mainTheorem
#print axioms Bridge.zo_sqrt_of_mainTheorem
#print axioms Bridge.zo_pow_of_mainTheorem
#print axioms Bridge.zo_sq_of_mainTheoremImproved
#print axioms Bridge.zo_sqrt_of_mainTheoremImproved
#print axioms Bridge.explicitBound_sq
#print axioms Bridge.explicitBoundPM_sq
#print axioms Bridge.explicitBoundImproved_sq_of_fbsDegreeBound
