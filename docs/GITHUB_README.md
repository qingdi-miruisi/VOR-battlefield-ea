# EDD — Epsilon-Grid Selection and Directed Decision-Space Operators for Large-Scale Multi-Objective Optimization

Reference implementation and complete experimental dataset for the manuscript

> **A Dimension-Adaptive Evolutionary Algorithm with Epsilon-Grid Selection
> and Directed Decision-Space Operators for Large-Scale Multi-Objective
> Optimization**

---

## 1. What EDD is

**EDD** is a single-population, dimension-adaptive evolutionary
multi-objective optimizer. Its environmental selection, offspring operator,
and final polishing step are all controlled by one Boolean computed from the
problem's dimensions:

```
highDim = (D >= 100) || (M >= 10)
```

| Regime | Environmental selection | Offspring operator |
|---|---|---|
| `D < 100` and `M < 10` | APD over an NBI reference set, with an HV-gated switch to SMS-EMO at 50/60/70 % of the budget | SBX + polynomial mutation |
| `D >= 100` or `M >= 10` | **EED** — epsilon-grid selection | **DSG** — directed decision-space operator |

The two branches share the convergence-gated polish-HV step applied in the
final 10 % of the budget.

### 1.1 Core mechanisms

**EED — Epsilon-Grid Environmental Selection.**
Given an offspring pool of size 2N, each of the M objectives is binned onto an
adaptive grid of `epsGrid = 10` cells spanning the pool's current
`[min, max]` range in that objective. Within each non-empty cell EDD retains
the solution nearest to the origin. If the surviving non-dominated set
exceeds N, the N points with the smallest ℓ₂ distance to the origin are kept;
if it falls below N, the set is filled from the next non-dominated front.
Cost is O(MN) per generation and **no reference vectors are required**, which
removes the reference-vector vacuum that collapses APD/NBI selection at
D = 300.

**DSG — Directed Decision-Space offspring operator.**
For each of N offspring:

1. Compute the 0.15 / 0.50 / 0.85 quantiles, along every decision dimension,
   of the top half of the current population (ranked by objective sum). This
   forms a three-segment fuzzy skeleton (low / mid / high).
2. Draw one segment uniformly at random per offspring, sample inside it, then
   apply a directed movement toward the per-segment quantile using a
   grey-wolf convergence factor `a = 2(1 − i/N)` and an M-adaptive random
   weight `wRand = 0.5 + 0.1·min(M,10)/10`.

The directed step scale is therefore set by the population's *own* per
-dimension spread, not by a dimension-independent crossover distribution —
which is why it continues to make progress where SBX degenerates into
undirected sampling at D = 300.

**Dimension-adaptive switching.**
The gate is computed once and never revisited. It is the single design choice
that makes EDD one algorithm rather than two code paths bolted together: at
large D both the selection layer and the variation layer are re-specified,
while the shared polish-HV step is common to both regimes.

### 1.2 Reported result, stated precisely

On **LSMOP1–9** (M = 3, D = 300) plus a cross-validation instance
**DTLZ2-300D-M3**, with 30 independent seeds per cell against ten baselines
(3 300 runs, 0 failures):

| Metric | EDD |
|---|---|
| **Combined IGD/HV Friedman rank** | **4.35 — 1st** |
| **HV Friedman rank** | **4.25 — 1st (tied with HCEA)** |
| **IGD Friedman rank** | **4.45 — 2nd** (MOEAD 1st at 4.20) |

The result is **structurally bimodal**, and this is reported rather than
averaged away:

- On **5 of the 10 instances** the baselines collapse to HV = 0; EDD (and, on
  LSMOP1/5/9 only, MOGWO) is the only algorithm that places part of its front
  on the true front. On LSMOP6 EDD reaches IGD 1.63 against 2 660.25 for
  HCEAV4, a factor of ~1 600.
- On the **3 instances where every algorithm converges** (LSMOP2/4/8) EDD
  ranks 9th–11th on IGD.

### 1.3 Component ablation — the key evidence

A four-variant ablation (`EDD_ABL`, 5 seeds, N = 100, G = 200) attributes both
the strengths and the costs to specific components:

