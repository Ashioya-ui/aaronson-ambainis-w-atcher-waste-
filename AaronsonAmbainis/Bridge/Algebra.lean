import AaronsonAmbainis.Bridge.Fourier

/-!
# Closure properties of `HasDegreeLE`

`HasDegreeLE` is closed under constants, sums, scalar multiples, products (degrees add), powers
and finite products; the coordinate functions have degree at most `1`.
These are what makes `HasDegreeLE` a degree in the usual sense.
-/

namespace AaronsonAmbainis.Bridge

open Finset

variable {ι : Type*} [Fintype ι] [DecidableEq ι]

theorem hasDegreeLE_const (a : ℝ) (d : ℕ) : HasDegreeLE (fun _ : Cube ι => a) d :=
  hasDegreeLE_mono (hasDegreeLE_zero_iff.mpr ⟨a, fun _ => rfl⟩) (Nat.zero_le d)

omit [DecidableEq ι] in
theorem hasDegreeLE_add {f g : Cube ι → ℝ} {d : ℕ} (hf : HasDegreeLE f d)
    (hg : HasDegreeLE g d) : HasDegreeLE (fun x => f x + g x) d := by
  obtain ⟨a, ha, hfa⟩ := hf
  obtain ⟨b, hb, hgb⟩ := hg
  refine ⟨fun S => a S + b S, fun S hS => by show a S + b S = 0; rw [ha S hS, hb S hS, add_zero], fun x => ?_⟩
  show f x + g x = ∑ S, (a S + b S) * chi S x
  simp only [add_mul, Finset.sum_add_distrib]
  rw [← hfa x, ← hgb x]

omit [DecidableEq ι] in
theorem hasDegreeLE_smul (r : ℝ) {f : Cube ι → ℝ} {d : ℕ} (hf : HasDegreeLE f d) :
    HasDegreeLE (fun x => r * f x) d := by
  obtain ⟨a, ha, hfa⟩ := hf
  refine ⟨fun S => r * a S, fun S hS => by show r * a S = 0; rw [ha S hS, mul_zero], fun x => ?_⟩
  show r * f x = ∑ S, r * a S * chi S x
  rw [hfa x, Finset.mul_sum]
  refine Finset.sum_congr rfl (fun S _ => ?_)
  ring

theorem hasDegreeLE_sum {α : Type*} (s : Finset α) {F : α → Cube ι → ℝ} {d : ℕ}
    (h : ∀ k ∈ s, HasDegreeLE (F k) d) : HasDegreeLE (fun x => ∑ k ∈ s, F k x) d := by
  classical
  induction s using Finset.induction_on with
  | empty => simpa using hasDegreeLE_const (ι := ι) 0 d
  | insert k s hk ih =>
    have h1 : HasDegreeLE (fun x => F k x + ∑ k ∈ s, F k x) d :=
      hasDegreeLE_add (h k (Finset.mem_insert_self k s))
        (ih (fun k' hk' => h k' (Finset.mem_insert_of_mem hk')))
    have h2 : (fun x => ∑ k ∈ insert k s, F k x) = fun x => F k x + ∑ k ∈ s, F k x := by
      funext x
      rw [Finset.sum_insert hk]
    rw [h2]
    exact h1

theorem hasDegreeLE_chi (S : Finset ι) : HasDegreeLE (chi S) S.card :=
  (hasDegreeLE_chi_iff S S.card).mpr le_rfl

omit [Fintype ι] in
theorem card_symmDiff_le (S T : Finset ι) : (symmDiff S T).card ≤ S.card + T.card := by
  refine le_trans (Finset.card_le_card ?_) (Finset.card_union_le S T)
  intro i hi
  rw [Finset.mem_symmDiff] at hi
  rw [Finset.mem_union]
  rcases hi with ⟨h, _⟩ | ⟨h, _⟩
  · exact Or.inl h
  · exact Or.inr h

