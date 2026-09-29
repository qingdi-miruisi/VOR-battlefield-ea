# GitHub Upload Checklist — EDD large-scale manuscript

**Status: prepared, not uploaded.** No remote repository has been created and
nothing has been pushed. This document lists exactly what to publish when the
manuscript is accepted (or when an anonymised repository is needed for review).

Legend: **[REQ]** must be uploaded · **[REC]** strongly recommended ·
**[OPT]** optional / judgement call.

---

## 1. Code — required

| Path | Flag | Note |
|---|---|---|
| `algorithms/EDD.m` | **[REQ]** | the proposed algorithm, 418 lines, self-contained |
| `algorithms/EDD_ABL.m` | **[REQ]** | ablation variant; needed for the ablation to be reproducible |
| `experiments/make_edd_abl.m` | **[REQ]** | generates `EDD_ABL.m` from `EDD.m`, asserts 7 substitutions |
| `algorithms/HCEA.m`, `algorithms/HCEAV4.m` | **[REQ]** | prior work in the family; two of the ten baselines |
| `algorithms/NSGA2.m` `NSGA3.m` `SPEA2.m` `AGEMOEA.m` `SMSEMOA.m` `MOGWO.m` `RVEA.m` `MOEAD.m` | **[REQ]** | remaining eight baselines |
| `problems/DTLZ2_300D_M3.m` | **[REQ]** | the new cross-validation instance |
| `problems_official/` (LSMOP, MaF, UF, CF, EMO, WFG) | **[REQ]** | official problem classes (PlatEMO-derived — see §5 licence) |
| `problems/` (DTLZ1-7, WFG1-9, ZDT*, helpers) | **[REQ]** | problem definitions used by the adapters |
| `problems_ext/extProbs.m` | **[REC]** | problem-set assembly used by the drivers |
| `algorithms/utils/` | **[REQ]** | NDSort, IGD, HV, OperatorGA, UniformPoint, etc. |
| `problems/wfg_toolbox/` | **[REQ]** | WFG transformation helpers |

## 2. Code — experiment drivers (required for reproduction)

| Path | Flag | Note |
|---|---|---|
| `experiments/run_largescale_final.m` | **[REQ]** | main driver |
| `experiments/run_ls_EDD.m`, `run_ls_RVEA.m`, `run_ls_MOEAD.m`, `run_ls_MOGWO.m`, `run_ls_HCEA.m`, `run_ls_HCEAV4.m`, `run_ls_SMSEMOA.m` | **[REQ]** | per-algorithm entry points |
| `experiments/run_ls_batch9.m` | **[REQ]** | NSGA2/NSGA3/SPEA2/AGEMOEA + the rest in one pass |
| `experiments/run_ls_dtlz2_backfill.m` | **[OPT]** | superseded one-problem backfill |
| `experiments/friedman_10.m` | **[REQ]** | Friedman ranks + Wilcoxon + Holm for Tables 1, 2, 6 |
| `experiments/run_ablation_edd.m` | **[REQ]** | component ablation (Table 4) |
| `experiments/run_conv_a.m` `run_conv_b.m` `run_conv_c.m` | **[REQ]** | convergence study (Table 5, Fig. 1) |
| `experiments/run_pf_data.m` | **[REQ]** | Pareto front capture (Fig. 2) |
| `experiments/make_figs.m`, `experiments/make_pf_figs.m` | **[REQ]** | figure generation |
| `experiments/analyze_abl_conv.m` | **[REC]** | ablation/convergence summary tables |
| `experiments/run_conv_curves.m`, `run_conv_curves_impl.m`, `run_conv_s1/s2/s3.m` | **[OPT]** | superseded sharded variants — safe to omit |
| `experiments/friedman_lsmop.m`, `friedman_m3.m`, `run_m3_edd16*.m` | **[OPT]** | earlier development work, not part of the paper |
| `experiments/run_ablation.m` | **[OPT]** | older HCEAV2 ablation, unrelated to this paper |
| `run_main.m` | **[REQ]** | one-call pipeline entry point (see §8 below) |

## 3. Data — required