| Variant | LSMOP6 | LSMOP9 | LSMOP2 |
|---|---:|---:|---:|
| **full EDD** | **1.631** | **1.548** | 0.4249 |
| no-EED (APD path at D = 300) | 4 716 (**2 892×** worse) | 42.62 (27.5× worse) | 0.1027 (**4.1× better**) |
| no-DSG (SBX offspring) | 224.2 (137× worse) | 9.075 (5.9× worse) | 0.4833 (1.1× worse) |
| no-polish | 1.631 (1.00×) | 1.548 (1.00×) | 0.3983 (0.93×) |

Three conclusions:

1. **On the collapse instances both components are individually necessary** —
   removing EED costs 2 892× on LSMOP6, removing DSG costs 137×.
2. **On the converged instance EED is actively harmful** — disabling it
   improves LSMOP2 IGD by 4.1× and more than doubles its hypervolume. This is
   the mechanistic cause of the bimodality.
3. **polish-HV shows no measurable effect at D = 300** (1.00× change in median
   IGD). Reported as a **negative result**; not claimed as a contribution.

---

## 2. Test problems

| Problem | M | D | Source |
|---|---|---|---|
| LSMOP1–9 | 3 | 300 | Cheng, Jin, Olhofer, Sendhoff, *IEEE Trans. Cybernetics* 47(12), 2017 |
| DTLZ2-300D-M3 | 3 | 300 | Deb, Thiele, Laumanns, Zitzler, *CEC 2002*, with D extended to 300 |

The DTLZ2-300D-M3 class is provided in `problems/DTLZ2_300D_M3.m` (25 lines,
standard DTLZ2 formulation with the distance variables spanning dimensions
`M … D`).

## 3. Comparison algorithms

Eleven algorithms in total: EDD plus ten baselines —
**HCEA, HCEAV4, NSGA-II, NSGA-III, SPEA2, AGEMOEA, SMSEMOA, MOGWO, RVEA,
MOEAD**.

Common protocol: population size `N = 100`, generations `G = 200`,
30 independent seeds (1…30), matched function-evaluation budgets.

Metrics: **IGD** (smaller is better; reference front = `ParetoFront(500)`) and
**HV** (larger is better; reference point = `1.1 × max(true front)`).
Statistical analysis: per-problem medians over 30 seeds, Friedman mean ranks
over 10 problems (ties averaged), problem-level Wilcoxon signed-rank with
Holm–Bonferroni correction.

---

## 4. Repository layout

```
algorithm/
├── algorithms/
│   ├── EDD.m                  ★ the proposed algorithm (418 lines, v12)
│   ├── EDD_ABL.m              ablation variant (generated; see make_edd_abl.m)
│   ├── HCEA.m, HCEAV4.m       prior work in the HCEA family
│   └── NSGA2.m NSGA3.m SPEA2.m AGEMOEA.m SMSEMOA.m MOGWO.m RVEA.m MOEAD.m
├── problems/
│   ├── DTLZ2_300D_M3.m        ★ new large-scale cross-validation instance
│   ├── LSMOP1..9 (via OfficialProblem adapter)
│   └── ... other benchmark families
├── problems_official/         PlatEMO-derived official problem classes
├── experiments/
│   ├── run_largescale_final.m main experiment driver (11 per-algorithm wrappers)
│   ├── friedman_10.m          Friedman ranks + Wilcoxon + Holm
│   ├── make_edd_abl.m         generates EDD_ABL.m from EDD.m (7 substitutions, asserted)
│   ├── run_ablation_edd.m     component ablation
│   ├── run_conv_a/b/c.m       convergence study (budget sweep)
│   ├── run_pf_data.m          Pareto front capture
│   ├── make_figs.m            convergence + ablation figures
│   ├── make_pf_figs.m         Pareto front figures
│   └── analyze_abl_conv.m     summary of ablation and convergence data
├── results/
│   ├── largescale_final/      ★ 3 300 runs (main experiment) + friedman_10.mat
│   ├── ablation_abl/          60 runs + ablation_summary.mat
│   └── figs/
│       ├── conv/              convergence trajectories (22 summary files)
│       ├── pf/                Pareto front capture (15 files)
│       └── out/               ★ final figures (PNG)
├── paper/
│   ├── main.md                full manuscript
│   ├── tables.tex             LaTeX tables (booktabs)
│   └── cover_letter.md
└── PROGRESS.md                development log
```

