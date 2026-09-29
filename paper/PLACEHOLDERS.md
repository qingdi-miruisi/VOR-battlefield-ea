# Metadata completion record

**Status: all placeholders filled. One item remains pending by design (item 2).**

Submitted values (supplied by the corresponding author):

| Field | Value |
|---|---|
| Corresponding author | Yuxuan Zhang |
| E-mail | 3150644070@qq.com |
| Affiliation | Graduate School, Army Engineering University of PLA, Nanjing, China |
| Journal target | Applied Soft Computing (Elsevier, Q1) |
| Title | A Dimension-Adaptive Evolutionary Algorithm with Epsilon-Grid Selection and Directed Decision-Space Operators for Large-Scale Multi-Objective Optimization |
| Repository policy | anonymised mirror during review; permanent public URL on acceptance |

---

## 1. Applied substitutions

| File | Field | Value now present |
|---|---|---|
| `paper/main.tex` | `\author[a]{}` | Yuxuan Zhang |
| `paper/main.tex` | `\ead{}` | 3150644070@qq.com |
| `paper/main.tex` | `\address[a]{}` | Graduate School, Army Engineering University of PLA, Nanjing, China |
| `paper/main.tex` | `\journal{}` | Applied Soft Computing |
| `paper/cover_letter.md` | date | 21 September 2026 |
| `paper/cover_letter.md` | journal | Applied Soft Computing |
| `paper/cover_letter.md` | signature | Yuxuan Zhang / Graduate School, Army Engineering University of PLA / Nanjing, China / 3150644070@qq.com |
| `docs/GITHUB_README.md` | BibTeX | `author = {Zhang, Yuxuan}`, `journal = {Applied Soft Computing}`, `year = {2026}` |

**Title decision.** Option A was selected and the leading `EDD:` prefix was
dropped. Rationale: at title level the acronym is undefined, and Option B
("Breaking the D=300 Barrier") contradicts the manuscript's own honest
framing — the paper states in its abstract, contributions and conclusion that
EDD is bimodal and ranks 9th–11th on three of the ten instances. A title
claiming to break the barrier would hand a reviewer the contradiction.

## 2. Pending — action required before submission (1 item)

| File(s) | Current text | Action |
|---|---|---|
| `paper/main.tex`, `paper/main.md`, `paper/cover_letter.md`, `docs/GITHUB_README.md` | `[anonymous repository URL, to be inserted before submission]` | create the anonymised mirror (e.g. `anonymous.4open.science`) and substitute the URL. Four occurrences. |

The permanent public URL should then be substituted in the accepted version.

**Related code edit, required for the repository to run on another machine.**
Every `experiments/*.m` driver hard-codes the local working directory, e.g.

```matlab
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
```

Replace with the path-agnostic form before publishing:

```matlab
cd(fileparts(fileparts(mfilename('fullpath'))));
```

or delete the line and document that the user runs from the repository root.
See `docs/UPLOAD_CHECKLIST.md` §6. This is the only code change required.

## 3. Verification performed

```
grep -rn "\[GitHub URL\]\|\[Corresponding author\]\|\[Affiliation\]\|\[Authors\]\|\[Year\]\|\[Date\]\|author@institution" paper
# no matches outside this record and the anonymised-repository placeholder
```

LaTeX compile (twice, so that cross-references resolve):

```
cd paper && pdflatex main.tex && pdflatex main.tex
# passed, 0 warnings on the second pass
# Output written on main.pdf (26 pages, 1 330 597 bytes)
```

Confirmed present in the compiled PDF: title, author name, affiliation,
e-mail, abstract, 5 tables, 6 figures, 18 references.

## 4. Remaining optional items

| Item | Note |
|---|---|
| `CITATION.cff` | create at repository root from the BibTeX entry in `docs/GITHUB_README.md` |
| `LICENSE`, `NOTICE` | see `docs/UPLOAD_CHECKLIST.md` §5.1 — the PlatEMO-derived directories are GPL-3.0, so a blanket Apache-2.0 notice must not be applied to them |
| `paper/main.md` vs `paper/main.tex` | both are complete manuscripts; after any further edit, treat `main.tex` as the source of truth and either regenerate `main.md` or delete it, to avoid divergence |
| Co-authors | if any exist, add one `\author[x]{}` and one `\address[x]{}` block per distinct affiliation in `paper/main.tex` |

## 5. Pre-submission checklist

- [x] Corresponding author, e-mail and affiliation in `main.tex`
- [x] Journal target set in `main.tex`, cover letter and README BibTeX
- [x] Title finalised (Option A without the acronym prefix)
- [x] Cover letter signed and dated
- [x] LaTeX compiles cleanly, 26 pages, all tables and figures resolved
- [ ] Anonymised repository URL created and substituted (4 occurrences)
- [ ] Hard-coded local paths removed from `experiments/*.m`
- [ ] `LICENSE` and `NOTICE` written with the PlatEMO attribution
- [ ] Co-author blocks added, if applicable
- [ ] Final read-through of `paper/main.tex` for journal-specific formatting
      (Elsevier reference style, word limits, figure resolution ≥ 300 dpi —
      the supplied figures are 180–200 dpi and may need regeneration at 300 dpi)
