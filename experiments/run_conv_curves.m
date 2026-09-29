function run_conv_curves(shardIdx)
    % 收敛曲线：预算扫描法（所有算法统一口径，公平可比）
    % 对每个 (算法, 问题) 在预算 G = [25 50 75 100 125 150 175 200] 各跑 3 种子，
    % 记录该预算下的最终 IGD → 得到以函数评估次数为横轴的收敛轨迹。
    % 用法：run_conv_curves(1) / (2) / (3)  —— 三片并行
    % 数据存 results/figs/conv/<alg>_<prob>.mat
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir('results\figs\conv'), mkdir('results\figs\conv'); end

    allAlgs = {'EDD','HCEA','HCEAV4','NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    % 三片切分
    switch shardIdx
        case 1, algs = allAlgs(1:4);    % EDD HCEA HCEAV4 NSGA2
        case 2, algs = allAlgs(5:8);    % NSGA3 SPEA2 AGEMOEA SMSEMOA
        case 3, algs = allAlgs(9:11);   % MOGWO RVEA MOEAD
        otherwise, error('shardIdx 1..3');
    end
    probNames = {'LSMOP2','LSMOP6','LSMOP9'};   % 1 收敛题 + 2 崩溃题
    budgets = [25 50 75 100 125 150 175 200];
    seeds = 1:3;
    N = 100;

    probObjs = cell(1,numel(probNames));
    for i = 1:numel(probNames)
        probObjs{i} = OfficialProblem(probNames{i}, 3, 300);
    end

    t0 = tic;
    for a = 1:numel(algs)
        an = algs{a};
        for p = 1:numel(probNames)
            pn = probNames{p};
            fn = fullfile('results\figs\conv', sprintf('%s_%s.mat', an, pn));
            if isfile(fn), fprintf('skip %s %s\n', an, pn); continue; end
            prob = probObjs{p};
            PF = prob.ParetoFront(500);
            traj = nan(numel(budgets), numel(seeds));
            for b = 1:numel(budgets)
                for s = 1:numel(seeds)
                    try
                        alg = feval(an, N, budgets(b), seeds(s));
                        [~, Res] = alg.optimize(prob);
                        traj(b, s) = IGD(Res.F, PF);
                    catch err
                        fprintf('  FAIL %s %s G=%d s=%d: %s\n', an, pn, budgets(b), seeds(s), err.message);
                    end
                end
            end
            fe = N * (budgets + 1);   % 函数评估次数（初始化 + 每代 N）
            save(fn, 'an', 'pn', 'budgets', 'fe', 'seeds', 'traj', '-v7.3');
            fprintf('%s %s done (median@G200=%.4g) elapsed=%.0fs\n', an, pn, ...
                median(traj(end,:), 'omitnan'), toc(t0));
        end
    end
    fprintf('=== shard %d 完成 elapsed=%.0fs ===\n', shardIdx, toc(t0));
end