| Path | Flag | Size (files) | Note |
|---|---|---|---|
| `results/largescale_final/{EDD,HCEA,HCEAV4,NSGA2,NSGA3,SPEA2,AGEMOEA,SMSEMOA,MOGWO,RVEA,MOEAD}/` | **[REQ]** | 3 300 `.mat` | main experiment, one file per run |
| `results/largescale_final/friedman_10.mat` | **[REQ]** | 1 | derived statistics for Tables 1–3, 6 |
| `results/ablation_abl/` | **[REQ]** | 60 + 1 | component ablation + `ablation_summary.mat` |
| `results/figs/conv/` | **[REQ]** | 22 | convergence trajectories (Table 5, Fig. 1) |
| `results/figs/pf/` | **[REQ]** | 15 | Pareto front capture (Fig. 2) |
| `results/new_algo/`, `results/new_algo_v12/`, `results/baselines_ext/`, `results/m3_focus/` | **[OPT]** | — | earlier-campaign data retained for provenance; not cited by the paper. Exclude to keep the repository small, or include under `results/_archive/` for full transparency. |
| `results/main/`, `results/main_v4/`, `results/merged_v4/`, etc. | **[OPT]** | — | pre-existing HCEA-family results, unrelated to this paper |

**Data format.** Every run file contains a single struct `out` with fields
`IGD`, `HV`, `nFE`, `elap`, `PPS` (plus `mech`/`switchGen` for the ablation).
Saved with MATLAB `-v7.3`, one file per run, so the loader works without any
of the drivers having to be re-run.

**Size guidance.** The 3 300 main-experiment files are the bulk of the
repository. If a size limit is a problem, publish
`results/largescale_final/friedman_10.mat` plus the three smaller result sets
(ablation, convergence, PF) and provide the per-run files via a Zenodo/Figshare
DOI — but note that per-run files are what makes the Friedman/Wilcoxon
statistics independently checkable, so they should remain available.

## 4. Figures — required

| Path | Flag | Note |
|---|---|---|
| `results/figs/out/conv_LSMOP6.png`, `conv_LSMOP2.png` | **[REQ]** | Fig. 1 |
| `results/figs/out/pf_LSMOP6_panels.png`, `pf_LSMOP2_panels.png`, `pf_DTLZ2_300D_M3_panels.png` | **[REQ]** | Fig. 2 (main panels) |
| `results/figs/out/pf_LSMOP6_3d.png`, `pf_LSMOP2_3d.png`, `pf_DTLZ2_300D_M3_3d.png` | **[REC]** | Fig. 2 (3-D views) |
| `results/figs/out/ablation_bar.png` | **[REQ]** | Fig. 3 |

## 5. Documentation — required

| Path | Flag | Note |
|---|---|---|
| `README.md` | **[REQ]** | the repository README (mirror of `docs/GITHUB_README.md`) |
| `LICENSE` | **[REQ]** | Apache-2.0 |
| `NOTICE` | **[REQ]** | PlatEMO attribution for the derived problem/utility files |
| `CITATION.cff` | **[REC]** | machine-readable citation metadata |
| `docs/UPLOAD_CHECKLIST.md` | **[REC]** | this file |
| `docs/GITHUB_README.md` | **[REC]** | source of the repository README (§1–10) |
| `paper/main.md`, `paper/tables.tex`, `paper/cover_letter.md` | **[REC]** | manuscript sources; include a preprint only if the journal's policy permits |
| `PROGRESS.md` | **[OPT]** | development log; contains internal notes (Chinese) not intended for the public repository |

### 5.1 Licence handling for PlatEMO-derived files

`problems_official/`, several files in `problems/`, and `algorithms/utils/`
are derived from **PlatEMO** (Tian, Cheng, Zhang, Jin, *IEEE Computational
Intelligence Magazine* 12(4), 2017), which is distributed under the
**GNU GPL v3**. Two consequences:

1. Do **not** place a blanket Apache-2.0 notice on `problems_official/`,
   `algorithms/utils/` or `problems/wfg_toolbox/`. Keep the original PlatEMO
   headers intact and document the situation in `NOTICE`.
2. If a single repository-wide licence is required, the safe options are
   (a) license the whole repository under GPL-3.0, or (b) mark the original
   contribution (`algorithms/EDD.m`, `algorithms/EDD_ABL.m`,
   `problems/DTLZ2_300D_M3.m`, `experiments/`, `results/`, `paper/`) as
   Apache-2.0 and the derived directories as GPL-3.0. Confirm the choice with
   the corresponding author before publishing.

## 6. Do NOT upload

