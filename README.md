# VOR: Battlefield-Adaptive EA for Large-Scale and Constrained Multi-Objective Optimization

This repository is the public code and data archive for the paper:

> **Battlefield-Adaptive Evolutionary Algorithm with Online
> Reference-Reallocation and Quantile $\varepsilon$-Grid Selection for
> Large-Scale and Constrained Multi-Objective Optimization**
>
> *Yuxuan Zhang, Graduate School, Army Engineering University of the
> PLA, Nanjing, China.*
>
> Target journal: *Applied Soft Computing* (Elsevier).

The algorithm under study, **VOR** (Vector-adaptive Online
Reference-reallocation EA), is a dimension-adaptive multi-objective
evolutionary algorithm whose central mechanism is a *battlefield
routing* rule: a single codebase services the large-scale ($D=300$) and
the constrained low-dimensional ($D=10$--$60$) battlefields, with the
variation operator, environmental selection and reference-vector
reallocation jointly gated by the initial IGD scale, the decision
dimension, and the presence of constraints.

The three core mechanisms:

1. **Q-EPS** — quantile $\varepsilon$-grid environmental selection
   (re-parses the $\varepsilon$-grid from the 0.25/0.5/0.75/0.9
   quantiles of the current non-dominated set each generation);
2. **ORA** — online reference-vector reallocation (K-means + PCA pull
   of the NBI reference vectors every 10 generations, IGD-derivative
   gated);
3. **Battlefield routing** — one $O(1)$ routing decision
   (initial IGD $+ D +$ hasCon) services $D \in \{10, 30, 60, 300\}$
   without hand-tuned dimension gates.

---

## Repository layout

```
VOR-battlefield-ea/
├── README.md                      # this file
├── LICENSE                        # MIT
├── algorithms/                    # all algorithm implementations (MATLAB)
│   ├── VOR.m                      # VOR-v2 core (~740 lines)
│   ├── EDD.m, EDD_cf.m, ...       # EDD lineage (v12 baseline + variants)
│   ├── NSGA2.m, RVEA.m, MOEAD.m   # classic baselines
│   ├── HCEAV4.m, ...              # HCEA architecture base
│   └── run_fdsea_ls.m, run_gdvtsf_ls.m, run_moeaib_ls.m
│                                  # SOTA trio invocation wrappers
│                                  # (FDSEA / GDVTSF / MOEA-IB, D=300)
├── experiments/                   # all benchmark & statistics scripts
│   ├── run_vor2_bench_30.m        # 30-seed benchmark runner (idempotent)
│   ├── stat_30.m                  # Friedman + Wilcoxon (30-seed)
│   ├── aggregate_vor2_30.m        # mean±std aggregation (30-seed)
│   ├── make_figs_en.m             # 3 vector PDF figures (fig1/fig2/fig3)
│   └── ...                        # (200+ diagnostic & ablation scripts)
├── results/
│   ├── vor2_bench/                # 900 .mat result files (30 seeds × 5 algos × 6 problems)
│   ├── stat_results_30.txt        # Friedman + Wilcoxon output
│   ├── agg30_stats.txt            # 30-seed mean±std table
│   └── figs/out/
│       ├── fig1_igd_conv.pdf      # IGD convergence (6 problems × 5 algos, 30 seeds)
│       ├── fig2_pf_scat.pdf       # Pareto-front snapshots (ZDT1 2D, LSMOP1 3D)
│       └── fig3_friedman.pdf      # Friedman rank-sum bar chart
└── paper_en/                      # LaTeX source of the paper
    ├── main.tex
    └── cover_letter/cover_letter.tex
```

---

## One-command reproduction

Open MATLAB and run, in order:

```matlab
cd experiments
run_vor2_bench_30()      % re-run all 900 (algo, problem, seed) combos
                         % idempotent: skips .mat files already present
stat_30()                % Friedman + Wilcoxon (30-seed)
                         % → results/stat_results_30.txt
aggregate_vor2_30()      % mean±std IGD/HV/PPS aggregation
                         % → results/vor2_bench/agg30_stats.txt
make_figs_en()           % regenerate the 3 publication figures
                         % → results/figs/out/fig1|2|3_*.pdf
```

Expected wall-clock: ~4--6 hours on a single modern CPU (one thread per
run); `run_vor2_bench_30` is idempotent, so you can interrupt and resume.

