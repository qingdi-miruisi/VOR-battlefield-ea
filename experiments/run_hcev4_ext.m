function run_hcev4_ext()
    % HCEAV4 × 80 扩展集 → results/new_algo（小步慢跑，断点续跑）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir('results\new_algo'), mkdir('results\new_algo'); end
    algs = {'HCEAV4'};
    [problems, names] = extProbs();
    nDone = 0; nSkip = 0; nFail = 0; t0 = tic;
    for a = 1:1
        an = algs{a};
        for p = 1:numel(names)
            pn = names{p}; prob = problems{p};
            doneThis = 0;
            for s = 1:30
                fn = fullfile('results\new_algo', sprintf('%s_%s_s%d.mat', an, pn, s));
                if isfile(fn), doneThis = doneThis + 1; nSkip = nSkip + 1; continue; end
                try
                    alg = feval(an, 100, 200, s);
                    [Pop, Res] = alg.optimize(prob);
                    PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
                    out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                    out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1; doneThis = doneThis + 1;
                catch err
                    nFail = nFail + 1;
                    fprintf('FAIL %s %s s%d: %s\n', an, pn, s, err.message);
                end
            end
            fprintf('%s %s: done=%d skip=%d (total done=%d fail=%d elapsed=%.0fs)\n', an, pn, doneThis, doneThis, nDone, nFail, toc(t0));
        end
    end
    fprintf('=== hcev4_ext 完成: 新增 %d, 跳过 %d, 失败 %d, 总耗时 %.1fs ===\n', nDone, nSkip, nFail, toc(t0));
end
