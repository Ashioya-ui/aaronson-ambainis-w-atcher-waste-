-- The statements and the final theorems
import AaronsonAmbainis.Conjecture
import AaronsonAmbainis.Main
-- Definitions and the statements of the links
import AaronsonAmbainis.Defs
import AaronsonAmbainis.Statements
import AaronsonAmbainis.DetDefs
import AaronsonAmbainis.AllPairsDefs
import AaronsonAmbainis.RowDefs
-- The determinant inequality
import AaronsonAmbainis.DetLow.Basic
import AaronsonAmbainis.DetLow.Unit
import AaronsonAmbainis.DetLow.NonZero
import AaronsonAmbainis.DetLow.RowOps
import AaronsonAmbainis.DetLow.Degree
import AaronsonAmbainis.DetLow.Count
import AaronsonAmbainis.DetLow.Main
import AaronsonAmbainis.DetLow.Corollary
import AaronsonAmbainis.DetBij.Basic
import AaronsonAmbainis.DetBij.Identity
import AaronsonAmbainis.DetBij.Perm
import AaronsonAmbainis.DetBij.Main
import AaronsonAmbainis.DetBij.Bijection
import AaronsonAmbainis.DetTheorem
-- Boolean functions: the antipodal, the all-pairs and the two-sided inequality
import AaronsonAmbainis.TwoSided.Basic
import AaronsonAmbainis.TwoSided.Overlap
import AaronsonAmbainis.TwoSided.Antipodal
import AaronsonAmbainis.TwoSided.Glue
import AaronsonAmbainis.TwoSided.AllPairsCore
import AaronsonAmbainis.TwoSided.AllPairs
import AaronsonAmbainis.TwoSided.CauchySchwarz
import AaronsonAmbainis.TwoSided.RemoveWeights
import AaronsonAmbainis.TwoSided.Main
-- Real functions with a row at every point: level functions, the integrated all-pairs
-- inequality, the third-moment inequality, the mean absolute increments
import AaronsonAmbainis.Level.Basic
import AaronsonAmbainis.Level.Rows
import AaronsonAmbainis.Level.AllPairs
import AaronsonAmbainis.Level.Integral
import AaronsonAmbainis.Level.Integrated
import AaronsonAmbainis.Level.ThirdMoment
import AaronsonAmbainis.Level.Median
import AaronsonAmbainis.Level.Increments
import AaronsonAmbainis.Level.Main
-- Averaging over coordinates: the influences
import AaronsonAmbainis.Average.Coordinate
import AaronsonAmbainis.Average.Iterate
import AaronsonAmbainis.Average.Influence
import AaronsonAmbainis.Average.Main
-- Bounded functions of low degree: the block inequality, the sensitivity at every point,
-- the packing bound, duality and the row bound
import AaronsonAmbainis.Row.Chi
import AaronsonAmbainis.Row.Degree
import AaronsonAmbainis.Row.Extension
import AaronsonAmbainis.Row.Markov
import AaronsonAmbainis.Row.Sensitivity
import AaronsonAmbainis.Row.Gadget
import AaronsonAmbainis.Row.Block
import AaronsonAmbainis.Row.Main
import AaronsonAmbainis.Row.DisjointBlocks
import AaronsonAmbainis.Row.HypothesisCheck
import AaronsonAmbainis.Pack.Blocks
import AaronsonAmbainis.Pack.Gate
import AaronsonAmbainis.Pack.Scaled
import AaronsonAmbainis.Pack.Packing
import AaronsonAmbainis.Pack.Main
import AaronsonAmbainis.Dual.Sets
import AaronsonAmbainis.Dual.Functional
import AaronsonAmbainis.Dual.Core
import AaronsonAmbainis.Dual.Cover
import AaronsonAmbainis.Dual.RowAux
import AaronsonAmbainis.Dual.Row
import AaronsonAmbainis.Dual.Main
import AaronsonAmbainis.Dual.Sanity
-- The main theorem from the links, and the chain of all links
import AaronsonAmbainis.MainTheorem
import AaronsonAmbainis.Chain
-- The definitions agree with the standard ones; the printed statements
import AaronsonAmbainis.Bridge.Basic
import AaronsonAmbainis.Bridge.Affine
import AaronsonAmbainis.Bridge.Fourier
import AaronsonAmbainis.Bridge.Algebra
import AaronsonAmbainis.Bridge.Poly
import AaronsonAmbainis.Bridge.ZeroOne
import AaronsonAmbainis.Bridge.Transport
import AaronsonAmbainis.Bridge.PrintedRow
import AaronsonAmbainis.Bridge.PrintedAA
import AaronsonAmbainis.Bridge.Capstone
import AaronsonAmbainis.Bridge.Instance
import AaronsonAmbainis.Bridge.Positivity
import AaronsonAmbainis.Bridge.PaperInequalities
import AaronsonAmbainis.Bridge.PaperTheorems
-- Axiom report
import AaronsonAmbainis.AxiomReport

/-!
# Bounded polynomials of low degree have influential variables

The root file of the library: it imports every module, in the order in which the modules are
meant to be read. The statements that are proved are in `AaronsonAmbainis/Conjecture.lean`, which
imports only Mathlib; the final theorems are in `AaronsonAmbainis/Main.lean`, and the chain of the
links of the proof is in `AaronsonAmbainis/Chain.lean`. The two modules of
`AaronsonAmbainis/Comparator/` stand apart and are not imported here.
-/
