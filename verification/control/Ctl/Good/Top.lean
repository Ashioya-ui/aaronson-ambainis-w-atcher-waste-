import Ctl.Good.Base

theorem Ctl.goodTop : (2 : Nat) + 2 = 4 ∧ True := ⟨Ctl.good, True.intro⟩

#print axioms Ctl.goodTop
