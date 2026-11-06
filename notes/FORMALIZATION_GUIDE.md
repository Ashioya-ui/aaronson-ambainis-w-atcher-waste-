# Formalization guide

This note describes how the Lean library `AaronsonAmbainis` is organised and in which order to
read it. The map from the numbered statements of the paper to Lean declarations is in
[`PAPER_TO_LEAN.md`](PAPER_TO_LEAN.md); the axiom report is in
[`AXIOM_AUDIT.md`](AXIOM_AUDIT.md); the checks that were run are in
[`VERIFICATION.md`](VERIFICATION.md).

## Reading order

The root file `AaronsonAmbainis.lean` imports the modules in the order in which they are meant
to be read.

1. `AaronsonAmbainis/Conjecture.lean`. The statements, written with nothing but Mathlib: the
   file imports `Mathlib` and nothing from this project, and consists of five definitions of
   type `Prop`. The one to read is `PrintedConjecture`.
2. `AaronsonAmbainis/Main.lean`. The four final theorems. Each is proved by naming a theorem of
   `Bridge/Capstone.lean`.
3. `AaronsonAmbainis/Defs.lean`. The definitions of Section 2 of the paper (the cube, flips,
   wings, rows, influences, variance, mean absolute increments, degree).
4. `AaronsonAmbainis/Statements.lean`, `DetDefs.lean`, `AllPairsDefs.lean`, `RowDefs.lean`. The
   links of the proof, each stated as a proposition, without proofs.
5. The proof directories. First those of the chain that leads from the determinant inequality
   to the bound for the influences: `DetLow` and `DetBij` (with `DetTheorem.lean`), `TwoSided`,
   `Level`, `Average`; in the paper these are Sections 3, 4 and 5, 7 and 8. Then those of the
   row bound and of the sensitivity at every point: `Row`, `Pack`, `Dual`; in the paper this is
   Section 6.
6. `AaronsonAmbainis/MainTheorem.lean` and `AaronsonAmbainis/Chain.lean`. The first holds the
   three implications that lead from the links to the theorems for bounded functions of low
   degree. The second chains all the links: every theorem of this file is one implication
   applied to theorems that precede it. A reader who wants to see how the links fit together
   before reading any proof can go from step 4 directly to `Chain.lean`.
7. `AaronsonAmbainis/Bridge/`. The passage from the definitions of the project to the
   Mathlib-only statements of step 1.

The last module in the root file is `AxiomReport.lean`, which is described in
[`AXIOM_AUDIT.md`](AXIOM_AUDIT.md).

## The chain

```
DetLow.lowestUnit, DetLow.lowestBound          (Lemmas 3.3, 3.4, 3.6)
        │  DetBij.detInequality_of_lowest
        ▼
detInequality        : DetInequality           (Corollary 3.2)
        │  antipodal_of_det
        ▼
antipodalInequality  : AntipodalInequality     (Theorem 4.3)
        │  allPairs_of_antipodal
        ▼
allPairsInequality   : AllPairsInequality      (Proposition 5.2)
        │  integratedAllPairs_of_allPairs
        ▼
integratedAllPairsInequality : IntegratedAllPairsInequality      (Proposition 7.4)
        │  thirdMoment_of_integratedAllPairs
        ▼
thirdMomentInequality : ThirdMomentInequality  (Theorem 7.6)
        │  meanIncrement_of_thirdMoment
        ▼
meanIncrementBound   : MeanIncrementBound      (Theorem 7.10)
        │  influence_of_meanIncrement
        ▼
influenceBound       : InfluenceBound          (Theorem 8.3)


markovEndpoint       : MarkovEndpoint          (Lemma 6.1)
        │  blockInequality_of_markov
        ▼
blockInequality      : BlockInequality         (Lemma 6.4)
        │  packingBound_of_block
        ▼
packingBound         : PackingBound            (Lemma 6.5)
        │  rowBoundPM_of_packing               (uses coverDuality, Proposition 6.7)
        ▼
rowBoundPM           : RowBoundPM              (Theorem 6.8)

blockInequality
        │  sensitivity_of_block
        ▼
sensitivityBound     : SensitivityBound        (Corollary 6.10)


influenceBound, sensitivityBound, rowBoundPM
        │  mainTheorem_of_influence
        ▼
mainTheorem          : MainTheorem             (Theorem 1.1)
        │  Bridge.printedConjecture, Bridge.explicitBound, Bridge.explicitBoundPM
        ▼
aaronson_ambainis    : PrintedConjecture       (Corollary 1.2; the conjecture)
```