---

## 5. How to reproduce

```matlab
% In MATLAB, from the repository root:
cd('algorithm')

% --- Main experiment: one algorithm across all 10 problems, 30 seeds ---
addpath('experiments')
run_ls_EDD          % EDD       -> results/largescale_final/EDD/
run_ls_RVEA         % RVEA      -> results/largescale_final/RVEA/
run_ls_MOEAD        % MOEAD     -> results/largescale_final/MOEAD/
run_ls_MOGWO        % MOGWO     -> results/largescale_final/MOGWO/
run_ls_HCEA         % HCEA      -> results/largescale_final/HCEA/
run_ls_HCEAV4       % HCEAV4    -> results/largescale_final/HCEAV4/
run_ls_SMSEMOA      % SMSEMOA   -> results/largescale_final/SMSEMOA/
% NSGA2 / NSGA3 / SPEA2 / AGEMOEA: see run_ls_batch9.m

% --- Statistics ---
run_ls_stats        % no: use friedman_10
friedman_10         % ranks + Wilcoxon + Holm -> largescale_final/friedman_10.mat

% --- Ablation ---
make_edd_abl        % regenerate EDD_ABL.m from EDD.m and assert substitutions
run_ablation_edd    % 4 variants x 3 problems x 5 seeds

% --- Convergence study ---
run_conv_a ; run_conv_b ; run_conv_c

% --- Pareto fronts and figures ---
run_pf_data
make_figs ; make_pf_figs
```

Every driver is **idempotent and resumable**: a per-run `.mat` file that
already exists is skipped, so the full dataset can be regenerated
incrementally and an interrupted campaign can be resumed without rework.

**One-call convenience.** A single entry point that runs the full pipeline in
the correct order is provided as `run_main.m` (see Section 9). Expect several
hours of wall-clock time on a single machine; the slowest baselines are MOGWO
and SMSEMOA (HV-based O(N²) selection).

**Requirements.** MATLAB R2019b or later. No additional toolboxes are needed
beyond the PlatEMO-derived utility functions bundled in the repository
(`algorithms/utils/`, `problems/wfg_toolbox/`). No network access is required.

**Ablation integrity.** `EDD_ABL.m` is not maintained by hand. It is produced
from `EDD.m` by `experiments/make_edd_abl.m`, which performs seven explicit
textual substitutions and asserts that all seven fired before writing the
file. This guarantees that the algorithm under test and the algorithm being
ablated cannot drift apart.

---

## 6. Data description

### 6.1 Main experiment — `results/largescale_final/`

One `.mat` file per run:

```
results/largescale_final/<algorithm>/<algorithm>_<problem>_s<seed>.mat
```

Each file contains a single struct `out`:

| Field | Meaning |
|---|---|
| `out.IGD` | inverted generational distance to `ParetoFront(500)` |
| `out.HV`  | hypervolume, reference point `1.1 × max(true front)` |
| `out.nFE` | function evaluations consumed |
| `out.elap`| wall-clock seconds |
| `out.PPS` | size of the final first non-dominated front |

Totals: **11 algorithms × 10 problems × 30 seeds = 3 300 files, 0 failures.**

`results/largescale_final/friedman_10.mat` holds the derived statistics:
`algs`, `probNames`, `igdTbl`, `hvTbl` (per-problem 30-seed medians),
`igdRank`, `hvRank`, `combined`, `pAll`.

### 6.2 Ablation — `results/ablation_abl/`

`<mode>_<problem>_s<seed>.mat` with `mode ∈ {full, noEED, noDSG, noPolish}`
and the same `out` struct plus `out.mech` (active mechanism) and
`out.switchGen`. Totals: **4 × 3 × 5 = 60 files.** `ablation_summary.mat`
holds the median tables.

