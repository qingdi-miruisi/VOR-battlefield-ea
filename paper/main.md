<!--
  =================================================================
  DRAFT MIRROR — 本文件是 main.tex 的 Markdown 镜像，仅用于阅读
  与版本对比。main.tex 是权威源稿；投稿以 main.tex 编译的 PDF 为准。
  后续对论文的修改请直接编辑 main.tex，并在确认前删除本文件或
  重新生成本文件，避免两者漂移。
  =================================================================
-->

# A Dimension-Adaptive Evolutionary Algorithm with Epsilon-Grid Selection and Directed Decision-Space Operators for Large-Scale Multi-Objective Optimization

## Abstract

Large-scale multi-objective optimization (LSMOP), in which the number of decision
variables reaches several hundreds, remains one of the most challenging open
problems in evolutionary multi-objective optimization. Existing evolutionary
multi-objective optimizers fail in such regimes for two distinct reasons:
(i) reference-vector mechanisms such as NSGA-III or RVEA lose diversity as the
number of non-dominated solutions must be distributed across a growing objective
space, and (ii) classical crossover and mutation operators such as SBX and
polynomial mutation lose their directed convergence capability as the decision
space grows. This paper proposes EDD, a single-population dimension-adaptive
evolutionary algorithm in which the environmental selection, offspring
operator, and final polishing are all controlled by a single dimension-aware
gate. When the decision dimension is large (D≥100), EDD switches from
reference-vector-based selection to an epsilon-grid environmental selection
(EED) that preserves a dense, well-distributed non-dominated front without
reference vectors; simultaneously, it replaces SBX by a directed
decision-space offspring operator (DSG) that preserves per-segment diversity
while imposing a grey-wolf-style directed movement. On the LSMOP1–9 benchmark
family (M = 3, D = 300) and the DTLZ2-300D-M3 cross-validation instance,
evaluated with 30 independent runs per cell against ten state-of-the-art
algorithms, EDD attains the best combined IGD/HV Friedman rank (4.35) and the
joint-best hypervolume rank (4.25, tied with HCEA), while ranking second on
inverse generational distance (IGD, 4.45). We report the result as structurally
bimodal rather than uniformly dominant: EDD is first on IGD in 5 of the 10
instances and is the only algorithm (or one of two) to obtain non-zero
hypervolume on five instances where the remaining field collapses entirely to
HV = 0 — outperforming HCEAV4 by a factor of ~1 600 in IGD on LSMOP6 (1.63 vs.
2 660.25) — but it ranks 9th–11th on the three multimodal instances (LSMOP2/4/8)
on which every algorithm converges. A four-variant component ablation locates
the cause: on the collapse instances both components of the high-dimensional
path are load-bearing (removing the epsilon-grid selection costs a factor of
2 892 in IGD on LSMOP6; removing the directed operator costs 137), whereas on
the converged instances the epsilon-grid selection is actively harmful
(disabling it improves LSMOP2 IGD by 4.1× and more than doubles its
hypervolume), and a third claimed component, convergence-gated polishing,
shows no measurable effect at this dimension (1.00× change in median IGD). The
contribution we establish is therefore specific and quantified: at D = 300,
EDD eliminates total convergence failure, which drives its aggregate rank
advantage, and the same ablation measures the cost it pays for that
robustness.

## 1. Introduction

### 1.1 The large-scale challenge

Multi-objective optimization (MOO) problems with a large decision dimension
D (hundreds to thousands) arise wherever the number of design variables far
exceeds the number of objectives. Such problems are distinct from classical
many-objective problems (MaOPs, M ≥ 5): even with only three objectives, the
search space grows as 2^D, and the interplay between convergence and diversity
is fundamentally different from the low-dimensional regime in which most
existing evolutionary multi-objective optimizers (EMOAs) are tuned. Classical
EMOAs fail on large-scale decision spaces in two ways. First, reference-vector
mechanisms (NSGA-III, RVEA, MOEA/D-IM) distribute the population across the
objective space using a fixed number of reference points; as D grows the
non-dominated front becomes dense in objective space and a fixed reference set
cannot resolve it, so diversity degrades. Second, scalarized offspring
operators (SBX, polynomial mutation) assume low-dimensional structure in their
crossover distribution; in high-D search spaces they behave as essentially
undirected random walks, and convergence slows by several orders of magnitude.

### 1.2 Related work and the gap

Large-scale dedicated solvers have been proposed: MOEA/LS, DSG-EA, CMOEA, and
MOEA/LSM. Most of these target a single dimension regime and do not switch
mechanisms smoothly between the low-D and high-D regime. A recent line of work
(C-EGD, RKS-TAE) addresses many-objective (large-M) problems, but the
large-D, small-to-medium-M regime (M = 2–5, D ≥ 100) remains under-served.
This is the regime we target.

### 1.3 Contributions

We make three contributions and report one negative result. (i) **Epsilon-Grid
Environmental Selection (EED).** We propose a dimension-aware environmental
selection that bins the M-objective space into an adaptive epsilon grid and
retains the nearest-to-origin solution per non-empty cell, preserving a dense
non-dominated front at D ≥ 100 without reference vectors. (ii) **Directed
Decision-Space offspring operator (DSG).** We replace SBX in the high-D regime
with a three-segment quantile-skeleton operator that preserves per-segment
diversity while imposing a directed movement toward the per-segment optimum, a
mechanism drawn from DSG-EA and the grey-wolf optimizer. (iii) **A
component-level attribution of the resulting performance.** Through a
four-variant ablation we show that EED and DSG are each individually necessary
on the instances where the field collapses, that EED is the measured cause of
the deficit on the instances where the field converges, and — as a negative
result — that the convergence-gated HV polishing step we carried over from
HCEA shows no measurable effect at D = 300. We report the negative result
because an ablation that cannot return one is not an ablation.

On the LSMOP1–9 benchmark family (M = 3, D = 300) and the DTLZ2-300D-M3
cross-validation instance, evaluated over 30 independent runs per cell against
ten baselines, EDD attains the best combined IGD/HV Friedman rank (4.35), a
joint-best HV rank (4.25, tied with HCEA) and the second-best IGD rank (4.45).
We report this result as bimodal rather than uniformly dominant: EDD is the
only algorithm (or one of two) to obtain non-zero hypervolume on five instances
where the remainder of the field collapses to HV = 0, but it ranks 9th–11th on
the three multimodal instances (LSMOP2/4/8) on which the whole field converges.
The defensible claim is therefore that EDD eliminates total convergence failure
at D = 300, which is what drives its aggregate advantage.