| Path | Reason |
|---|---|
| `_tmp_official/PlatEMO-master/` | vendored upstream source tree; do not re-host |
| `docs/spill/`, `*.log`, `*.bak`, `_archive/` | scratch files |
| Any file containing local absolute paths (`D:\harness工作\...`) | path leakage; the drivers already use `cd(...)` with the repository path — replace with relative/path-agnostic code before publishing |
| `results/_archive/` | only if deliberately excluding earlier campaigns (§3) |

**Action required before publishing.** The `experiments/*.m` drivers and
`algorithms/EDD*.m` hard-code the working directory, e.g.

```matlab
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
```

Replace each such line with a path-agnostic form before upload:

```matlab
cd(fileparts(fileparts(mfilename('fullpath'))));   % works for experiments/*.m
```

or simply delete the `cd` line and document that the user must run from the
repository root. This is the one edit that **must** be made; every other file
is publishable as-is.

## 7. Suggested repository release procedure

```bash
# 1. Create the working copy and drop the excluded paths
#    (see sections 5 and 6)
# 2. Make the drivers path-agnostic (section 6, "Action required")
# 3. Verify the pipeline still runs end-to-end from a clean checkout
matlab -batch "cd('algorithm'); run_main"
# 4. Check that no absolute local path survives
grep -rn "harness工作" . && echo "FAIL: leaked path" || echo "OK"
# 5. Initialise and tag
git init
git add .
git commit -m "EDD v12: reference implementation and full experimental dataset"
git tag -a v1.0 -m "Manuscript submission release"
```

## 8. One-call pipeline (`run_main.m`)

The repository should ship a single entry point that runs the stages in the
correct order. Contents:

```matlab
function run_main()
% RUN_MAIN  Reproduce the complete EDD large-scale study end-to-end.
%            Every stage is idempotent: existing per-run .mat files are
%            skipped, so the pipeline can be interrupted and resumed.
    root = fileparts(fileparts(mfilename('fullpath')));
    cd(root);
    addpath(fullfile(root,'experiments'));

    fprintf('=== 1/6  Main experiment (11 algorithms x 10 problems x 30 seeds)\n');
    run_ls_EDD; run_ls_RVEA; run_ls_MOEAD; run_ls_MOGWO;
    run_ls_HCEA; run_ls_HCEAV4; run_ls_SMSEMOA; run_ls_batch9;

    fprintf('=== 2/6  Statistics (Friedman + Wilcoxon + Holm)\n');
    friedman_10;

    fprintf('=== 3/6  Component ablation\n');
    make_edd_abl; run_ablation_edd;

    fprintf('=== 4/6  Convergence study\n');
    run_conv_a; run_conv_b; run_conv_c;

    fprintf('=== 5/6  Pareto fronts\n');
    run_pf_data;

    fprintf('=== 6/6  Figures\n');
    make_figs; make_pf_figs; analyze_abl_conv;

    fprintf('\n=== done. See results/ and results/figs/out/ ===\n');
end
```

**Expected runtime.** Several hours on a single machine. The dominant costs
are MOGWO (~4 700 s for 300 runs) and SMSEMOA (~3 600 s for 229 runs), both
due to hypervolume-based O(N²) selection at D = 300; the remaining nine
algorithms take under 30 minutes each. Stages 2–6 together take minutes once
stage 1 is complete.

## 9. Pre-publication checklist

- [ ] Replace hard-coded absolute paths in all `experiments/*.m` (section 6)
- [ ] `grep -rn "harness工作" .` returns nothing
- [ ] `run_main` completes from a clean checkout
- [ ] LICENSE and NOTICE written; PlatEMO attribution intact (section 5.1)
- [ ] `README.md` at repository root mirrors `docs/GITHUB_README.md`
- [ ] `CITATION.cff` contains the final title, authors and journal
- [ ] `[GitHub URL]`, `[Authors]`, `[Affiliation]`, `[Year]` placeholders in
      `paper/main.md`, `paper/cover_letter.md`, `docs/GITHUB_README.md`
      replaced with concrete values
- [ ] Verified that `results/largescale_final/` contains exactly 3 300 files
      and `results/ablation_abl/` exactly 60
- [ ] `PROGRESS.md` either excluded or reviewed for content not meant to be
      public
- [ ] Journal's data-availability policy checked; if a Zenodo/Figshare DOI is
      required, deposit `results/largescale_final/` there and cite the DOI in
      `paper/main.md` §9