### 6.3 Convergence study — `results/figs/conv/`

`<algorithm>_<problem>.mat` containing `budgets`, `fe` (function evaluations),
`seeds` and `traj` (a `numBudgets × numSeeds` matrix of final IGD at each
budget). Protocol: `G ∈ {25, 50, 100, 150, 200}`, 3 seeds per point, identical
for all algorithms. Totals: **11 algorithms × 2 problems × 3 seeds × 5 budgets.**

### 6.4 Pareto fronts — `results/figs/pf/`

`<algorithm>_<problem>.mat` containing the final first non-dominated front
`F`, the true front `PFtrue`, and the corresponding `igd`, for
`seed = 1`, `N = 100`, `G = 200`, on LSMOP6, LSMOP2 and DTLZ2-300D-M3.
Totals: **5 algorithms × 3 problems = 15 files.**

---

## 7. Figures

All final figures are in `results/figs/out/`:

| File | Content |
|---|---|
| `conv_LSMOP6.png` | convergence curves, collapse instance (EDD reaches its final IGD at G = 25; MOGWO needs the full 200 generations; all others remain 2–3 orders of magnitude away) |
| `conv_LSMOP2.png` | convergence curves, converged instance (EDD's IGD *degrades* monotonically — the only degrading trajectory) |
| `pf_LSMOP6_panels.png`, `pf_LSMOP6_3d.png` | Pareto fronts on LSMOP6 |
| `pf_LSMOP2_panels.png`, `pf_LSMOP2_3d.png` | Pareto fronts on LSMOP2 |
| `pf_DTLZ2_300D_M3_panels.png`, `pf_DTLZ2_300D_M3_3d.png` | Pareto fronts on DTLZ2-300D-M3 |
| `ablation_bar.png` | log₁₀ IGD by ablation variant and instance |

**Note on the panel figures.** The per-problem panel figures give each
algorithm its own axis limits and annotate the panel title with that
algorithm's IGD. This is deliberate: on LSMOP6 the IGD values span a factor
of ~2 200 (1.63 for EDD versus 3 613 for HCEAV4), so a shared linear axis
would reduce EDD's front to a single invisible point. The sixth panel repeats
all five algorithms on shared axes for reference.

---

## 8. Honest scope of the claims

The paper claims, and the data support, the following and nothing more:

- EDD attains the best **combined** IGD/HV Friedman rank and a **joint-best**
  HV rank on this test set; it is **second** on IGD, not first.
- The advantage is **not uniform**. It is concentrated on the instances where
  the baseline algorithms fail to converge. On the three instances where the
  whole field converges, EDD ranks 9th–11th on IGD, and the ablation shows
  this is caused by the EED component specifically.
- The **polish-HV** component shows no measurable effect at D = 300. This is
  reported as a negative result.
- Pairwise Wilcoxon tests are **underpowered** at n = 10 problems: all exact
  p-values saturate at 1.0, which is a statement about power, not about
  equivalence. Per-problem ranks, win/loss counts and the ablation are the
  primary evidence.
- All results are on **synthetic benchmarks**. No real-world engineering
  instance is evaluated.
- EDD's DSG operator is tuned for M ≥ 3 and is **not** competitive on
  M = 2 large-D instances.

---

## 9. Upload checklist

See `docs/UPLOAD_CHECKLIST.md` for the itemised list of files to publish,
with required/optional flags.

---

## 10. Licence and citation

Code released under **Apache-2.0** (see `LICENSE`).
Benchmark problem definitions derived from PlatEMO retain their original
terms; see `NOTICE`.

If you use this code or data, please cite the manuscript:

```bibtex
@article{zhang2026edd,
  title   = {A Dimension-Adaptive Evolutionary Algorithm with Epsilon-Grid
             Selection and Directed Decision-Space Operators for
             Large-Scale Multi-Objective Optimization},
  author  = {Zhang, Yuxuan},
  journal = {Applied Soft Computing},
  year    = {2026},
  note    = {Code and data: [anonymous repository URL, to be inserted until
             acceptance]}
}
```
