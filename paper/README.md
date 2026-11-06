# Paper

`aaronson_ambainis_paper.pdf` is the paper of this repository:

**David Turturean, "A proof of the Aaronson–Ambainis conjecture" (November 2026).**

The LaTeX source is `aaronson_ambainis_paper.tex`. Build it with:

```bash
make
```

A compiled PDF is committed, so the paper can be read without a TeX installation.

The paper is self-contained; it refers to the formalization only through a link to this repository.
[`notes/PAPER_TO_LEAN.md`](../notes/PAPER_TO_LEAN.md) maps its numbered statements to the Lean
declarations of this repository.

The committed PDF was rebuilt from this TeX on remote compute for the November 2026 release.
The release-files workflow checks the PDF date and hyperlink, both checksum manifests,
and the citation metadata. Building the paper does not build the Lean development.
