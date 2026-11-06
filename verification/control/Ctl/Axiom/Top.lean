-- A solution for comparator that proves the statement of `Ctl.goodTop` from a new axiom.
-- This file is a control: comparator must reject it, because the axiom is not permitted.
axiom Ctl.extra : (2 : Nat) + 2 = 4 ∧ True

theorem Ctl.goodTop : (2 : Nat) + 2 = 4 ∧ True := Ctl.extra

#print axioms Ctl.goodTop
