import Lean
open Lean

/-!
Counts the declarations stored in the compiled files of the project (all modules whose name has
the prefix `AaronsonAmbainis`).  A kernel replay of the project reports the number of declarations
that it has checked; this count is an independent way to obtain the same number.

The script only reads `.olean` files.  The project must have been built (`lake build`) before.

Run:  lake env lean --run scripts/count_declarations.lean
-/

unsafe def main (_ : List String) : IO UInt32 := do
  initSearchPath (← findSysroot)
  let sp ← searchPathRef.get
  let target := `AaronsonAmbainis
  let mut mods : Array Name := #[]
  for path in (← SearchPath.findAllWithExt sp "olean") do
    if let some m := (← searchModuleNameOfFileName path sp) then
      if target.isPrefixOf m then
        unless mods.contains m do mods := mods.push m
  let mut nDefn := 0
  let mut nThm := 0
  let mut nAxiom := 0
  let mut nOpaque := 0
  let mut nQuot := 0
  let mut nIndBlocks := 0
  let mut nInd := 0
  let mut nCtor := 0
  let mut nRec := 0
  let mut nSkipped := 0
  let mut nAll := 0
  let mut found : Array String := #[]
  for m in mods do
    let f ← findOLean m
    let (mod, _) ← readModuleData f
    for ci in mod.constants do
      nAll := nAll + 1
      if ci.isUnsafe || ci.isPartial then
        nSkipped := nSkipped + 1
      else
        match ci with
        | .defnInfo _ => nDefn := nDefn + 1
        | .thmInfo _ =>
          nThm := nThm + 1
          if m == `AaronsonAmbainis.Main then
            found := found.push s!"{ci.name} (theorem, in {m})"
        | .axiomInfo _ => nAxiom := nAxiom + 1
        | .opaqueInfo _ => nOpaque := nOpaque + 1
        | .quotInfo _ => nQuot := nQuot + 1
        | .inductInfo v =>
          nInd := nInd + 1
          if v.all.head? == some v.name then nIndBlocks := nIndBlocks + 1
        | .ctorInfo _ => nCtor := nCtor + 1
        | .recInfo _ => nRec := nRec + 1
  IO.println s!"modules with prefix AaronsonAmbainis: {mods.size}"
  IO.println s!"constants in these modules: {nAll}; unsafe or partial (skipped by a replay): {nSkipped}"
  IO.println s!"definitions {nDefn}; theorems {nThm}; axioms {nAxiom}; opaque {nOpaque}; quot {nQuot}"
  IO.println s!"inductive types {nInd} in {nIndBlocks} blocks; constructors {nCtor}; recursors {nRec}"
  IO.println s!"declarations a replay adds (definitions + theorems + axioms + opaque + quot + inductive blocks): {nDefn + nThm + nAxiom + nOpaque + nQuot + nIndBlocks}"
  for s in found do IO.println s!"final theorem: {s}"
  return 0
