import Ctl.Bad.Base

-- A consequence of the false statement of `Ctl.Bad.Base`. This file is a control.
theorem Ctl.top : (1 : Nat) = 2 := False.elim Ctl.bad

#print axioms Ctl.top
