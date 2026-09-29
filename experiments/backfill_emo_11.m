function backfill_emo_11()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO'); addpath('problems_official\UF');
    clear classes; clear IGD HV; clear HCEA HCEAV4;
    emos = {'EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
    algos = {'HCEA','HCEAV4'};
    outdirH = 'results\main'; outdirV4 = 'results\merged_v4';
    nDone = 0; nSkip = 0; nFail = 0; t0 = tic;
    for a = 1:numel(algos)
        an = algos{a};
        outdir = outdirH; if strcmp(an,'HCEAV4'), outdir = outdirV4; end
        for p = 1:numel(emos)
            pn = emos{p};
            prob = OfficialProblem(pn);
            PF = prob.ParetoFront(500);
            ref = prob.setRefPoint(PF).refPoint;
            for s = 1:30
                fn = fullfile(outdir, sprintf('%s_%s_s%d.mat', an, pn, s));
                if isfile(fn); nSkip = nSkip + 1; continue; end
                try
                    alg = feval(an, 100, 200, s);
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD = IGD(Res.F, PF);
                    out.HV = HV(Res.F, ref);
                    out.nFE = Res.nFE;
                    out.elap = Res.elap;
                    out.PPS = size(Res.F, 1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1;
                catch err
                    nFail = nFail + 1;
                    fprintf('FAIL %s %s s%d: %s\n', an, pn, s, err.message);
                end
            end
            fprintf('%s %s: done=%d skip=%d fail=%d (elapsed=%.0fs)\n', an, pn, nDone, nSkip, nFail, toc(t0));
        end
    end
    fprintf('=== EMO 补齐完成: done=%d skip=%d fail=%d, 总耗时 %.1fs ===\n', nDone, nSkip, nFail, toc(t0));
end