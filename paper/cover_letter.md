# Cover Letter — EDDV8 grafted SOTA-operator paper

**To:** The Editor-in-Chief, *Applied Soft Computing* (or *Knowledge-Based Systems*)

**From:** Yuxuan Zhang, corresponding author
Graduate School, Army Engineering University of the PLA, Nanjing, China
Email: 3150644070@qq.com

---

Dear Editor,

We submit our manuscript entitled **"Grafting 2026 SOTA Operators into
a Dimension-Adaptive Framework for Large-Scale and Constrained
Multi-Objective Optimization"** for consideration in *Applied Soft
Computing* (or *KBS*, SCI Q1).

## Positioning in one paragraph

We propose **EDDV8**, a dimension-adaptive evolutionary framework that
grafts the component mechanisms of three 2026 state-of-the-art (SOTA)
algorithms (FDSEA, GDVTSF, MOEA-IB) into a unified EDD interface,
preserving dimension-aware gating so that a single codebase services
both the large-scale ($D=300$) and the constrained low-dimensional
($D=10$--$15$, CF/MW) battlefields. Our central contributions are
two: (i) on the LSMOP1--9 benchmark family ($M=3$, $D=300$), EDDV8
ties the original EDD at the 4th--5th combined IGD/HV Friedman rank
out of 12 (FDSEA $1.78$, MOEA-IB $2.78$, GDVTSF $3.22$, EDDV8 $6.00$),
preserving the elimination of total convergence failure on five of ten
instances where all eight traditional baselines collapse to
$\mathrm{HV}=0$; (ii) on the official constrained CF/MW family
(CF1--10, MW1--14), EDDV8's constraint-aware NSGA-2 selection
\emph{reduces} the structural PPS collapse that characterised the
original EDD\_cf --- the MW-family median PPS rises from
$\approx 1$ to $\approx 24$ and the MW1 median IGD improves from
$11.2$ to $2.1$ (factor $\sim$5) --- though the collapse persists on
eleven of the twenty-four CF/MW instances, which we report in full as
the residual boundary of the selection mechanism.

## Honest reporting — three explicit limitations

We do **not** claim EDDV8 to be a uniformly dominant method. Three
limitations are reported in full and are central to the paper's
scientific value:

1. **Against the 2026 SOTA trio (FDSEA, GDVTSF, MOEA-IB)** on the
   LSMOP family, EDDV8 ties the original EDD at rank 4--5 in the
   12-algorithm aggregate and does not lead on any individual
   instance in per-problem IGD. The SOTA trio resolves the front more
   sharply on converged instances and does not pay the PPS-collapse
   cost on constrained low-$D$ problems.

2. **On the official constrained CF/MW family** (CF1--10, MW1--14,
   $D=10$--$15$), EDDV8 ranks 4th of 5 in the 5-algorithm Friedman
   test (MOEA-IB $0.79$, FDSEA $1.38$, GDVTSF $1.63$, EDDV8 $2.83$,
   original EDD\_cf $3.75$). The PPS collapse persists on eleven of
   the twenty-four instances (PPS $\le 10$), including six where
   EDDV8's median PPS degenerates to a single point (CF10, MW1, MW4,
   MW5, MW9, MW12). This residual boundary localises to the
   constraint-aware selection mechanism, not to the grafted
   operators (which are gated to $D \ge 100$ and do not contribute on
   the CF/MW battlefield).

3. **On the three converged LSMOP instances** (LSMOP2/4/8), EDDV8's
   per-instance IGD matches the original EDD: the grafted operators
   (FDSEA initialisation, GDVTSF cluster-drift, MOEA-IB ReMO
   random-walk) do not change the median trajectory on this family.
   The grafted operators' value is structural --- they provide the
   constraint-aware selection mechanism that reduces the CF/MW PPS
   collapse --- rather than a direct IGD/HV improvement on the LSMOP
   converged instances.

## Why this paper matters

The value of this paper is a **quantified, component-level
characterisation of the boundary of a grafted SOTA-operator
framework**: the constraint-aware NSGA-2 selection reduces but does
not eliminate the PPS collapse of the original EDD\_cf on the CF/MW
family, and the grafted operators preserve the large-scale
robustness property of the original EDD at $D=300$ without changing
the per-seed IGD/HV medians. For practitioners, the paper provides a
clear decision rule: use EDDV8 when the concern is robustness against
baseline collapse on large-$D$ unconstrained problems (the mechanism
is load-bearing) or when solving constrained low-$D$ problems and a
partial PPS improvement over the original variant is acceptable;
prefer the 2026 SOTA methods when sharp front resolution on
converged instances or complete PPS retention on all CF/MW
instances is the objective.

## What we ask of the readers

We ask the reviewers to evaluate this paper on the basis of the
honesty and completeness of the residual-boundary analysis, not on
whether EDDV8 achieves a new SOTA. The paper is written to be a
**scientifically useful negative-result boundary study** even though
the positive results (robustness against collapse, partial PPS
improvement on CF/MW) are not uniform.

All source code and raw data are available at
[anonymous repository URL] under Apache-2.0. The manuscript has not
been published and is not under consideration elsewhere.

We suggest the following reviewers:
- [Reviewer 1 name, affiliation]
- [Reviewer 2 name, affiliation]

We declare no competing interests.

Sincerely,

**Yuxuan Zhang** (corresponding author)
Graduate School, Army Engineering University of the PLA
Nanjing, China
Email: 3150644070@qq.com