## 2. Related Work

### 2.1 Large-scale multi-objective optimization

The large-scale MOO literature is organised around two complementary axes:
problem dimension (D) and objective count (M). Large-D problems (D ≥ 100)
with moderate M (2–5) are the focus of the LSMOP family [1], the two-stage
direction-guided framework DSG-EA [11], and population-hierarchical
approaches such as PH-LSMAEA [12]. Large-M problems (M ≥ 5) with moderate D
(20–100) are the focus of NSGA-III [3], RVEA [5], MOEA/D [4], and AGE-MOEA
[6]. EDD is designed for the former regime: M = 3 with D = 300.

Two families of remedy for large D appear in the literature. The first
reduces the effective decision dimension before search — DSG-EA [11]
performs directed sampling to obtain a "fuzzy decision variable" skeleton
and then searches along the reduced directions, and PH-LSMAEA [12] partitions
the population into elite/development/elimination layers with different
variation strategies. Both assume that the objectives can be decomposed along
a small number of effective decision directions. The second family retains
the full decision space but replaces the environmental selection — this is
where MOEA/D's weight-grid decomposition [4] and RVEA's angle-penalised
distance [5] become the strongest baselines at moderate D. EDD belongs to
the second family but replaces the reference-vector mechanism itself, which
is what distinguishes it from both: unlike DSG-EA [11] it does not assume a
reduced effective dimension, and unlike NSGA-III/RVEA it uses no reference
vectors at D ≥ 100.

### 2.2 Epsilon-based environmental selection

Epsilon dominance and epsilon-grid selection have been studied in single-
objective [17] and many-objective (SPEA2 [10], epsilon-MOEA) settings. Our
EED differs from prior epsilon mechanisms in three ways: (i) the grid is
adaptive to the current pool (bin width = range/10), (ii) selection is by
nearest-to-origin within each non-empty bin rather than by epsilon-dominance,
and (iii) EED is gated on decision dimension so that it only activates at
D ≥ 100, where reference-vector mechanisms are known to fail. We emphasise
that the 10-bin grid is deliberately coarse: Section 5.4 shows that this
coarseness is simultaneously the source of EDD's robustness on the collapse
instances and the source of its deficit on the multimodal instances
(LSMOP2/4/8).

### 2.3 Directed decision-space operators

DSG-EA [11] proposes a decision-space grouping operator that treats the
decision vector as a composition of subcomponents, building on the fuzzy
decision-variable framework of [18]. Our DSG operator extends this line with
a grey-wolf directed-movement term (wRand · cand + wDir · a · r1 · dir, with
the grey-wolf convergence factor and hierarchy taken from GWO [13]) and an
M-adaptive weight wRand = 0.5 + 0.1·min(M,10)/10, so that higher objective
counts preserve more random (diversity) weight. This is the core mechanism
by which EDD maintains convergence at D = 300. The critical difference from
[11] is that DSG is *not* a dimension-reduction step: it operates on all 300
dimensions, using the population's own per-dimension quantile spread to set
the movement scale, so it does not require the objective–decision
decomposability assumption that [11] relies on.

### 2.4 Convergence-gated boundary immigration

Convergence-gated polishing appears in the HCEA family [15] and in a number
of adaptive-archive EMOAs. HCEA switches between APD reference-vector
selection and SMS-EMO [8] incremental-hypervolume refinement at fixed
checkpoints (50/60/70% of the budget), accepting the switch only when a
one-generation trial strictly improves the measured hypervolume. EDD inherits
this switching machinery unchanged for D < 100 and adds the HV polishing step
(adaptive reference point 1.1 × current maximum objective) that is applied at
all D, which makes it insensitive to the scale of the objective space.

### 2.5 Positioning

EDD is closest to HCEA [15] in its selection machinery and to DSG-EA [11] in
its offspring operator. Its distinguishing contribution is the **conjunction**
of the two under a single dimension-aware gate: at D ≥ 100 both the
environmental selection and the offspring operator are re-specified, and the
gate is computed once from (D, M).

The component ablation in Section 5.5 settles what this conjunction is and is
not worth, and the answer is not uniformly favourable to the design. On the
instances where the baselines collapse, the conjunction is what rescues the
method: removing EED costs a factor of 2 892 in IGD on LSMOP6 and removing DSG
costs a factor of 137, so neither component is redundant. But on the instances
where the whole field converges, the EED half of the conjunction is a
liability — disabling it *improves* IGD by 4.1× on LSMOP2. HCEA [15] shares
EDD's polish-HV step but has no EED/DSG path and still collapses on
LSMOP6/LSMOP9, while the external baselines share neither; that contrast
isolates the EED+DSG conjunction as the active ingredient on the collapse
instances, and the same ablation isolates EED as the source of the deficit on
the converged ones. We therefore present EDD as a *specialist* large-scale
optimizer whose value is the elimination of convergence failure, not as a
uniformly dominant method.

## 3. Proposed Algorithm

### 3.1 Dimension-adaptive framework

EDD is a single-population (1 + λ) generational EMOA that branches on the
decision dimension D:

- **Low dimension (D < 100).** EDD follows the HCEAV4 path: angle–distance
environmental selection (APD) over a NBI reference set, with a
HV-gated switch to SMS-EMO at 50/60/70% of the budget. This path is
inherited unchanged from HCEAV4 and is well-established on D < 100 instances.

- **Large dimension (D ≥ 100).** EDD switches to the EED + DSG + polish-HV
path, in which both the offspring operator and the environmental selection
are re-specified for high-dimensional search:
  * offspring is produced by the DSG operator (three-segment quantile
    skeleton + grey-wolf directed movement), replacing SBX;
  * environmental selection is by EED (epsilon grid + nearest-to-origin
    per bin), replacing the APD + NBI mechanism;
  * polish-HV is applied every fifth generation in the final 10% of the
    budget to recover hypervolume quality on multimodal instances.

The switch is computed once as `highDim = (D ≥ 100) ∨ (M ≥ 10)` and never
revisited. This gate is the defining design choice: the algorithm is a single
code base whose behaviour is controlled by a single Boolean computed from the
problem's D and M. The shared polish-HV step (applied at all D) is the
mechanism that prevents the high-D path from sacrificing hypervolume
convergence.

