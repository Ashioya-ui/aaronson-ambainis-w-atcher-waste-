import AaronsonAmbainis.DetLow.Basic

/-!
# DetLow: the degree of the determinant of the agreement matrix in each variable

In each variable the determinant of the agreement matrix has degree at most the number of ones
of `g`. This is a step of the proof of Lemma 3.6 of the paper.
-/

namespace AaronsonAmbainis
namespace DetLow

open Finset MvPolynomial

variable {ι : Type} [Fintype ι] [DecidableEq ι]

/-- Each entry of the agreement matrix has degree at most one in each variable. -/
theorem degreeOf_agMon_le (x z : Cube ι) (j : ι) : degreeOf j (agMon x z) ≤ 1 := by
  unfold agMon
  refine (degreeOf_prod_le j univ _).trans ?_
  calc ∑ i, degreeOf j (if x i = z i then (X i : MvPolynomial ι ℤ) else 1)
      ≤ ∑ i, (if j = i then 1 else 0) := by
        apply Finset.sum_le_sum
        intro i _
        by_cases h : x i = z i
        · rw [if_pos h, degreeOf_X]
        · rw [if_neg h, degreeOf_one]
          exact Nat.zero_le _
    _ = 1 := by simp

/-- In the variable `s_j` the determinant of the agreement matrix has degree at most the number
of ones of `g` (proof of Lemma 3.6 of the paper). -/
theorem degreeOf_det_le (g : Cube ι → Bool) (j : ι) :
    degreeOf j (agMatrix g).det ≤ Fintype.card (Ones g) := by
  have hc : ∀ n : ℤ, degreeOf j ((n : MvPolynomial ι ℤ)) = 0 := by
    intro n
    rw [← eq_intCast (C : ℤ →+* MvPolynomial ι ℤ) n, degreeOf_C]
  rw [Matrix.det_apply']
  refine (degreeOf_sum_le j univ _).trans ?_
  apply Finset.sup_le
  intro σ _
  refine (degreeOf_mul_le j _ _).trans ?_
  rw [hc, zero_add]
  refine (degreeOf_prod_le j univ _).trans ?_
  calc ∑ i : Ones g, degreeOf j (agMatrix g (σ i) i) ≤ ∑ _i : Ones g, 1 :=
        Finset.sum_le_sum (fun i _ => degreeOf_agMon_le _ _ j)
    _ = Fintype.card (Ones g) := by simp

end DetLow
end AaronsonAmbainis
