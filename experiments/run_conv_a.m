function run_conv_a()
    % 收敛曲线 shard A: EDD, HCEA, HCEAV4, NSGA2
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir('results\figs\conv'), mkdir('results\figs\conv'); end
    algs = {'EDD','HCEA','HCEAV4','NSGA2'};
    probNames = {'LSMOP6','LSMOP2'};
    budgets = [25 50 100 150 200];
    seeds = 1:3;
    N = 100;
    t0 = tic;
    for a = 1:numel(algs)
        an = algs{a};
        for p = 1:numel(probNames)
            pn = probNames{p};
            fn = fullfile('results\figs\conv', sprintf('%s_%s.mat', an, pn));
            if isfile(fn), fprintf('skip %s %s\n', an, pn); continue; end
            prob = OfficialProblem(pn, 3, 300);
            PF = prob.ParetoFront(500);
            traj = nan(numel(budgets), numel(seeds));
            for b = 1:numel(budgets)
                for s = 1:numel(seeds)
                    try
                        alg = feval(an, N, budgets(b), seeds(s));
                        [~, Res] = alg.optimize(prob);
                        traj(b,s) = IGD(Res.F, PF);
                    catch err
                        fprintf('  FAIL %s %s G=%d s=%d: %s\n', an, pn, budgets(b), s, err.message);
                    end
                end
            end
            fe = N * (budgets + 1);
            save(fn, 'an', 'pn', 'budgets', 'fe', 'seeds', 'traj', '-v7.3');
            fprintf('%s %s done elapsed=%.0fs\n', an, pn, toc(t0));
        end
    end
    fprintf('=== shard A done %.0fs ===\n', toc(t0));
end