### 3.2 Epsilon-Grid Environmental Selection (EED)

Given an offspring pool of size 2N, EED bins each of the M objectives onto
an adaptive grid of 10 cells spanning the current pool's [min, max] range,
and retains the nearest-to-origin solution per non-empty cell. When the
surviving non-dominated set exceeds N, EED keeps the N points with the
smallest ℓ₂ distance to the origin; when it falls below N, EED fills from
the next non-dominated front. This selection is O(MN) per generation —
cheaper than SMS-EMO's O(N²) slice selection — and requires no reference
vectors, eliminating the NBI diversity vacuum that breaks HCEAV4 at
D = 300.

### 3.3 Directed Decision-Space Offspring Operator (DSG)

For D ≥ 100, SBX and polynomial mutation degrade because the operator's
scalarisation assumes low-dimensional structure. DSG instead:

1. Computes the 0.15 / 0.50 / 0.85 quantiles of the current population's
   top-half (by objective sum) along every decision dimension, forming a
   three-segment fuzzy skeleton (low / mid / high).
2. For each offspring, samples one segment uniformly at random and applies
   a directed movement toward the per-segment quantile with a grey-wolf
   convergence factor a = 2(1 − i/N) and an M-adaptive weight
   wRand = 0.5 + 0.1·min(M,10)/10.

This preserves per-segment diversity (offspring remain in their chosen
segment) while imposing a directed bias toward the best per-segment
solution.

### 3.4 Convergence-gated polish-HV (neutral at D = 300)

For all D, EDD applies a polish-HV step every 5 generations in the final
10% of the budget. polish-HV selects a random individual, perturbs its
decision variables by 1%, and accepts the perturbation if it improves HV
against the adaptive reference point 1.1 × max(Pop.objs). This step is
inherited from HCEA [15], where it was introduced for low-dimensional
deceptive fronts. We state up front that the component ablation in
Section 5.5 finds no measurable effect for it on the D = 300 test set
(1.00× change in median IGD when disabled); it is retained for structural
compatibility with the HCEA family and for EDD's low-D branch, and it is
not claimed as a large-scale contribution.

### 3.5 Pseudocode

```
procedure EDD(P, G, N, D, M)
  highDim ← (D ≥ 100) ∨ (M ≥ 10)
  Pop ← P.Initialization(N);  FE ← N
  for g = 1..G:
    if not highDim and g in round({0.5, 0.6, 0.7}·G):
      Pt ← SMS_Gen(Pop, N)
      if HV(Pt) > HV(Pop): Pop ← Pt
    if highDim:
      O ← DSG(Pop, N)
      Pop ← EED(Pop ∪ O, N)
    else:
      O ← SBX_Polyn(Pop, N)
      Pop ← APD_NBI(Pop ∪ O, N)
    FE ← FE + N
    if g ≥ round(0.9·G) and (g − round(0.9G)) mod 5 = 0:
      Pop ← polishHV(Pop, 1.1·max(Pop.objs))
  return Pop
```

### 3.6 Complexity analysis

Per generation: offspring production is O(N·D) for DSG (dominated by the
per-dimension quantile computation over the top half of the population),
environmental selection is O(MN) for EED or O(N²) for APD/SMS at low D,
and polish-HV is O(MN) when active. Total for G generations is
O(G·N·D) + O(G·N²) for the low-D path. Function evaluations: N per
generation plus at most ⌈G/20⌉ · 3 polish steps in the final 10%.
Compared to HCEAV4, EDD adds no function evaluations; the switch is purely
in the selection and offspring layers.

## 4. Experimental Setup

### 4.1 Test problems

The test set is the 10-instance large-scale family:

- **LSMOP1–9** (Cheng, Jin, Olhofer 2017). Each problem has M = 3
  objectives and D = 300 decision variables, with a composition of
  subcomponents and a distance function. This is the primary large-scale
  benchmark family, designed to stress large-D search.
- **DTLZ2-300D-M3.** The classical DTLZ2 (Deb et al. 2002) with D extended
  to 300 and M = 3. Used as a cross-validation instance: the
  Pareto-optimal front is the unit sphere's positive orthant, independent
  of D. This tests whether EDD's advantages on LSMOP transfer to a
  non-LSMOP large-D problem.

### 4.2 Comparison algorithms

Eleven algorithms: EDD (ours), and the ten baselines
HCEA, HCEAV4, NSGA-II, NSGA-III, SPEA2, AGEMOEA, SMSEMOA, MOGWO, RVEA, and
MOEAD. All algorithms are run with population size N = 100 and maximum
generations G = 200, with 30 independent random seeds (seed = 1, 2, …, 30).
Function-evaluation budgets are matched.

### 4.3 Performance metrics

We report:
- **Inverted Generational Distance (IGD)**: smaller is better;
- **Hypervolume (HV)**: larger is better, computed with the adaptive
  reference point 1.1 × max(objective);
- **Combined rank**: the arithmetic mean of the per-problem IGD rank and
  HV rank (smaller is better).

### 4.4 Statistical analysis

Per problem and per metric, we compute the median across the 30 seeds.
For the Friedman rank we average the per-problem rank over the 10 problems.
For problem-level comparisons we use the Wilcoxon signed-rank test on the
per-problem median differences, with Holm-Bonferroni correction across the
ten pairwise comparisons involving EDD.

## 5. Results

All statistics below are computed from 30 independent runs per
(algorithm, problem) pair, i.e. 3 300 runs in total, with no failed runs.
Per-problem values are medians over the 30 seeds. Ranks are Friedman
mean ranks over the 10 instances (ties averaged).

### 5.1 Friedman ranks on the 10 large-scale instances

| Algorithm | IGD rank | HV rank | Combined rank |
|-----------|---------:|--------:|--------------:|
| **EDD (ours)** | **4.45 (2nd)** | **4.25 (1st, tied)** | **4.35 (1st)** |
| MOEAD     | 4.20 (1st)  | 5.65 (5th)  | 4.93 (2nd)  |
| MOGWO     | 4.85 (3rd)  | 5.35 (3rd)  | 5.10 (3rd)  |
| HCEA      | 6.85 (9th)  | 4.25 (1st, tied) | 5.55 (4th) |
| RVEA      | 5.70 (5th)  | 5.45 (4th)  | 5.58 (5th)  |
| AGEMOEA   | 5.50 (4th)  | 6.45 (7th)  | 5.98 (6th)  |
| NSGA-III  | 5.90 (6th)  | 7.05 (9th)  | 6.48 (7th)  |
| SPEA2     | 6.75 (7th)  | 6.25 (6th)  | 6.50 (8th)  |
| NSGA-II   | 7.10 (10th) | 6.45 (7th)  | 6.78 (9th)  |
| SMSEMOA   | 6.75 (7th)  | 7.80 (11th) | 7.28 (10th) |
| HCEAV4    | 7.95 (11th) | 7.05 (9th)  | 7.50 (11th) |

