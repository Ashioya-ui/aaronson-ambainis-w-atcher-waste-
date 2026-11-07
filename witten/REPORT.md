# Aaronson–Ambainis primitives × self-approaching paths × Craig, run on Witten's construction

Witten, *A Note On Lattice Definition of Gauge Theories With Chiral Fermions*, arXiv:2611.05051.
Craig, *A Gauge-Invariant Measure for Lattice Chiral Fermions*, arXiv:2610.09093.
Turturean, *A proof of the Aaronson–Ambainis conjecture* (this repository).

## 1. Primitives that satisfy the conditions of our paper

Our paper: a self-approaching curve has length at most 3.1297 times its diameter in the plane, and the best curves known reach 1 + 2π/3 ≈ 3.0944. Margins survive perturbation (Lemma A) and refinement (Lemma B′).

| Primitive (Lean) | Statement | Condition it satisfies | Role in the algorithm |
| --- | --- | --- | --- |
| Rows, `RowBoundPM` (Theorem 6.8) | \|f(x) − f(y)\| is at most the sum of the weights of the coordinates that differ | A certified bound on displacement by weighted length; with Lemma A, a move inside the margin cannot cross the boundary | Admissibility certificate: a link update R moves each plaquette through it by at most ‖1 − R‖ |
| `MarkovEndpoint` (Lemma 6.1) and Chebyshev polynomials | \|p′(0)\| ≤ D² for p of degree D bounded by 1 on [0, 2] | Speed at an endpoint is at most D² times the range | Witten works with D†D ≥ 0, whose zero modes sit at the endpoint 0: a filter that separates them needs degree N ≥ √(λ_top / (4·gap)), and Chebyshev reaches it |
| Averaging over coordinates (Section 8) | Conditional expectations over growing sets of coordinates | A chain of nested projections is self-approaching: ‖f_k − f_j‖² = ‖f_k‖² − ‖f_j‖² ≤ ‖f_i − f_j‖² for i < k < j | Its increments are orthogonal, so length ≤ √K × diameter over K steps, with equality for the staircase. This bounds the drift of Craig's projectors across K refinements |

New data:
- In n dimensions the staircase (one coordinate at a time) is self-approaching with length/diameter = √n. The planar constants 3.0944–3.1297 therefore do not hold in field space (196,608 real dimensions for the Standard Model group on an 8⁴ lattice).
- What does hold there is the √K bound for nested projections, together with the margin and endpoint primitives above.

## 2. The algorithm: leashed Craig–Witten refinement

1. **Sample admissible fields with certified moves.** This is primitive 1 combined with Lemma A: a move whose certified change fits inside the margin is accepted without a check, and any other move is checked exactly.
2. **Interpolate** with Witten's section 3 construction: the constant connection on 1-cells, then Dirichlet problems on 2-, 3- and 4-cells. The Dirichlet problems are solved as Yang–Mills minimisation with the cell's boundary fixed (his footnote 17), at spacings a and a/2.
3. **Build Witten's Laplace-like operator** D†D = Δ − ½ Σ [γ_μ, γ_ν] F_μν for 5̄ ⊕ 10 at each spacing (his section 4).
4. **Extract the chiral zero-mode projectors.** A Jackson-damped Chebyshev filter does this, with its degree certified by `MarkovEndpoint` (primitive 2).
5. **Compare across spacings (Craig's step).** The chiral projectors at spacings a and a/2 are compared through their principal angles. The drift over K refinements is at most √K × the total distance (primitive 3).

## 3. The run

- **Setup:** Witten's own: SU(5), positive-chirality fermions in 5̄ ⊕ 10 (one Standard Model generation), the 4-torus, admissible fields.
- **Lattice:** 4⁴, refined to 8⁴. Instanton number 0 (β = 120, ε = 0.35) and instanton number 2 (U(1) fluxes along diag(1, −1, 0, 0, 0) with sampled fluctuations, β = 200, ε = 0.6). Fermions are antiperiodic.
- **Machine:** Linux cloud VM, 2 cores, 7 GB.
- **Code and data:** `pipeline.py`, `run.py`, `hybrid.py`, `trees.py`; results are in `results/`.

## 4. Findings against Witten's

| Witten | Result | Verdict |
| --- | --- | --- |
| §3 The interpolation reproduces the lattice field | Link error ≤ 9.1 × 10⁻¹⁵ | Agrees |
| §3 Gauge-equivalent fields give equivalent interpolations | 9.7 × 10⁻¹¹ after a Haar-random gauge transformation | Agrees |
| §3 Field strength of order ε | 0.352 against ε = 0.350, and 0.609 against 0.600, in lattice units | Agrees; spacing a/m divides the plaquette margin by m² |
| §3 Topology fixed by the lattice field | Topological charge 0.00009 and 1.977 | Agrees |
| §3 Gauge-fixed links satisfy \|U − 1\| < (k − 1)ε | Measured maximum is 0.60 × 3ε (instanton number 0) and 0.49 × 3ε (instanton number 2) over 4,352 links each. The ladder bound mε is attained exactly (ratio 1.000). For k = 3, (k − 1) is the best possible over all 384 tree gauges (exhaustive search, and a counting proof: 15 face–edge incidences against 14). For k = 4, 75,718 trees searched, none better | Agrees, and the bound is sharp |
| §4 \|det D⁺_W\| through D†D, with no doubling | Zero modes: 0 and 2 for the 5̄, 0 and 6 for the 10, so index 8, all of one chirality. The naive lattice operator gives 64 and 64, index 0 | Agrees |
| §2.3 Zero modes in instanton sectors | 8 at instanton number 2 = 4 per unit for one generation | Agrees |
| §4 Computable in principle | The certified minimum degree is 5. A degree-120 Chebyshev filter with 24 random vectors counts 1.62 ± 0.25 (exact 2) and 5.26 ± 0.33 (exact 6). Cost is polynomial: degree grows linearly with refinement m and each product costs (mL)⁴ | Sharpened: \|det\| and zero modes are computable in practice |
| Craig: compare chiral projectors across spacings | Zero-mode projectors at a and a/2 agree to principal cosines ≥ 0.99971 (5̄: 0.99982, 0.99981; 10: 0.99971–0.99977) | Agrees |
| New | Witten's operator already gives the correct index at spacing a (gap ratio 27 for the 5̄, 14 for the 10). Spacing a/2 sharpens the zero modes from 0.03–0.05 to below 0.001 | New |
| §4 Monte Carlo is blocked by the phase e^{−iπη(D_Y)} | Next run | Open |

## 5. Implementation

```bash
pip install numpy scipy
python3 run.py A && python3 run.py B && python3 run.py C   # sampler, interpolation, fermions
python3 hybrid.py                                         # Witten's bound, Craig comparison, Chebyshev counts
python3 trees.py                                          # tree gauges on the 3- and 4-cube
```

## 6. Data

Witten's paper fixes the theory, the geometry and the construction, and reports no numerical runs. The data here is his exact setup, run: SU(5) with 5̄ ⊕ 10 on the 4-torus, with admissible fields built by his construction. The lattice size is set by the machine.

## Next

The phase e^{−iπη(D_Y)} on Y = T³ × D across the sampled ensemble. Its spread decides whether Monte Carlo works in practice.
