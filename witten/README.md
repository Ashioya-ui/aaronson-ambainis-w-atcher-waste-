# Witten's lattice chiral gauge theory, run on his own setup

E. Witten, *A Note On Lattice Definition of Gauge Theories With Chiral Fermions*, arXiv:2611.05051.
The paper describes the construction and argues that it can be computed in principle (section 4). It reports no runs. This directory runs it.

## The setup (Witten's, not a model)

- Gauge group SU(5). Positive-chirality fermions in 5̄ ⊕ 10: one Standard Model generation, the anomaly-free representation Witten cites.
- Spacetime: the 4-torus, lattice 4⁴, admissible fields ‖1 − U_P‖ < ε on every plaquette.
- The continuum: a fine lattice with m = 2 points per lattice spacing (8⁴).

## The pipeline

1. **Leashed sampler** over the admissible set: Metropolis for the Wilson action, restricted to admissible fields. Margin rule (Lemma A of our self-approaching paper, in this setting): an update R of one link changes every plaquette through it by at most ‖1 − R‖, since ‖1 − RP‖ ≤ ‖1 − R‖ + ‖1 − P‖. So a move with ‖1 − R‖ ≤ ε − max ‖1 − U_P‖ cannot leave the set and needs no check; other moves are checked exactly and refused if they leave.
2. **Witten's interpolation (section 3).** On 1-cells, the constant connection: an m-th root of the link through its traceless logarithm. On 2-, 3- and 4-cells, the Dirichlet problem, solved as minimisation of the Yang–Mills (Wilson) action with the cell's boundary fixed (his footnote 17). Each cell depends only on its own lattice data.
3. **Witten's section 4.** |det D⁺_W| through the Laplace-like operator D⁺†D⁺ = Δ − ½ Σ_{μ<ν} [γ_μ, γ_ν] F_μν (the covariant Laplacian and the clover field strength), compared with the naive lattice Weyl operator.

## Results

| Witten's claim | Check | Instanton number 0 | Instanton number 2 |
| --- | --- | --- | --- |
| The interpolation reproduces every link exactly | max over links of ‖Π fine links − U‖ | 9.1 × 10⁻¹⁵ | 7.6 × 10⁻¹⁵ |
| Gauge-equivalent lattice fields give gauge-equivalent interpolations | fine plaquette traces after a Haar-random gauge transformation | 9.7 × 10⁻¹¹ (1.6 × 10⁻¹¹ with Landau gauge first) | — |
| Field strength of order ε in lattice units | max fine ‖1 − W_p‖ · m² against max coarse ‖1 − U_P‖ | 0.352 against 0.350 | 0.609 against 0.600 |
| The topology of the interpolation is fixed by the lattice field | fine topological charge | 0.00009 | 1.977 |

Instanton number 2 is an SU(5) field with U(1) fluxes along H = diag(1, −1, 0, 0, 0) (instanton number tr H² · n₁₂ n₃₄ = 2), with admissible fluctuations from the sampler on top.

Sampler, instanton number 0 (β = 120, ε = 0.35, 60 sweeps): 61,440 proposals, 3,979 accepted, 4,074 refused for leaving the admissible set, 5,907 cleared by the margin rule without a check. Instanton number 2 (β = 200, ε = 0.6): 61,440 proposals, 10,639 accepted, 432 refused, 29,562 cleared by the margin rule. The instanton number did not change.

FERMIONS_PLACEHOLDER

## Run it

```bash
pip install numpy scipy
python3 run.py A   # instanton number 0: sampler, interpolation, gauge covariance
python3 run.py B   # instanton number 2: flux plus fluctuations, interpolation
python3 run.py C   # fermions in 5̄ ⊕ 10 on the stage-B field
```

Results are written to `results/stage_*.json`.

## Next

η(D_Y) on Y = T³ × D (antiperiodic fermions on the circle that bounds the disc), through D_Y² and the signs of ⟨ψ, D_Y ψ⟩, as in section 4; then the phase exp(−iπη) across admissible configurations. That phase decides whether Monte Carlo works in practice.
