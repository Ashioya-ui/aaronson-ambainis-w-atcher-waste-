import AaronsonAmbainis.Main

/-!
# Comparator: the solution

The untrusted side of a run of comparator: the four theorems of `Challenge.lean` again, each
proved by naming the final theorem of `AaronsonAmbainis/Main.lean` that has the same type.

No file of the library imports this file.
-/

namespace AaronsonAmbainisComparator

theorem aaronson_ambainis : AaronsonAmbainis.PrintedConjecture :=
  AaronsonAmbainis.aaronson_ambainis

theorem aaronson_ambainis_explicit : AaronsonAmbainis.ExplicitBound :=
  AaronsonAmbainis.aaronson_ambainis_explicit

theorem aaronson_ambainis_pm : AaronsonAmbainis.ExplicitBoundPM :=
  AaronsonAmbainis.aaronson_ambainis_pm

theorem aaronson_ambainis_of_fbsDegreeBound :
    AaronsonAmbainis.FbsDegreeBound → AaronsonAmbainis.ExplicitBoundImproved :=
  AaronsonAmbainis.aaronson_ambainis_of_fbsDegreeBound

end AaronsonAmbainisComparator