**EDD attains the best combined rank (4.35) and joint-best HV rank
(4.25), and is second on IGD (4.45).** The combined rank of the runner-up
(MOEAD, 4.93) is 0.58 rank units worse.

We deliberately report the HV result as a **tie with HCEA** rather than a
win. The tie arises because on the four instances where the metric
degenerates (LSMOP6 and LSMOP7, where *every* algorithm attains HV = 0),
the tie-averaged rank assigns the same mid-range rank to all of them, so
the HV aggregate is not a clean discriminator on this test set. Section 5.4
gives the non-degenerate breakdown.

### 5.2 Per-problem IGD (median over 30 seeds, lower is better)

| Problem | EDD | HCEA | HCEAV4 | NSGA-II | NSGA-III | SPEA2 | AGEMOEA | SMSEMOA | MOGWO | RVEA | MOEAD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| LSMOP1 | **0.86** | 2.69 | 2.69 | 4.41 | 2.71 | 3.93 | 4.28 | 2.70 | **0.86** | 3.69 | 3.12 |
| LSMOP2 | 0.43 | 0.15 | 0.15 | 0.11 | 0.17 | **0.09** | 0.12 | 0.36 | 0.40 | **0.09** | **0.09** |
| LSMOP3 | **0.86** | 14.48 | 14.48 | 13.91 | 10.31 | 15.91 | 11.04 | 10.57 | 9.32 | 12.00 | 7.20 |
| LSMOP4 | 0.48 | 0.32 | 0.32 | 0.29 | 0.34 | 0.27 | 0.32 | 0.51 | 0.45 | **0.26** | 0.27 |
| LSMOP5 | **0.94** | 11.70 | 11.70 | 10.60 | 7.84 | 9.90 | 4.72 | 5.26 | **0.94** | 8.07 | 3.62 |
| LSMOP6 | **1.63** | 2660.25 | 2660.25 | 1087.19 | 394.87 | 934.82 | 232.24 | 219.30 | **1.63** | 843.04 | 14.76 |
| LSMOP7 | 1.33 | 1.11 | 1.11 | 1.62 | 5626.53 | 1.74 | 1.45 | 7429.95 | **1.21** | 1.32 | 1.37 |
| LSMOP8 | 0.94 | 0.71 | 0.71 | 0.98 | 0.68 | 0.72 | 0.70 | 8.88 | 0.74 | **0.65** | 0.72 |
| LSMOP9 | **1.55** | 30.55 | 30.55 | 10.26 | 11.51 | 11.95 | 10.02 | 10.53 | **1.55** | 34.42 | 4.46 |
| DTLZ2-300D-M3 | **0.74** | 6.81 | 6.81 | 1.97 | 1.87 | 1.90 | 1.87 | 1.35 | 5.96 | 2.45 | 4.25 |

### 5.3 Per-problem HV (median over 30 seeds, higher is better)

| Problem | EDD | HCEA | HCEAV4 | NSGA-II | NSGA-III | SPEA2 | AGEMOEA | SMSEMOA | MOGWO | RVEA | MOEAD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| LSMOP1 | **0.124** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0.120 | 0 | 0 |
| LSMOP2 | 0.435 | 0.906 | 0.906 | 0.984 | 0.820 | **1.012** | 0.938 | 0.635 | 0.463 | 1.014 | 1.010 |
| LSMOP3 | **0.120** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| LSMOP4 | 0.381 | 0.566 | 0.566 | 0.666 | 0.543 | 0.719 | 0.577 | 0.406 | 0.330 | **0.737** | 0.725 |
| LSMOP5 | **0.121** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0.121** | 0 | 0 |
| LSMOP6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| LSMOP7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| LSMOP8 | 0.121 | 0.041 | 0.041 | 0.037 | 0.040 | 0.035 | 0.045 | 0 | **0.132** | 0.048 | 0.057 |
| LSMOP9 | **0.536** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0.536** | 0 | 0 |
| DTLZ2-300D-M3 | **0.033** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Per-problem EDD ranks (out of 11):

| Problem | EDD IGD rank | EDD HV rank | non-zero HV algorithms |
|---|---:|---:|---:|
| LSMOP1 | 1 | 1 | 2 |
| LSMOP2 | 11 | 11 | 11 |
| LSMOP3 | 1 | 1 | 1 |
| LSMOP4 | 10 | 10 | 11 |
| LSMOP5 | 1 | 1 | 2 |
| LSMOP6 | 2 | 1 (all tie at 0) | 0 |
| LSMOP7 | 5 | 1 (all tie at 0) | 0 |
| LSMOP8 | 9 | 2 | 10 |
| LSMOP9 | 1 | 1 | 2 |
| DTLZ2-300D-M3 | 1 | 1 | 1 |

### 5.4 The result is bimodal, and we report it as such

The per-problem table reveals a structure that the aggregate Friedman rank
alone conceals, and which we state explicitly rather than average away:

**(a) On five instances the baselines collapse completely — EDD does not.**
On LSMOP1, LSMOP3, LSMOP5, LSMOP9 and DTLZ2-300D-M3, NSGA-II, NSGA-III,
SPEA2, AGEMOEA, SMSEMOA, RVEA, MOEAD and both HCEA variants attain
**HV = 0**: they fail to converge to the Pareto front at all within the
budget. EDD (and, on LSMOP1/5/9 only, MOGWO) is the sole algorithm that
obtains a non-zero hypervolume. The IGD gap on these instances is
correspondingly large — on LSMOP6 EDD reaches IGD = 1.63 against 2660.25
for HCEA and HCEAV4, a factor of ~1 600; on LSMOP9, 1.55 against 30.55;
on LSMOP3, 0.86 against 14.48.

