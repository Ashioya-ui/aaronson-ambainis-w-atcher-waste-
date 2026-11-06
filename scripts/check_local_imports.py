#!/usr/bin/env python3
"""Checks on the import graph of the project.

Usage:  check_local_imports.py REPOSITORY_ROOT LIBRARY

  1. Every import of a module of the library names a file that exists.
  2. Every Lean file of the library is imported, directly or not, by the root file
     `LIBRARY.lean`, so that `lake build` compiles all of them.
  3. The file `LIBRARY/Conjecture.lean`, which holds the statements, imports Mathlib and nothing
     else.
  4. The modules below `LIBRARY/Comparator/` (the two sides of a comparator run) are exempt from
     check 2, and no other module imports one of them.
  5. `LIBRARY/Comparator/Challenge.lean`, if it exists, imports `LIBRARY.Conjecture` and nothing
     else.

The exit status is 0 exactly if all checks pass.
"""
import os
import re
import sys

IMPORT = re.compile(r"^\s*(?:public\s+)?import\s+(\S+)\s*$")


def imports_of(path):
    """The modules imported by a file (imports come before everything except comments)."""
    result, depth = [], 0
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            text = line.strip()
            if depth > 0 or text.startswith("/-"):
                depth += text.count("/-") - text.count("-/")
                continue
            if not text or text.startswith("--"):
                continue
            match = IMPORT.match(line)
            if not match:
                break
            result.append(match.group(1))
    return result


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    root, library = sys.argv[1], sys.argv[2]

    def path_of(module):
        return os.path.join(root, *module.split(".")) + ".lean"

    modules = {library}
    for directory, subdirs, files in os.walk(os.path.join(root, library)):
        subdirs[:] = sorted(subdirs)
        for name in sorted(files):
            if name.endswith(".lean"):
                relative = os.path.relpath(os.path.join(directory, name), root)
                modules.add(relative[:-len(".lean")].replace(os.sep, "."))

    errors = []
    graph = {}
    for module in sorted(modules):
        if not os.path.isfile(path_of(module)):
            errors.append("the file of the module %s is missing" % module)
            graph[module] = []
            continue
        graph[module] = imports_of(path_of(module))
        for target in graph[module]:
            local = target == library or target.startswith(library + ".")
            if local and target not in modules:
                errors.append("%s imports %s, which has no file" % (module, target))

    reached, todo = set(), [library]
    while todo:
        module = todo.pop()
        if module in reached or module not in graph:
            continue
        reached.add(module)
        todo.extend(graph[module])
    judge = {m for m in modules if m.startswith(library + ".Comparator.")}
    for module in sorted(modules - reached - judge):
        errors.append("%s is not imported from the root file %s.lean" % (module, library))
    for module in sorted(modules - judge):
        for target in graph[module]:
            if target in judge:
                errors.append("%s imports the comparator module %s" % (module, target))

    statement = library + ".Conjecture"
    if graph.get(statement) != ["Mathlib"]:
        errors.append("%s must import Mathlib and nothing else; it imports %s"
                      % (statement, graph.get(statement)))

    challenge = library + ".Comparator.Challenge"
    if challenge in modules and graph.get(challenge) != [statement]:
        errors.append("%s must import %s and nothing else; it imports %s"
                      % (challenge, statement, graph.get(challenge)))

    for error in errors:
        print("import check:", error)
    print("import check: %d modules, %d comparator modules, %d errors"
          % (len(modules - judge), len(judge), len(errors)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
