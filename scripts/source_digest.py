#!/usr/bin/env python3
"""Prints one digest of the Lean project files.

Usage:  source_digest.py REPOSITORY_ROOT LIBRARY [--list]

The Lean project files are `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`, the root file
`LIBRARY.lean` and every `.lean` file below `LIBRARY/`, except the directory `LIBRARY/Comparator/`.
For each file the script forms the line "<sha256 of the file>  <path>"; the lines are sorted by
path and joined by newlines, and the digest is the sha256 of this text.  With `--list` the lines
are printed as well.

The two modules below `LIBRARY/Comparator/` are left out because no file of the library imports
them (`check_local_imports.py` checks this): they do not determine the compiled library.

The recorded checks in `notes/VERIFICATION.md` name the digest of the sources on which they ran.
"""
import hashlib
import os
import sys


def project_files(root, library):
    files = ["lakefile.toml", "lake-manifest.json", "lean-toolchain", library + ".lean"]
    for folder, subdirs, names in os.walk(os.path.join(root, library)):
        if folder == os.path.join(root, library):
            subdirs[:] = [d for d in subdirs if d != "Comparator"]
        for name in names:
            if name.endswith(".lean"):
                files.append(os.path.relpath(os.path.join(folder, name), root).replace(os.sep, "/"))
    return sorted(files)


def main():
    args = [a for a in sys.argv[1:] if a != "--list"]
    if len(args) != 2:
        print(__doc__)
        return 2
    root, library = args
    lines = []
    for rel in project_files(root, library):
        with open(os.path.join(root, rel), "rb") as handle:
            lines.append("%s  %s" % (hashlib.sha256(handle.read()).hexdigest(), rel))
    if "--list" in sys.argv[1:]:
        print("\n".join(lines))
    digest = hashlib.sha256("\n".join(lines).encode()).hexdigest()
    print("source digest: %s (%d files)" % (digest, len(lines)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