/-- Degrees add under multiplication. -/
theorem hasDegreeLE_mul {f g : Cube ι → ℝ} {d e : ℕ} (hf : HasDegreeLE f d)
    (hg : HasDegreeLE g e) : HasDegreeLE (fun x => f x * g x) (d + e) := by
  obtain ⟨a, ha, hfa⟩ := hf
  obtain ⟨b, hb, hgb⟩ := hg
  have h1 : (fun x => f x * g x)
      = fun x => ∑ S : Finset ι, ∑ T : Finset ι, (a S * b T) * chi (symmDiff S T) x := by
    funext x
    rw [hfa x, hgb x, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl (fun S _ => Finset.sum_congr rfl (fun T _ => ?_))
    rw [← chi_mul_chi]
    ring
  rw [h1]
  refine hasDegreeLE_sum _ (fun S _ => hasDegreeLE_sum _ (fun T _ => ?_))
  by_cases hS : d < S.card
  · have h0 : (fun x => a S * b T * chi (symmDiff S T) x) = fun _ => 0 := by
      funext x
      rw [ha S hS]
      ring
    rw [h0]
    exact hasDegreeLE_const 0 _
  · by_cases hT : e < T.card
    · have h0 : (fun x => a S * b T * chi (symmDiff S T) x) = fun _ => 0 := by
        funext x
        rw [hb T hT]
        ring
      rw [h0]
      exact hasDegreeLE_const 0 _
    · refine hasDegreeLE_smul _ (hasDegreeLE_mono (hasDegreeLE_chi _) ?_)
      exact (card_symmDiff_le S T).trans (Nat.add_le_add (not_lt.mp hS) (not_lt.mp hT))

theorem hasDegreeLE_pow {g : Cube ι → ℝ} {k : ℕ} (hg : HasDegreeLE g k) (m : ℕ) :
    HasDegreeLE (fun x => g x ^ m) (m * k) := by
  induction m with
  | zero => simpa using hasDegreeLE_const (ι := ι) 1 0
  | succ m ih =>
    have h2 : (fun x => g x ^ (m + 1)) = fun x => g x ^ m * g x := by
      funext x
      rw [pow_succ]
    rw [h2, add_one_mul]
    exact hasDegreeLE_mul ih hg

theorem hasDegreeLE_prod {α : Type*} (s : Finset α) {F : α → Cube ι → ℝ} {k : α → ℕ}
    (h : ∀ a ∈ s, HasDegreeLE (F a) (k a)) :
    HasDegreeLE (fun x => ∏ a ∈ s, F a x) (∑ a ∈ s, k a) := by
  classical
  induction s using Finset.induction_on with
  | empty => simpa using hasDegreeLE_const (ι := ι) 1 0
  | insert a s ha ih =>
    have h2 : (fun x => ∏ a ∈ insert a s, F a x) = fun x => F a x * ∏ a ∈ s, F a x := by
      funext x
      rw [Finset.prod_insert ha]
    rw [h2, Finset.sum_insert ha]
    exact hasDegreeLE_mul (h a (Finset.mem_insert_self a s))
      (ih (fun a' ha' => h a' (Finset.mem_insert_of_mem ha')))

/-- The `±1` coordinate function has degree at most `1`. -/
theorem hasDegreeLE_pm_coord (i : ι) :
    HasDegreeLE (fun x : Cube ι => if x i then (-1 : ℝ) else 1) 1 :=
  dict_hasDegreeLE_one i

/-- The `0/1` coordinate function has degree at most `1`. -/
theorem hasDegreeLE_zo_coord (i : ι) :
    HasDegreeLE (fun x : Cube ι => if x i then (1 : ℝ) else 0) 1 := by
  have h : (fun x : Cube ι => if x i then (1 : ℝ) else 0)
      = fun x => (1 / 2 : ℝ) + (-1 / 2) * dict i x := by
    funext x
    unfold dict
    split_ifs <;> norm_num
  rw [h]
  exact hasDegreeLE_add (hasDegreeLE_const _ 1) (hasDegreeLE_smul _ (dict_hasDegreeLE_one i))

end AaronsonAmbainis.Bridge