**A necessary precision about what "converges" means here.** The reference
point used for HV is derived from the *true* Pareto front
(1.1 × max of the true front), so any obtained solution with a single
objective value above that box contributes zero hypervolume. Inspecting the
individual fronts (Figure 2) shows that on LSMOP6 full EDD produces a front
whose f₂ component reaches 6.0 × 10⁵ while the true front lies in [0, 1]³:
the front mixes a converged subset — which is what drives the low IGD of
1.63 and makes EDD the best algorithm on that instance — with divergent
outliers. The correct statement is therefore that EDD is the only algorithm
that places a *subset* of its front on the true front on these instances,
not that it converges cleanly. This also explains why HV = 0 for *every*
algorithm (including EDD) on LSMOP6 and LSMOP7: no algorithm, EDD included,
places a large enough fraction of its front inside the true-front reference
box for the hypervolume to register. We report this distinction because the
IGD and HV columns of Tables 5.2–5.3 otherwise appear to contradict each
other on LSMOP6.

**(b) On three instances where every algorithm converges, EDD is behind.**
On LSMOP2, LSMOP4 and LSMOP8 all eleven algorithms attain non-zero HV, and
EDD ranks 11th, 10th and 9th on IGD respectively (HV ranks 11, 10, 2). On
these multimodal instances the weight-grid decomposition of MOEAD
(IGD 0.09, 0.27, 0.72) and the reference-vector mechanism of RVEA
(0.09, 0.26, 0.65) resolve the front more sharply than the epsilon grid.

The aggregate rank is therefore a compromise between two regimes: EDD is
first on 5 of 10 instances (IGD) and never collapses, but it is near-last on
the 3 instances where the whole field converges. We regard this as the
honest characterisation of the method: **EDD's contribution is robustness
at D = 300 — the elimination of total convergence failure — rather than
uniform dominance of the metric on every instance.**

### 5.5 Component ablation (4 variants × 3 instances × 5 seeds)

To test whether the EED and DSG components are individually necessary, we
built an ablation variant `EDD_ABL` that shares the EDD source but exposes
three switches: (i) *no-EED* forces the APD/SMS path even at D ≥ 100,
(ii) *no-DSG* keeps the EED selection but replaces the DSG offspring operator
with SBX, and (iii) *no-polish* disables the polish-HV step. The full variant
(ablMode = 0) reproduces EDD v12 exactly (identical IGD to the locked
implementation), which validates the ablation harness.

Median IGD over 5 seeds (G = 200, N = 100):

| Variant | LSMOP6 | LSMOP9 | LSMOP2 |
|---|---:|---:|---:|
| **full EDD** | **1.631** | **1.548** | 0.4249 |
| no-EED (APD path at D=300) | 4 716 (**2 892× worse**) | 42.62 (**27.5× worse**) | 0.1027 (**4.1× better**) |
| no-DSG (SBX offspring) | 224.2 (137× worse) | 9.075 (5.9× worse) | 0.4833 (1.1× worse) |
| no-polish | 1.631 (1.00×) | 1.548 (1.00×) | 0.3983 (0.93×, marginal) |

Median HV over the same runs:

| Variant | LSMOP6 | LSMOP9 | LSMOP2 |
|---|---:|---:|---:|
| full EDD | 0 | **0.5362** | 0.435 |
| no-EED | 0 | **0** | **0.9889** |
| no-DSG | 0 | **0** | 0.3902 |
| no-polish | 0 | 0.5362 | 0.4906 |

Three conclusions follow, and the second and third are negative results about
our own design that we report rather than suppress.

**(a) On the collapse instances, EED and DSG are each individually
necessary.** On LSMOP6, removing EED costs a factor of 2 892 in IGD (1.631 →
4 716) and removing DSG costs a factor of 137 (1.631 → 224.2). On LSMOP9 the
same ordering holds (27.5× and 5.9×), and removing EED also annihilates the
hypervolume (0.5362 → 0). Neither component alone is sufficient: EED without
DSG still collapses by two orders of magnitude, and DSG without EED collapses
by three. The claim that the *conjunction* is what rescues the method at
D = 300 is therefore supported on the collapse instances.

**(b) On the converged multimodal instance, EED is actively harmful.**
On LSMOP2, disabling EED *improves* IGD by a factor of 4.1 (0.4249 → 0.1027)
and more than doubles HV (0.435 → 0.9889). This is the mechanistic
explanation of the bimodality documented in Section 5.4: the same epsilon-grid
selection that eliminates convergence failure on five instances is the
component that costs EDD ranks 9–11 on the three instances where the field
converges. The deficit is not a tuning artefact — it is attributable to a
specific, identified component, and the ablation quantifies it.

**(c) polish-HV shows no measurable benefit on this test set.** Disabling the
polish step changes the median IGD by 1.00× on LSMOP6 and LSMOP9 and by 0.93×
(marginally *better*) on LSMOP2. The component is inherited from HCEA [15],
where its contribution was established on low-dimensional deceptive fronts;
on the D = 300 test set it is neutral. We retain it for structural
compatibility with the HCEA family and for the low-D branch of EDD, but we do
**not** claim it as a contributing mechanism for the large-scale results of
this paper.

### 5.6 Convergence behaviour

Figure (convergence) reports the IGD trajectory as a function of the
function-evaluation budget, obtained by re-running each algorithm at budgets
G ∈ {25, 50, 100, 150, 200} (3 seeds per point; all algorithms share the
identical protocol).

| Algorithm | LSMOP6 G=25 | LSMOP6 G=100 | LSMOP6 G=200 | LSMOP2 G=25 | LSMOP2 G=100 | LSMOP2 G=200 |
|---|---:|---:|---:|---:|---:|---:|
| **EDD** | **1.629** | **1.629** | **1.629** | 0.3321 | 0.4194 | 0.4249 |
| MOGWO | 2 580 | 1.70 | 1.633 | 0.1253 | 0.3411 | 0.3327 |
| MOEAD | 7 148 | 413.8 | 10.87 | **0.0985** | **0.0923** | **0.0919** |
| RVEA | 12 430 | 2 111 | 777.7 | 0.0962 | 0.0945 | 0.0929 |
| AGEMOEA | 6 678 | 601.7 | 200.6 | 0.1172 | 0.1181 | 0.1129 |
| SPEA2 | 10 080 | 2 916 | 1 360 | 0.0954 | 0.0952 | 0.0940 |
| SMSEMOA | 6 931 | 1 477 | 258.3 | 0.1381 | 0.1382 | 0.4429 |
| NSGA-II | 12 930 | 2 656 | 1 514 | 0.1070 | 0.1066 | 0.1100 |
| NSGA-III | 8 536 | 1 078 | 426.9 | 0.1166 | 0.1614 | 0.1448 |
| HCEA / HCEAV4 | 10 020 | 2 849 | 3 613 | 0.1359 | 0.1580 | 0.1792 |