Three further theorems of `Chain.lean` branch off this chain.

* `twoSidedInequality : TwoSidedInequality` (Theorem 5.4), from `allPairsInequality` by
  `twoSided_of_allPairs`. It is a result of the paper in its own right; no final theorem uses
  it.
* `meanIncrementDegreeBound : MeanIncrementDegreeBound` (Corollary 7.11), from
  `meanIncrementBound` and `rowBoundPM` by `meanIncrementDegree_of_meanIncrement`.
* `mainTheoremImproved_of_rowBound : RowBound → MainTheoremImproved` (Remark 8.4), from
  `influenceBound` and `sensitivityBound` by `mainTheoremImproved_of_influence`. Its hypothesis
  is not proved in the library (see "Design" below). The fourth final theorem,
  `aaronson_ambainis_of_fbsDegreeBound`, rests on it.

## Directories

| Directory | Files | Lines | Content |
|---|---|---|---|
| top level | 12 | 1222 | the statement, the final theorems, the definitions, the statements of the links, `DetTheorem.lean`, the two files that assemble the chain (`MainTheorem.lean`, which follows the proof of the main theorem in Section 8.3, and `Chain.lean`), the axiom report, and the root file `AaronsonAmbainis.lean` |
| `DetLow/` | 8 | 671 | the lowest monomials of the determinant of the agreement matrix (Sections 3.2 and 3.3) |
| `DetBij/` | 5 | 601 | the wing identity, the bijection theorem and the determinant inequality (Sections 3.4 and 3.1) |
| `TwoSided/` | 9 | 960 | the antipodal inequality, the all-pairs inequality, the removal of the weights and the two-sided inequality (Sections 4 and 5) |
| `Level/` | 9 | 1383 | level functions and their rows, integration over the level, the integrated all-pairs inequality, the third-moment inequality and the bound for the mean absolute increments (Section 7) |
| `Average/` | 4 | 456 | averaging over coordinates and the bound for the influences (Sections 8.1 and 8.2) |
| `Row/` | 10 | 799 | Markov's inequality at an endpoint, the sensitivity lemma, the block inequality and the sensitivity at every point (Sections 6.1 to 6.4 and 6.8) |
| `Pack/` | 5 | 282 | the packing bound (Section 6.5) |
| `Dual/` | 8 | 527 | duality between packings and rows, and the row bound (Sections 6.6 and 6.7) |
| `Bridge/` | 14 | 2553 | the definitions agree with the standard ones; the statements as printed |

In all: 84 files and 9,454 lines, of which 6,446 are lines of code (neither blank nor comment).

The directory `Comparator/` holds two further files, 66 lines together: the challenge and the
solution of a comparator run (see [`../comparator/README.md`](../comparator/README.md)). They
are not part of the library. No module imports them, the root file included, and the numbers
of this note do not count them.

## What the final theorems depend on

`Main.lean` and the modules that it imports, directly or through other modules, are 74 of the
84 files (7,993 lines). The other ten files are side results and checks; the final theorems do not
depend on them:

* `AaronsonAmbainis.lean`, the root file, which imports every module of the library;
* `AxiomReport.lean`, which only prints axioms and checks types;
* `DetBij/Bijection.lean`, the bijection theorem in the wording of the paper;
* `DetLow/Corollary.lean`, `Dual/Sanity.lean` and `Row/HypothesisCheck.lean`, corollaries and
  consistency checks;
* `Bridge/Positivity.lean`, `Bridge/PaperTheorems.lean`, `Bridge/PaperInequalities.lean` and
  `Bridge/Instance.lean`, which show that the propositions of the library are the statements
  printed in the paper, that the inverted sums are positive, and that the Mathlib-only
  statements are not vacuous.

