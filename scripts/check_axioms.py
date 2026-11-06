#!/usr/bin/env python3
"""Checks the output of `scripts/print_axioms.sh`.

Usage:  check_axioms.py AXIOM_REPORT.txt

  1. Every line "'NAME' depends on axioms: [...]" lists only the three axioms in `ALLOWED`.
  2. The report covers each theorem in `REQUIRED`.
  3. The report mentions no other axiom anywhere (in particular not `sorryAx`).

The exit status is 0 exactly if the three checks pass.
"""
import re
import sys

ALLOWED = {"propext", "Classical.choice", "Quot.sound"}

REQUIRED = [
    "AaronsonAmbainis.aaronson_ambainis",
    "AaronsonAmbainis.aaronson_ambainis_explicit",
    "AaronsonAmbainis.aaronson_ambainis_pm",
    "AaronsonAmbainis.aaronson_ambainis_of_fbsDegreeBound",
]

DEPENDS = re.compile(r"'([^']+)' depends on axioms:\s*\[(.*?)\]", re.S)
FREE = re.compile(r"'([^']+)' does not depend on any axioms")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        text = handle.read()

    reported, errors = {}, []
    for name, axioms in DEPENDS.findall(text):
        reported[name] = {a.strip() for a in axioms.split(",") if a.strip()}
    for name in FREE.findall(text):
        reported[name] = set()

    for name, axioms in sorted(reported.items()):
        extra = axioms - ALLOWED
        if extra:
            errors.append("%s depends on %s" % (name, ", ".join(sorted(extra))))
    for name in REQUIRED:
        if name not in reported:
            errors.append("no axiom report for %s" % name)
    if "sorryAx" in text:
        errors.append("the report mentions sorryAx")
    if re.search(r"\berror\b", text):
        errors.append("the report contains an error message")

    for error in errors:
        print("axiom check:", error)
    print("axiom check: %d declarations reported, %d errors; allowed axioms: %s"
          % (len(reported), len(errors), ", ".join(sorted(ALLOWED))))
    return 1 if errors or not reported else 0


if __name__ == "__main__":
    sys.exit(main())