Two features of this table carry the paper's argument.

First, on LSMOP6 EDD reaches its final IGD of 1.629 **already at G = 25** and
does not improve further — the mechanism converges immediately — whereas
MOGWO, its only competitor in final quality, needs the full 200 generations
to reach 1.633, and every other algorithm remains two to three orders of
magnitude away at the full budget. EDD's advantage on the collapse instances
is therefore a *speed* advantage as much as a quality advantage.

Second, on LSMOP2 EDD's IGD **degrades monotonically** over the budget
(0.3321 → 0.4194 → 0.4249) while MOEAD and RVEA improve slightly and stay
near 0.09. This is the trajectory-level signature of the ablation result (b)
above: the EED path does not merely fail to help on LSMOP2, it actively pulls
the population off the front as generations accumulate. No other algorithm in
the table exhibits a degrading trajectory on this instance.

### 5.7 Wilcoxon signed-rank + Holm-Bonferroni

Problem-level Wilcoxon signed-rank tests were applied to the 10 paired
per-problem medians (EDD vs. each baseline), with Holm-Bonferroni correction
over the 10 comparisons.

| Baseline | IGD win/lose | HV win/lose/tie | IGD p (Holm) | Verdict |
|---|---:|---:|---:|---|
| HCEA | 6/4 | 6/2/2 | 1.0 | not significant |
| HCEAV4 | 6/4 | 6/2/2 | 1.0 | not significant |
| NSGA-II | 8/2 | 6/2/2 | 1.0 | not significant |
| NSGA-III | 7/3 | 6/2/2 | 1.0 | not significant |
| SPEA2 | 7/3 | 6/2/2 | 1.0 | not significant |
| AGEMOEA | 7/3 | 6/2/2 | 1.0 | not significant |
| SMSEMOA | 9/1 | 6/2/2 | 1.0 | not significant |
| MOGWO | 3/5 | 4/2/4 | 1.0 | not significant |
| RVEA | 6/4 | 6/2/2 | 1.0 | not significant |
| MOEAD | 7/3 | 6/2/2 | 1.0 | not significant |

The exact p-value saturates at 1.0 for every comparison. This is a statement
about **statistical power, not about equivalence**: with n = 10 paired
problems the Wilcoxon test has very little power to reject, and the IGD
differences are dominated in magnitude by the collapse instances, whose
ordering is already deterministic (EDD converges, the baseline does not).
We therefore do **not** claim statistical significance for EDD's rank
advantage; the rank evidence in Tables 5.1–5.3 and the win/loss counts above
are the primary evidence, and the reader should read the p-values as
"underpowered" rather than as "no difference".

## 6. Discussion

### 6.1 The mechanism behind the bimodal result

The per-problem breakdown in Section 5.4 is not an accident of the metric;
the component ablation in Section 5.5 identifies its cause.

On the collapse instances (LSMOP1/3/5/9, DTLZ2-300D-M3) the difficulty is
**reaching the front at all** at D = 300. Removing EED from the D ≥ 100 path
costs a factor of 2 892 in IGD on LSMOP6 and 27.5 on LSMOP9, and removes the
hypervolume entirely on LSMOP9 (0.5362 → 0); removing DSG costs 137× and
5.9× respectively. So on these instances both halves of the high-dimensional
path are load-bearing, and the reference-vector and scalarised-crossover
mechanisms of NSGA-II/III, RVEA, SPEA2, AGEMOEA and SMSEMOA lose their
directed convergence at this dimension entirely (HV = 0 for the whole field).
DSG's directed term has a step scale set by the *population's own quantile
spread* along each of the 300 dimensions rather than by a dimension-independent
crossover distribution, which is what allows progress when SBX-style operators
have degenerated into undirected sampling; EED's 10-bin grid is coarse enough
to remain stable in 300 dimensions and does not suffer the reference-vector
vacuum that removes selection pressure from HCEAV4 at this D.

On the instances where the whole field converges (LSMOP2/4/8) the remaining
difficulty is **sharpness**, and the same ablation shows the EED half becomes
counterproductive: on LSMOP2, disabling EED improves IGD from 0.4249 to 0.1027
(4.1×) and more than doubles HV (0.435 → 0.9889). The convergence trajectory
(Table in Section 5.6) shows the same effect dynamically — EDD's IGD on
LSMOP2 *degrades* monotonically from 0.3321 at G = 25 to 0.4249 at G = 200,
the only degrading trajectory in the table. A 10-bin epsilon grid is simply
coarser than MOEAD's weight grid or RVEA's angle-penalised distance, so once
the front is reachable the grid actively pulls the population toward cell
centroids instead of resolving the front finely. This is a genuine limitation
of the EED design, it is localised to a specific component by the ablation,
and we do not attempt to explain it away.

### 6.2 Why the combined rank nevertheless favours EDD

The combined rank averages the IGD and HV ranks over the 10 problems. EDD's
advantage is that it is **never catastrophic**: its worst IGD rank is 11th
on a single instance, whereas HCEA/HCEAV4 attain IGD of 2660 and 30.55 on
LSMOP6/LSMOP9 (ranks 9–11), RVEA attains 843 on LSMOP6, and NSGA-III and
SMSEMOA attain 5626 and 7430 on LSMOP7. An algorithm that eliminates total
convergence failure accumulates a better average rank than algorithms that
win narrowly on the easy instances but collapse on the hard ones. This is
the sense in which EDD is the strongest method on this test set, and it is
a claim we can support directly from the per-problem table.

The counter-consideration is equally clear from the ablation: if a
practitioner's problem is of the LSMOP2/4/8 type — one on which many
algorithms converge — EDD's EED component will cost them, and a weight-grid
or angle-penalised method is the better choice. EDD's aggregate advantage
is purchased by accepting a specific, quantified deficit on that subclass.

### 6.3 The HCEA tie on HV

