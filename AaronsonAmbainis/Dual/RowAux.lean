import AaronsonAmbainis.RowDefs
import AaronsonAmbainis.TwoSided.Basic

/-!
# The row bound from the packing bound and duality

`Dual.rowBoundPM_of_packing_of_cover : PackingBound → CoverDuality → RowBoundPM`
(Theorem 6.8 of the paper from Lemma 6.5 and linear-programming duality, Proposition 6.7). As in
the paper, at each point `x` duality is applied to the demands `t S = |f x - f (x^S)|` with
`K = π² d²`; then `S = Δ(x,y)`.
-/

namespace AaronsonAmbainis
namespace Dual

open Finset

theorem rowBoundPM_of_packing_of_cover : PackingBound → CoverDuality → RowBoundPM := by
  intro hPB hCD ι _ _ d f hf hdeg
  have key : ∀ x : Cube ι, ∃ a : ι → ℝ, (∀ i, 0 ≤ a i) ∧
      ∑ i, a i ≤ Real.pi ^ 2 * (d : ℝ) ^ 2 ∧
      ∀ S : Finset ι, |f x - f (flipSet x S)| ≤ ∑ i ∈ S, a i := by
    intro x
    refine hCD ι (fun S => |f x - f (flipSet x S)|) (Real.pi ^ 2 * (d : ℝ) ^ 2)
      (by positivity) ?_ ?_
    · -- `t ∅ = 0`
      rw [flipSet_empty, sub_self, abs_zero]
    · -- the hypothesis of `CoverDuality` is `PackingBound` at `x`
      intro κ hκ hpack
      exact hPB ι d f hf hdeg x κ hκ hpack
  choose a ha0 haK hacov using key
  refine ⟨a, ha0, haK, fun x y => ?_⟩
  have h := hacov x (diffSet x y)
  rwa [flipSet_diffSet] at h

end Dual
end AaronsonAmbainis
