import Lean
open Lean Elab Command

-- A false statement, added while the kernel is switched off. This file is a control: it is
-- meant to be rejected by a kernel replay. See README.md in this directory.
set_option debug.skipKernelTC true in
run_cmd liftCoreM (addDecl (Declaration.thmDecl { name := `Ctl.bad, levelParams := [], type := mkConst ``False, value := mkConst ``True.intro }))

#print axioms Ctl.bad
