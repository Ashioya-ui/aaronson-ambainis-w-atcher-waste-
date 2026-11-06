#!/usr/bin/env python3
"""Static audit of the Lean sources.

Usage:  check_no_placeholders.py PATH [PATH ...] [--holes FILE=N] [--json REPORT.json]

Every `.lean` file below the given paths is read, comments and string literals are removed, and
the remaining code is searched for the words listed in `FORBIDDEN`:

  placeholder   an unfinished proof
  assumption    a declaration that is accepted without proof
  kernel        a way to have a declaration accepted without the kernel checking its proof
  elaboration   new syntax or code that runs while a file is elaborated
  option        a change of an option of Lean

The library uses none of them. The exit status is 0 exactly if nothing is found.

The one exception is declared on the command line: `--holes FILE=N` says that the file FILE (the
challenge of a comparator run, which states theorems and leaves their proofs open) contains the
word `sorry` exactly N times. These N occurrences are not reported; any other number of them is,
and so is every other word of the list in that file.

This is a test of the source text only. What the kernel has accepted is tested by
`make axioms` and `make replay`.
"""
import argparse
import json
import os
import re
import sys

FORBIDDEN = {
    "placeholder": ["sorry", "admit", "stop"],
    "assumption": ["axiom", "opaque", "constant"],
    "kernel": [
        "native_decide", "ofReduceBool", "ofReduceNat", "implemented_by", "extern", "unsafe",
        "partial", "csimp", "skipKernelTC", "addDeclWithoutChecking",
    ],
    "elaboration": [
        "run_cmd", "run_elab", "run_meta", "elab", "elab_rules", "macro", "macro_rules",
        "syntax", "declare_syntax_cat", "notation", "infix", "infixl", "infixr", "prefix",
        "postfix", "initialize", "builtin_initialize",
    ],
    "option": ["set_option"],
}

# These occur as the last component of a longer name (`debug.skipKernelTC`, `Lean.ofReduceBool`),
# so they are searched for as plain substrings.
SUBSTRING = {"skipKernelTC", "addDeclWithoutChecking", "ofReduceBool", "ofReduceNat"}

NAME_CHAR = r"A-Za-z0-9_'!?"


def strip_comments_and_strings(src):
    """Replace comments and string literals by blanks; line breaks are kept."""
    out = []
    i, n, depth = 0, len(src), 0
    while i < n:
        if depth > 0:
            if src.startswith("/-", i):
                depth += 1
                i += 2
            elif src.startswith("-/", i):
                depth -= 1
                i += 2
            else:
                if src[i] == "\n":
                    out.append("\n")
                i += 1
        elif src.startswith("/-", i):
            depth = 1
            i += 2
        elif src.startswith("--", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src[i] == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            out.append("\n" * src.count("\n", i, j + 1))
            i = j + 1
        else:
            out.append(src[i])
            i += 1
    if depth != 0:
        raise ValueError("a block comment is not closed")
    return "".join(out)


def pattern(word):
    if word in SUBSTRING:
        return re.compile(re.escape(word))
    return re.compile(r"(?<![" + NAME_CHAR + r".])" + re.escape(word) + r"(?![" + NAME_CHAR + r"])")


def lean_files(paths):
    found = []
    for path in paths:
        if os.path.isfile(path):
            found.append(path)
            continue
        for directory, subdirs, files in os.walk(path):
            subdirs[:] = sorted(d for d in subdirs if not d.startswith("."))
            found.extend(os.path.join(directory, f) for f in sorted(files) if f.endswith(".lean"))
    return sorted(set(found))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--holes", action="append", default=[], metavar="FILE=N")
    parser.add_argument("--json", dest="json_path")
    args = parser.parse_args()

    holes = {}
    for item in args.holes:
        name, _, number = item.rpartition("=")
        if not name or not number.isdigit():
            parser.error("--holes expects FILE=N")
        holes[os.path.normpath(name)] = int(number)

    patterns = [(kind, word, pattern(word)) for kind, words in FORBIDDEN.items() for word in words]
    counts = {word: 0 for _, word, _ in patterns}
    findings, parse_errors = [], []
    files = lean_files(args.paths)
    hole_errors = ["%s: named by --holes, but not among the files read" % name
                   for name in sorted(holes) if name not in {os.path.normpath(f) for f in files}]
    for path in files:
        allowed = holes.get(os.path.normpath(path))
        in_file = []
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
        try:
            code = strip_comments_and_strings(source)
        except ValueError as err:
            parse_errors.append({"file": path, "error": str(err)})
            continue
        original = source.split("\n")
        for number, line in enumerate(code.split("\n"), start=1):
            for kind, word, regex in patterns:
                if regex.search(line):
                    item = {"file": path, "line": number, "kind": kind, "word": word,
                            "text": original[number - 1].strip()}
                    if allowed is not None and word == "sorry":
                        in_file.extend([item] * len(regex.findall(line)))
                    else:
                        counts[word] += 1
                        findings.append(item)
        if allowed is not None and len(in_file) != allowed:
            hole_errors.append("%s: %d times `sorry`, but --holes says %d"
                               % (path, len(in_file), allowed))
            counts["sorry"] += len(in_file)
            findings.extend(in_file)

    report = {"files_scanned": len(files), "counts": counts, "findings": findings,
              "parse_errors": parse_errors, "permitted_holes": holes, "hole_errors": hole_errors}
    if args.json_path:
        with open(args.json_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2, sort_keys=True)
            handle.write("\n")

    for item in findings:
        print("%s:%d: %s (%s): %s" % (item["file"], item["line"], item["word"], item["kind"],
                                      item["text"]))
    for item in parse_errors:
        print("%s: %s" % (item["file"], item["error"]))
    for item in hole_errors:
        print(item)
    if not files:
        print("no Lean file found")
        return 1
    print("static audit: %d files, %d findings, %d files that could not be read"
          % (len(files), len(findings), len(parse_errors)))
    if holes:
        print("static audit: permitted open proofs: %s"
              % ", ".join("%d in %s" % (holes[name], name) for name in sorted(holes)))
    return 1 if findings or parse_errors or hole_errors else 0


if __name__ == "__main__":
    sys.exit(main())
