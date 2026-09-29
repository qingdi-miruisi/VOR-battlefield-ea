function run_cf_mw_baselines()
% 任务4：8 传统基线在 CF1-10 + MW1-14 × 30 种子（原生约束处理）
% N=100 G=200 → results/cf_baselines/<ALG>/<PN>_<ALG>_s<k>.mat
% 8 基线：NSGA2/NSGA3/MOEAD/SPEA2/SMSEMOA/RVEA/AGEMOEA/MOGWO
% 用本地 OfficialProblem 桥接（CF/MW 走 Evaluation 提取 objs/cons）
% NDSort 已修 2参兼容：MW7/9/10/11/13/14 的官方 GetOptimum 调 NDSort(R,1) 不再崩
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    algs = {'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO'};
    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = 1:14, probs{end+1} = ['MW' num2str(i)]; end
    nP = numel(probs);
    N = 100; G = 200;

    for a = 1:numel(algs)
        an = algs{a};
        algDir = fullfile('results','cf_baselines', an);
        if ~isdir(algDir), mkdir(algDir); end
        nOk = 0;
        for p = 1:nP
            pn = probs{p};
            wrap = OfficialProblem(pn, 2, 10);
            PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
            okSeed = 0;
            for s = 1:30
                fn = fullfile(algDir, [pn '_' an '_s' num2str(s) '.mat']);
                if isfile(fn), okSeed = okSeed + 1; continue; end
                try
                    rng(s);
                    alg = feval(an, N, G, s);
                    [Pop, Res] = alg.run(wrap);
                    [fn2, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn2==1);
                    if isempty(nd), nd = 1:size(Pop.objs,1); end
                    F = Pop.objs(nd,:);
                    out.IGD = IGD(F, PF); out.HV = HV(F, ref);
                    out.nFE = Res.nFE; out.PPS = numel(nd);
                    save(fn, 'out', '-v7.3');
                    okSeed = okSeed + 1;
                catch err
                    fprintf('  %s %s s%d FAIL: %s\n', an, pn, s, err.message);
                end
            end
            if okSeed == 30, nOk = nOk + 1; end
        end
        fprintf('%s 24题中跑通=%d\n', an, nOk);
    end
    fprintf('=== 8 传统基线 CF/MW 完成 ===\n');
end
