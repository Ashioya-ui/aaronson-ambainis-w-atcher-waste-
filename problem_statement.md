# The Aaronson–Ambainis conjecture

**Conjecture (Aaronson and Ambainis).** Let `p : R^N → R` be a polynomial of degree `d`. Suppose that `0 ≤ p(X) ≤ 1` for all `X ∈ {0,1}^N`, and `E_X[(p(X) − E[p])²] ≥ ε`. Then there exists an `i` such that `Inf_i[p] ≥ (ε/d)^{O(1)}`.

Here `X` is uniform on `{0,1}^N`, the point `X^i` is `X` with the `i`-th bit flipped, and

```text
Inf_i[p] := E_X[(p(X) − p(X^i))²].
```

This is Conjecture 6 of S. Aaronson and A. Ambainis, *The need for structure in quantum speedups*, [arXiv:0911.0996v3](https://arxiv.org/abs/0911.0996v3), and Conjecture 1.7 of the journal version, Theory of Computing 10 (2014), 133–166.

## The same question on the cube {−1,1}^n

Determine whether there exists a function δ(ε, d) > 0, bounded below by a polynomial in ε and 1/d, such that every multilinear polynomial f : {−1, 1}^n → [−1, 1] of degree at most d with variance at least ε has a coordinate i with influence Inf_i(f) ≥ δ(ε, d).

Here `Inf_i(f) = E[((f(x) − f(x^i))/2)²]`. The substitution `f = 2p − 1`, `x = 1 − 2X` carries one form to the other: the degree and the influences are unchanged and the variance is multiplied by 4.

## Statement formalized here

The answer is yes, with explicit bounds.

1. Let `p` be a real polynomial in `N` variables of total degree at most `d` with `0 ≤ p ≤ 1` on `{0,1}^N` and with variance at least `ε > 0`. Then some variable `i` has

   ```text
   Inf_i[p] ≥ (8√15 / (125 π^4)) · ε^{5/2} / d^6     and     Inf_i[p] ≥ (ε/d)^7.
   ```

2. Let `f` be a real polynomial in `n` variables of total degree at most `d` with `|f| ≤ 1` on `{−1,1}^n` and with variance at least `ε > 0`. Then some coordinate `i` has

   ```text
   Inf_i(f) ≥ (√15 / (500 π^4)) · ε^{5/2} / d^6.
   ```

3. If Theorem 1.7 of A. Agarwal and S. Ben-David, [arXiv:2410.19062](https://arxiv.org/abs/2410.19062), is taken as a hypothesis, the first bound in item 1 holds with the constant `32√15 / (125 π^4)` in place of `8√15 / (125 π^4)`.

(The hypotheses force `N ≥ 1` and `d ≥ 1`, since a constant has variance zero. They also force `ε ≤ 1/4` in item 1 and `ε ≤ 1` in item 2; for such `ε` we have `ε^{5/2} ≥ ε^3`, so each of the bounds is at least a positive constant times `ε^3 / d^6`.)

The exact Lean targets are the propositions of [`AaronsonAmbainis/Conjecture.lean`](AaronsonAmbainis/Conjecture.lean), a file that imports only Mathlib. In `Conjecture.lean` the power `ε^{5/2}` is the real power `ε ^ ((5 : ℝ) / 2)`, and `√15` is `Real.sqrt 15`; for example, the bound of item 2 reads `Real.sqrt 15 / (500 * Real.pi ^ 4) * ε ^ ((5 : ℝ) / 2) / (d : ℝ) ^ 6`.

| Statement | Lean proposition | Lean theorem |
| --- | --- | --- |
| item 1, bound `(ε/d)^7` | `AaronsonAmbainis.PrintedConjecture` | `AaronsonAmbainis.aaronson_ambainis` |
| item 1, bound `(8√15 / (125 π^4)) · ε^{5/2} / d^6` | `AaronsonAmbainis.ExplicitBound` | `AaronsonAmbainis.aaronson_ambainis_explicit` |
| item 2 | `AaronsonAmbainis.ExplicitBoundPM` | `AaronsonAmbainis.aaronson_ambainis_pm` |
| item 3 | `AaronsonAmbainis.FbsDegreeBound → AaronsonAmbainis.ExplicitBoundImproved` | `AaronsonAmbainis.aaronson_ambainis_of_fbsDegreeBound` |

The theorems are in [`AaronsonAmbainis/Main.lean`](AaronsonAmbainis/Main.lean). The same bounds without square roots, `192 ε^5 ≤ 3125 π^8 d^12 Inf_i[p]^2` for item 1, `3 ε^5 ≤ 50000 π^8 d^12 Inf_i(f)^2` for item 2 and `3072 ε^5 ≤ 3125 π^8 d^12 Inf_i[p]^2` for item 3, are the theorems `AaronsonAmbainis.Bridge.explicitBound_sq`, `AaronsonAmbainis.Bridge.explicitBoundPM_sq` and `AaronsonAmbainis.Bridge.explicitBoundImproved_sq_of_fbsDegreeBound` of `AaronsonAmbainis/Bridge/Capstone.lean`.
