function run_agemoa_retry()
    % AGEMOEA 缺失种子重试（MaF10/WFG1_M3/WFG1_M5 各 1-2 个失败种子，Inf 瞬态）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    [problems, names] = extProbs();
    algs = {'AGEMOEA'};
    an = algs{1};
    pIdx = find(strcmp(names,'MaF10'))+find(strcmp(names,'WFG1_M3'))+find(strcmp(names,'WFG1_M5'));
    t0 = tic;
    for p = pIdx
        pn = names{p}; prob = problems{p};
        doneThis = 0; failThis = 0;
        for s = 1:30
            fn = fullfile('results\baselines_ext', sprintf('%s_%s_s%d.mat', an, pn, s));
            if isfile(fn), continue; end
            try
                alg = AGEMOEA(100, 200, s);
                [Pop, Res] = alg.optimize(prob);
                PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
                out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                save(fn, 'out', '-v7.3');
                doneThis = doneThis + 1;
            catch err
                failThis = failThis + 1;
                fprintf('FAIL %s %s s%d: %s\n', an, pn, s, err.message);
            end
        end
        fprintf('%s %s: 补齐 %d, 失败 %d (elapsed=%.0fs)\n', an, pn, doneThis, failThis, toc(t0));
    end
    fprintf('=== agemoa_retry 完成 ===\n');
end
