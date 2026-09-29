function backfill_baselines_ext()
    % 80 扩展 M>=3 问题 x 8 基线 x 30 种子补齐（小步慢跑：每问题x30种子保存一次，断点续跑）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    [problems, names] = extProbs();
    algs8 = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    outdir = 'results\baselines_ext'; if ~isdir(outdir), mkdir(outdir); end
    nDone = 0; nSkip = 0; nFail = 0; t0 = tic;
    for a = 1:numel(algs8)
        an = algs8{a};
        for p = 1:numel(names)
            pn = names{p};
            prob = problems{p};
            PF = prob.ParetoFront(500);
            ref = prob.setRefPoint(PF).refPoint;
            doneThis = 0; skipThis = 0;
            for s = 1:30
                fn = fullfile(outdir, sprintf('%s_%s_s%d.mat', an, pn, s));
                if isfile(fn); skipThis = skipThis + 1; continue; end
                try
                    alg = feval(an, 100, 200, s);
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD = IGD(Res.F, PF);
                    out.HV  = HV(Res.F, ref);
                    out.nFE = Res.nFE;
                    out.elap = Res.elap;
                    out.PPS  = size(Res.F, 1);
                    save(fn, 'out', '-v7.3');
                    doneThis = doneThis + 1; nDone = nDone + 1;
                catch err
                    nFail = nFail + 1;
                    fprintf('FAIL %s %s s%d: %s\n', an, pn, s, err.message);
                end
            end
            nSkip = nSkip + skipThis;
            fprintf('%s %s: done+%d skip+%d (累计 done=%d, elapsed=%.0fs)\n', an, pn, doneThis, skipThis, nDone, toc(t0));
        end
    end
    fprintf('=== 完成: 新增 %d, 跳过 %d, 失败 %d, 总耗时 %.1fs ===\n', nDone, nSkip, nFail, toc(t0));
end