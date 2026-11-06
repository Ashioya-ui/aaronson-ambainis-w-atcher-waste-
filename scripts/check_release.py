#!/usr/bin/env python3
"""Check the tracked publication files, without building Lean or changing files.

The staging repo contains files excluded by .publishignore. Validate the exported
set there; in the publication repo, also reject any excluded file left in Git.
CITATION.cff schema validation is a separate cffconvert step in release-check.yml.
"""
import fnmatch
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_REPO = "physical-superintelligence/aaronson-ambainis"
PUBLIC_URL = "https://github.com/" + PUBLIC_REPO
PAPER = "paper/aaronson_ambainis_paper"
REQUIRED = {
    "README.md", "CITATION.cff", "LICENSE", "Makefile", ".publishignore",
    "lakefile.toml", "lake-manifest.json", "lean-toolchain",
    "AaronsonAmbainis.lean", "AaronsonAmbainis/Main.lean",
    "AaronsonAmbainis/Conjecture.lean", "paper/Makefile", "paper/SHA256SUMS",
    PAPER + ".tex", PAPER + ".pdf", "SHA256SUMS",
    ".github/workflows/build-lean.yml", ".github/workflows/comparator.yml",
    ".github/workflows/release-check.yml", "verification/comparator/README.md",
}
PRIVATE_LINK = re.compile(
    r"(?:github\.com|raw\.githubusercontent\.com)/"
    r"(?:psi-experiments/|physical-superintelligence/aaronson-ambainis"
    r"(?:-work|-development-archive)(?:[/#?\s]|$))", re.I
)
PLACEHOLDER = re.compile(
    r"\[(?:publication date|approved public model name|MODEL)\]"
    r"|Private\s+draft\s+for\s+review|Publication\s+date\s+remains\s+to\s+be\s+finalized", re.I
)


def main():
    errors = []
    tracked = set(subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode().rstrip("\0").split("\0"))
    rules = [line.strip() for line in (ROOT / ".publishignore").read_text().splitlines()
             if line.strip() and not line.lstrip().startswith("#")]

    def excluded(name):
        return any(name == rule.rstrip("/") or
                   name.startswith(rule.rstrip("/") + "/") or
                   fnmatch.fnmatchcase(name, rule) for rule in rules)

    ignored = {name for name in tracked if excluded(name)}
    released = tracked - ignored
    if os.environ.get("GITHUB_REPOSITORY") == PUBLIC_REPO and ignored:
        errors.append("publication repo contains excluded files: " + ", ".join(sorted(ignored)))
    for name in sorted(REQUIRED - released):
        errors.append("missing release file: " + name)

    def check_manifest(name, expected):
        manifest = ROOT / name
        listed = set()
        for line in manifest.read_text().splitlines():
            match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
            if not match:
                errors.append("malformed checksum in " + name)
                continue
            digest, relative = match.groups()
            path = Path(relative)
            if path.is_absolute() or ".." in path.parts:
                errors.append("unsafe checksum path in " + name + ": " + relative)
                continue
            full_name = (manifest.parent / path).relative_to(ROOT).as_posix()
            if full_name in listed:
                errors.append("duplicate checksum: " + full_name)
            listed.add(full_name)
            target = ROOT / full_name
            if not target.is_file() or hashlib.sha256(target.read_bytes()).hexdigest() != digest:
                errors.append("checksum mismatch: " + full_name)
        if listed != expected:
            errors.append(name + " coverage mismatch; missing=" + repr(sorted(expected - listed))
                          + "; unexpected=" + repr(sorted(listed - expected)))

    check_manifest("SHA256SUMS", released - {"SHA256SUMS"})
    check_manifest("paper/SHA256SUMS", {
        name for name in released if name.startswith("paper/") and name != "paper/SHA256SUMS"
    })
    for name in sorted(released):
        try:
            text = (ROOT / name).read_text()
        except UnicodeDecodeError:
            continue
        if name == "verification/comparator/README.md":
            # A specifically labeled staging run is provenance, not a public
            # verification link. Its outputs must also be copied into the repo.
            text = re.sub(
                r"(?m)^Private staging run \(historical\): "
                + re.escape(PUBLIC_URL + "-work/actions/runs/") + r"[0-9]+$", "", text
            )
        if PRIVATE_LINK.search(text):
            errors.append("private publication link: " + name)
        if PLACEHOLDER.search(text):
            errors.append("draft placeholder: " + name)

    cff = (ROOT / "CITATION.cff").read_text()
    if not re.search(r'^repository-code:\s*[\"\']?' + re.escape(PUBLIC_URL)
                     + r'[\"\']?\s*$', cff, re.M):
        errors.append("CITATION.cff must use the publication repository")
    tex = (ROOT / (PAPER + ".tex")).read_text()
    date = re.search(r"\\date\{([^}]+)\}", tex)
    if not date or PUBLIC_URL not in tex:
        errors.append("paper source lacks its date or publication link")
    pdf = str(ROOT / (PAPER + ".pdf"))
    page_text = subprocess.check_output(
        ["pdftotext", "-f", "1", "-l", "2", pdf, "-"], text=True
    )
    urls = subprocess.check_output(["pdfinfo", "-url", pdf], text=True)
    if date and date.group(1) not in " ".join(page_text.split()):
        errors.append("PDF date does not match the TeX date")
    if PUBLIC_URL not in urls or PRIVATE_LINK.search(urls):
        errors.append("PDF does not have the correct clickable publication link")
    for error in errors:
        print("release check:", error, file=sys.stderr)
    if errors:
        return 1
    print(f"release check: {len(released)} publication files; checksums, links, PDF and metadata OK")
    print(f"Excluded staging files: {len(ignored)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
