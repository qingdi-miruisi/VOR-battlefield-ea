function run_pf_data()
    % Pareto 前沿数据：3 问题 × 5 算法 × 1 种子（s=1）
    % 记录每个算法在该问题上的最终 Pareto 前沿 Res.F（仅第一非支配层）
    % 数据存 results/figs/pf/<alg>_<prob>.mat（每算法即存，小步慢跑）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir('results\figs\pf'), mkdir('results\figs\pf'); end

    algs = {'EDD','HCEAV4','MOEAD','RVEA','NSGA2'};
    probNames = {'LSMOP6','LSMOP2','DTLZ2_300D_M3'};
    seed = 1; N = 100; G = 200;
    t0 = tic;

    for p = 1:numel(probNames)
        pn = probNames{p};
        if strcmp(pn, 'DTLZ2_300D_M3')
            prob = DTLZ2_300D_M3();
        else
            prob = OfficialProblem(pn, 3, 300);
        end
        PFtrue = prob.ParetoFront(500);
        for a = 1:numel(algs)
            an = algs{a};
            fn = fullfile('results\figs\pf', sprintf('%s_%s.mat', an, pn));
            if isfile(fn), fprintf('skip %s %s\n', an, pn); continue; end
            try
                alg = feval(an, N, G, seed);
                [~, Res] = alg.optimize(prob);
                F = Res.F;                     % 第一非支配层目标值
                igd = IGD(F, PFtrue);
                save(fn, 'an', 'pn', 'F', 'PFtrue', 'igd', 'seed', 'N', 'G', '-v7.3');
                fprintf('%-8s %-14s frontSize=%3d IGD=%.4g  elapsed=%.0fs\n', ...
                    an, pn, size(F,1), igd, toc(t0));
            catch err
                fprintf('FAIL %s %s: %s\n', an, pn, err.message);
            end
        end
    end
    fprintf('=== PF 数据完成 %.0fs ===\n', toc(t0));
end
