function run_main()
% RUN_MAIN  Reproduce the complete EDD large-scale study end-to-end.
%
%   Stages
%     1/6  Main experiment  — 11 algorithms x 10 problems x 30 seeds
%     2/6  Statistics       — Friedman ranks + Wilcoxon + Holm
%     3/6  Ablation         — 4 component variants x 3 problems x 5 seeds
%     4/6  Convergence      — budget sweep, 11 algorithms x 2 problems x 3 seeds
%     5/6  Pareto fronts    — 5 algorithms x 3 problems, seed 1
%     6/6  Figures          — convergence, ablation, Pareto front plots
%
%   Every stage is idempotent: a per-run .mat file that already exists is
%   skipped, so the pipeline can be interrupted and resumed without rework.
%   Expect several hours of wall-clock time on a single machine; the dominant
%   costs are MOGWO and SMSEMOA (hypervolume-based O(N^2) selection at D=300).
%
%   Requirements: MATLAB R2019b or later, no additional toolboxes.

    root = fileparts(fileparts(mfilename('fullpath')));
    cd(root);
    addpath('problems'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF');
    addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext'); addpath('experiments');

    t0 = tic;
    fprintf('\n=== 1/6  Main experiment (11 algorithms x 10 problems x 30 seeds) ===\n');
    run_ls_EDD;
    run_ls_RVEA;
    run_ls_MOEAD;
    run_ls_MOGWO;
    run_ls_HCEA;
    run_ls_HCEAV4;
    run_ls_SMSEMOA;
    run_ls_batch9;      % NSGA2, NSGA3, SPEA2, AGEMOEA (and any remaining)

    fprintf('\n=== 2/6  Statistics (Friedman + Wilcoxon + Holm) ===\n');
    friedman_10;

    fprintf('\n=== 3/6  Component ablation ===\n');
    make_edd_abl;       % regenerate EDD_ABL.m from EDD.m, asserting substitutions
    run_ablation_edd;

    fprintf('\n=== 4/6  Convergence study ===\n');
    run_conv_a; run_conv_b; run_conv_c;

    fprintf('\n=== 5/6  Pareto fronts ===\n');
    run_pf_data;

    fprintf('\n=== 6/6  Figures ===\n');
    make_figs; make_pf_figs; analyze_abl_conv;

    fprintf('\n=== run_main complete in %.0f s ===\n', toc(t0));
    fprintf('    data    : results/largescale_final/, results/ablation_abl/, results/figs/\n');
    fprintf('    figures : results/figs/out/\n');
end