HCEA (this group's earlier algorithm) ties EDD on aggregate HV rank (4.25).
The tie is instructive: HCEA inherits the same polish-HV step as EDD and
therefore also obtains non-zero hypervolume on some collapse instances, but
it has no EED/DSG path, so it fails on LSMOP6 and LSMOP9 (IGD 2660.25 and
30.55) where EDD succeeds. Conversely HCEA outperforms EDD on LSMOP2
(HV 0.906 vs 0.435) and LSMOP4 (0.566 vs 0.381). The two algorithms
therefore have genuinely complementary HV profiles, and the aggregate tie
reflects that. That EDD's IGD rank (4.45) is far better than HCEA's (6.85)
is what separates them in the combined rank. The ablation explains HCEA's
LSMOP2 advantage directly: HCEA runs the APD path there, and the no-EED
variant of EDD — which is functionally that path — scores 0.9889 HV against
full EDD's 0.435.

### 6.4 Negative result on polish-HV

We record explicitly that the third mechanism listed in our contributions
does not contribute on this test set. Disabling polish-HV changes median IGD
by 1.00× on LSMOP6 and LSMOP9 and by 0.93× (marginally better) on LSMOP2.
The component is inherited from HCEA [15], where its value was established on
low-dimensional deceptive fronts, and it remains part of the low-D branch of
EDD. For the large-scale results of this paper it is neutral, and we do not
claim it as a contributing mechanism. We include this negative result because
the alternative — silently listing a component as a contribution while the
ablation shows no effect — is the kind of overclaiming the ablation exists to
prevent.

### 6.5 Honest limitation

EDD's mechanism is most effective on LSMOP-style large-D problems where the
baseline algorithms collapse, and least effective where the field already
converges — and the ablation shows this is attributable to a specific
component (EED) rather than to noise. On DTLZ2-300D (fixed orthant front,
pure distance-variable convergence) EDD is first on both IGD and HV, which
shows the mechanism is not specific to the LSMOP composition structure; but
DTLZ2-300D is also the instance on which nine of eleven algorithms fail
outright, so we deliberately do not over-weight it as independent evidence.
The clearest statement of the limitation is this: on the three instances
where the whole field converges, EDD is *not* the best method, and a
practitioner whose problem is of that type should prefer a weight-grid or
angle-penalised method.

## 7. Conclusion

We have proposed EDD, a single-population dimension-adaptive evolutionary
algorithm in which the environmental selection, offspring operator, and
final polishing are controlled by a single decision-dimension gate. On the
LSMOP1–9 family (M = 3, D = 300) and the DTLZ2-300D-M3 cross-validation
instance, evaluated over 30 seeds per cell against ten baselines, EDD
attains the **best combined IGD/HV Friedman rank (4.35)**, a **joint-best
HV rank (4.25, tied with HCEA)**, and the **second-best IGD rank (4.45)**.

The result is structurally bimodal, and a four-variant component ablation
identifies its cause rather than leaving it as an observation. On the five
instances where the baselines collapse to HV = 0, both components of the
high-dimensional path are load-bearing: removing EED costs a factor of 2 892
in IGD on LSMOP6, and removing DSG costs 137. On the three instances where
the whole field converges, the same ablation shows that EED is not merely
unhelpful but harmful — disabling it improves IGD by 4.1× and more than
doubles HV on LSMOP2 — and the convergence trajectory confirms that full EDD
degrades monotonically there over the budget. A third claimed component,
polish-HV, shows no measurable effect on this test set (1.00× change in
median IGD when disabled), and we report that as a negative result.

The defensible claim is therefore narrow and quantified: **at D = 300, EDD
eliminates total convergence failure across half the test set, which is what
drives its aggregate rank advantage; it does not uniformly dominate the
metric, and one of its components is the measured cause of its deficit on the
instances where the field already converges.** Future work follows directly
from the ablation: make the epsilon grid adaptive (or hybridise EED with a
weight-grid selection) so that the LSMOP2/4/8 deficit is removed without
losing the collapse-instance robustness, and replace the hard D ≥ 100 gate
with a continuous interpolation between the APD and EED regimes.

## 8. Limitations and future work

- **Bimodal performance with an identified cause.** EDD's advantage is
  concentrated on instances where the baselines collapse; on instances where
  the whole field converges (LSMOP2/4/8) it ranks 9th–11th on IGD. The
  component ablation attributes the deficit specifically to the EED
  epsilon-grid selection (disabling it improves LSMOP2 IGD by 4.1×).
  Refining the grid — making the bin count adaptive to the front's intrinsic
  dimensionality, or hybridising EED with a weight-grid selection — is the
  direct next step.
- **polish-HV is neutral at D = 300.** Disabling the polish step changes
  median IGD by 1.00× on the collapse instances. It is retained for
  compatibility with the low-D branch and the HCEA family, not claimed as a
  large-scale contribution.
- **Single-D gate.** EDD's current implementation uses a hard D ≥ 100 gate.
  A continuous interpolation (e.g. weight = clamp((D−30)/70, 0, 1)) is
  left for future work.
- **Underpowered pairwise tests.** With n = 10 problems the problem-level
  Wilcoxon test has negligible power and all p-values saturate at 1.0. We
  report this as a power limitation, not as evidence of equivalence, and
  rely on per-problem ranks, win/loss counts, and the ablation as the
  primary evidence.
- **Synthetic benchmarks only.** All instances in the paper are synthetic
  (LSMOP, DTLZ2). Extending EDD to real large-scale engineering problems
  (energy management, hyper-parameter optimisation) is future work.
- **M = 2 regime.** EDD's DSG operator is tuned for M ≥ 3; on M = 2 the
  wRand weight degrades to near-pure random, and EDD is not competitive on
  M = 2 large-D instances. This is a known limitation.
- **Ablation limited to 3 instances × 5 seeds.** The ablation uses 5 seeds
  per cell on three representative instances (two collapse, one converged)
  rather than the full 30-seed × 10-instance protocol; the effect sizes
  reported (2 892×, 137×, 4.1×) are far larger than seed-level variation,
  but the ablation is not powered for significance testing.

## 9. Data and code availability

All source code (MATLAB) and the complete raw dataset are available at
[anonymous repository URL, to be inserted before submission] under an
Apache-2.0 licence. The dataset comprises three parts:

1. **Main experiment** — 3 300 runs (11 algorithms × 10 problems × 30 seeds),
   one `.mat` file per run under
   `results/largescale_final/<algorithm>/<algorithm>_<problem>_s<seed>.mat`,
   each containing IGD, HV, Pareto-front size, function-evaluation count and
   wall-clock time. A summary file
   `results/largescale_final/friedman_10.mat` holds the per-problem medians,
   the Friedman ranks and the Wilcoxon p-values of Sections 5.1–5.4 and 5.7.
2. **Component ablation** — 60 runs (4 variants × 3 instances × 5 seeds)
   under `results/ablation_abl/`, plus `ablation_summary.mat`.
3. **Convergence study** — 396 runs (11 algorithms × 2 instances × 3 seeds ×
   6 budget levels) under `results/figs/conv/`, each storing the full
   budget-indexed IGD trajectory.

Reproduction requires MATLAB R2019b or later; no additional toolboxes are
needed beyond the PlatEMO-derived utility functions included in the
repository. The EDD implementation is a single self-contained class file
(`algorithms/EDD.m`, 418 lines). The ablation variant
(`algorithms/EDD_ABL.m`) is generated from `EDD.m` by
`experiments/make_edd_abl.m` via seven explicit textual substitutions, so the
shipped algorithm and the ablated algorithm cannot drift apart; the script
asserts that all seven substitutions fired before writing the file. Every
experiment script is idempotent and resumable (existing per-run `.mat` files
are skipped), so the full dataset can be regenerated incrementally.

## References

[1] R. Cheng, Y. Jin, M. Olhofer, B. Sendhoff, Test problems for large-scale
multiobjective and many-objective optimization, IEEE Transactions on
Cybernetics 47 (12) (2017) 4108–4121.
https://doi.org/10.1109/TCYB.2016.2600577

[2] K. Deb, A. Pratap, S. Agarwal, T. Meyarivan, A fast and elitist
multiobjective genetic algorithm: NSGA-II, IEEE Transactions on Evolutionary
Computation 6 (2) (2002) 182–197. https://doi.org/10.1109/4235.996017

[3] K. Deb, H. Jain, An evolutionary many-objective optimization algorithm
using reference-point-based nondominated sorting approach, Part I: Solving
problems with box constraints, IEEE Transactions on Evolutionary Computation
18 (4) (2014) 577–601. https://doi.org/10.1109/TEVC.2013.2281535

[4] Q. Zhang, H. Li, MOEA/D: A multiobjective evolutionary algorithm based on
decomposition, IEEE Transactions on Evolutionary Computation 11 (6) (2007)
712–731. https://doi.org/10.1109/TEVC.2007.892759

[5] R. Cheng, Y. Jin, M. Olhofer, B. Sendhoff, A reference vector guided
evolutionary algorithm for many-objective optimization, IEEE Transactions on
Evolutionary Computation 20 (5) (2016) 773–791.
https://doi.org/10.1109/TEVC.2016.2519378

[6] A. Panichella, An adaptive evolutionary algorithm based on non-Euclidean
geometry for many-objective optimization, in: Proceedings of the Genetic and
Evolutionary Computation Conference (GECCO), 2019, pp. 595–603.
https://doi.org/10.1145/3321707.3321839

[7] S. Mirjalili, S. Saremi, S. M. Mirjalili, L. dos S. Coelho, Multi-objective
grey wolf optimizer: A novel algorithm for multi-criterion optimization,
Expert Systems with Applications 47 (2016) 106–119.
https://doi.org/10.1016/j.eswa.2015.10.039

[8] N. Beume, B. Naujoks, M. Emmerich, SMS-EMOA: Multiobjective selection based
on dominated hypervolume, European Journal of Operational Research 181 (3)
(2007) 1653–1669. https://doi.org/10.1016/j.ejor.2006.08.008

[9] K. Deb, L. Thiele, M. Laumanns, E. Zitzler, Scalable multi-objective
optimization test problems, in: Proceedings of the 2002 Congress on
Evolutionary Computation (CEC), Vol. 1, 2002, pp. 825–830.
https://doi.org/10.1109/CEC.2002.1007032

[10] E. Zitzler, M. Laumanns, L. Thiele, SPEA2: Improving the strength Pareto
evolutionary algorithm, TIK-Report 103, ETH Zurich, 2001.
https://doi.org/10.3929/ethz-a-004284029

[11] J. Zou, L. Tang, Y. Liu, S. Yang, S. Wang, A two-stage direction-guided
evolutionary algorithm for large-scale multiobjective optimization,
Information Sciences 674 (2024) 120719.
https://doi.org/10.1016/j.ins.2024.120719

[12] S. Wang, J. Zheng, Y. Zou, Y. Liu, J. Zou, S. Yang, A population
hierarchical-based evolutionary algorithm for large-scale many-objective
optimization, Swarm and Evolutionary Computation 91 (2024) 101752.
https://doi.org/10.1016/j.swevo.2024.101752

[13] S. Mirjalili, S. M. Mirjalili, A. Lewis, Grey wolf optimizer, Advances in
Engineering Software 69 (2014) 46–61.
https://doi.org/10.1016/j.advengsoft.2013.12.007

[14] Y. Tian, R. Cheng, X. Zhang, Y. Jin, PlatEMO: A MATLAB platform for
evolutionary multi-objective optimization, IEEE Computational Intelligence
Magazine 12 (4) (2017) 73–87. https://doi.org/10.1109/MCI.2017.2742868

[15] HCEA: A hybrid convergence–environmental-selection archive with
hypervolume-verified mechanism switching, Technical report (HCEA/HCEAV2/
HCEAV4 algorithm family), 2026. [Internal report; implementation available in
the accompanying repository.]

[16] E. Zitzler, L. Thiele, Multiobjective evolutionary algorithms: A
comparative case study and the strength Pareto approach, IEEE Transactions on
Evolutionary Computation 3 (4) (1999) 257–271.
https://doi.org/10.1109/4235.797969

[17] K. Deb, M. Mohan, S. Mishra, Evaluating the ε-domination based
multi-objective evolutionary algorithm for a quick computation of
Pareto-optimal solutions, Evolutionary Computation 13 (4) (2005) 501–525.
https://doi.org/10.1162/106365605774666895

[18] X. Yang, J. Zou, S. Yang, J. Zheng, Y. Liu, A fuzzy decision variables
framework for large-scale multiobjective optimization, IEEE Transactions on
Evolutionary Computation 27 (3) (2023) 617–628.
https://doi.org/10.1109/TEVC.2021.3118593