To reproduce only the *published numbers* without re-running the
benchmark, skip to step 2: the 900 `.mat` files under
`results/vor2_bench/` are committed and already contain every value
reported in the paper (final population `R.F`, IGD/HV/PPS scalars,
full IGD convergence history `R.igdHistory`, true-front sample `PF`,
reference set `ref`, elapsed time `R.el`, algorithm/problem names
`aName`/`pName`).

---

## Benchmark protocol (as published)

| Parameter | Value |
|---|---|
| Population size $N$ | 100 |
| Max generations $G$ | 200 |
| Seeds | 1--30 (independent, per problem) |
| True-front sample | 500 points |
| Metrics | IGD, HV, PPS (see `experiments/stat_30.m`) |

**Six problems** (dimension $D$, number of objectives $M$):

| Problem | $M$ | $D$ | Notes |
|---|---|---|---|
| MaF14 | 3 | 60 | constrained, irregular front |
| CF1 | 3 | 10 | constrained |
| ZDT1 | 2 | 30 | unconstrained, disconnected PF |
| LSMOP1 | 3 | 300 | large-scale, initial IGD $\approx 11$ |
| LSMOP6 | 3 | 300 | large-scale, initial IGD $\approx 4 \times 10^4$ |
| DTLZ2-300D | 3 | 300 | large-scale |

**Five-algorithm comparison set:**
NSGA-2, RVEA, MOEA/D, EDD (v12, our EDD lineage), VOR (ours).

**SOTA trio on the $D=300$ battlefield:**
FDSEA, GDVTSF, MOEA-IB (invoked via
`algorithms/run_fdsea_ls.m`, `run_gdvtsf_ls.m`,
`run_moeaib_ls.m`; SOTA numbers are the publicly reported 30-seed
results from the original papers, not re-implemented here).

---

## .mat result-file naming

One file per `(algorithm, problem, seed)` triple:

```
results/vor2_bench/{ALGO}_{PROB}_s{SEED}.mat
```

where `{ALGO} ∈ {VOR, EDD, MOEAD, RVEA, NSGA2}` (5),
`{PROB} ∈ {MaF14, CF1, ZDT1, LSMOP1, DTLZ2_300D, LSMOP6}` (6),
`{SEED} ∈ 1..30` (30) → 5 × 6 × 30 = **900 files**.

Each `.mat` file (MATLAB v7.3 format) contains:

| Field | Type | Meaning |
|---|---|---|
| `R.F` | matrix $N_f \times M$ | final non-dominated objective matrix |
| `PF` | matrix $500 \times M$ | true-front sample |
| `ref` | matrix $500 \times M$ | reference set |
| `igd` | scalar | final IGD (primary reported metric) |
| `hv` | scalar | final Hypervolume |
| `pps` | scalar | number of non-dominated solutions (PPS, $\le N$) |
| `el` | scalar | elapsed wall-clock time (s) |
| `R.igdHistory` | vector | per-generation IGD trace (for fig1) |
| `aName` | string | algorithm name (e.g. `'VOR'`) |
| `pName` | string | problem name (e.g. `'LSMOP6'`) |

Total `.mat` archive size: ~90 MB.

---

## Runtime environment

- **MATLAB** R2022a or later (the scripts use `exportgraphics`,
  `pdist2`, and basic matrix ops; no toolboxes are required).
- **PlatEMO** (optional): only needed to re-implement the SOTA trio
  (`run_fdsea_ls.m` / `run_gdvtsf_ls.m` / `run_moeaib_ls.m` call the
  public PlatEMO implementations of FDSEA/GDVTSF/MOEA-IB). The
  published SOTA numbers in the paper are taken from the original
  papers' 30-seed reports, not re-run here.
- **No other dependencies.** All problem definitions
  (MaF14, CF1, ZDT1, LSMOP1/6, DTLZ2) are self-contained MATLAB
  functions under `algorithms/` and `experiments/`.

---

## Citation

If you use this code, please cite the paper:

> Y. Zhang. *Battlefield-Adaptive Evolutionary Algorithm with Online
> Reference-Reallocation and Quantile $\varepsilon$-Grid Selection for
> Large-Scale and Constrained Multi-Objective Optimization*.
> *Applied Soft Computing* (in press / submitted).

(Replace "in press / submitted" with the final journal reference and
DOI once the manuscript is accepted.)

---

## Contact

Corresponding author: **Yuxuan Zhang**,
Graduate School, Army Engineering University of the PLA, Nanjing, China.
Email: [3150644070\@qq.com](mailto:3150644070@qq.com)

This work was conducted as an independent project; no funding was
received.