Among the 74, five are index files, with a module docstring and no declaration
(`TwoSided/Main.lean`, `Level/Main.lean`, `Average/Main.lean`, `Pack/Main.lean`,
`Dual/Main.lean`), and two are imported although no final theorem uses a declaration of
theirs: `TwoSided/RemoveWeights.lean`, which proves the two-sided inequality, and
`Bridge/ZeroOne.lean`, which serves a second form of the hypothesis `RowBound`
(`Bridge.rowBound_iff_printedML`).

Ten modules of `Bridge/` are among the 74. They carry `MainTheorem`, which is stated with the
definitions of `Defs.lean`, over to `PrintedConjecture`, which is stated with `MvPolynomial`
and finite sums only, and the hypothesis `FbsDegreeBound` over to `RowBound`.

## Design

* **Statements apart from proofs.** Every link is a definition of type `Prop` in one of the
  four statement files, and its proof is a theorem of that type elsewhere. A link that rests
  on earlier links is proved as an implication from them (`antipodal_of_det`,
  `allPairs_of_antipodal`, and so on), and `Chain.lean` applies these implications one after
  the other. A reader can see how the chain closes by reading the statement files and
  `Chain.lean` only.
* **A statement that needs no trust in the project.** `Conjecture.lean` imports only Mathlib,
  so that the meaning of `PrintedConjecture` does not depend on any definition of this
  library.
* **A named hypothesis instead of an axiom.** The row bound of Agarwal and Ben-David with the
  constant `π²/4` (arXiv:2410.19062, Theorem 1.7) is not proved here. It appears only as a
  hypothesis: `RowBound` on the cube, and `FbsDegreeBound` in the Mathlib-only form. The
  theorems that assume it, among them `mainTheoremImproved_of_rowBound` and
  `aaronson_ambainis_of_fbsDegreeBound`, are implications. The other three final theorems do
  not use it.
* **Rows as families.** In the propositions on real functions, a row of `f` at every point is
  a family `a : Cube ι → ι → ℝ` with `0 ≤ a x j` and `|f x - f y| ≤ ∑ j ∈ diffSet x y, a x j`
  for all `x` and `y`. That this is a row in the sense of Definition 2.3 at every point is
  `Bridge.rows_iff_printed`.
* **Bounds without square roots.** The propositions of the chain state the bounds as
  inequalities between polynomials, for example `3 Var(f)^5 ≤ 50000 π^8 d^12 Inf_j(f)^2` in
  `MainTheorem`. The forms with the power `5/2`, in which the paper and `Conjecture.lean`
  state the bounds, are deduced at the end (`Bridge.sqrt_form_iff`, where the power `ε^{5/2}` is
  written `ε ^ 2 * Real.sqrt ε`); `Conjecture.lean` writes the power `ε^{5/2}` as the real power
  `ε ^ ((5 : ℝ) / 2)`, and `Bridge.rpow_five_halves` says that `ε ^ ((5 : ℝ) / 2)` and
  `ε ^ 2 * Real.sqrt ε` are equal.
* **Inverses.** In Lean `0⁻¹ = 0` and `x / 0 = 0`. The sums that are inverted in the
  antipodal, the all-pairs and the two-sided inequality are shown to be positive in
  `Bridge/Positivity.lean`, and the denominators of the integrated all-pairs inequality in
  `Level/AllPairs.lean` (`Level.pairSum_pos`).

## What comes from Mathlib

The library uses Mathlib throughout (finite sums, real analysis, interval integrals,
`MvPolynomial`, `Matrix.det`, permutations). Three theorems of Mathlib replace arguments that
the paper gives in full:

* `det_ne_zero_of_sum_row_lt_diag`, on strictly diagonally dominant matrices, in the proof of
  Lemma 3.4 in `DetLow/NonZero.lean`;
* `Polynomial.Chebyshev.eval_iterate_derivative_le_of_forall_abs_le_one`, from which Markov's
  inequality at an endpoint (Lemma 6.1) is deduced in `Row/Markov.lean`;
* `geometric_hahn_banach_compact_closed`, the separation theorem used for the duality of
  Proposition 6.7 in `Dual/Cover.lean`, in place of Lemma 6.6.

The pinned versions are in `lean-toolchain` and `lake-manifest.json`.
