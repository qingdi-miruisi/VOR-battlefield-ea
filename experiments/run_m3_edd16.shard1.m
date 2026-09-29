function run_m3_edd16()
    % EDD16 M>=3 分片 1：题 1-25（MaF7-15, LSMOP1-9, EMO1-7）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils');
    addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir('results\m3_focus\EDD16'), mkdir('results\m3_focus\EDD16'); end
    [problems, names] = extProbs();
    excl = {'UF8_M3','UF9_M3','UF10_M3'};
    idx = ~cellfun(@(x) any(strcmp(x, excl)), names);
    m3names = names(idx); m3problems = problems(idx);
    nDone = 0; nFail = 0; t0 = tic;
    for p = 1:25
        pn = m3names{p}; prob = m3problems{p};
        PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
        doneThis = 0;
        for s = 1:30
            fn = fullfile('results\m3_focus\EDD16', sprintf('EDD16_%s_s%d.mat', pn, s));
            if isfile(fn), doneThis = doneThis + 1; continue; end
            try
                alg = EDD16(100, 200, s); [Pop, Res] = alg.optimize(prob);
                out.IGD = IGD(Res.F, PF);
                out.HV = HV(Res.F, ref);
                out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                save(fn, 'out', '-v7.3');
                nDone = nDone + 1; doneThis = doneThis + 1;
            catch err
                nFail = nFail + 1;
                fprintf('FAIL EDD16 %s s%d: %s\n', pn, s, err.message);
            end
        end
        fprintf('EDD16 %s: done=%d skip=%d (total done=%d fail=%d elapsed=%.0fs)\n', pn, doneThis, doneThis, nDone, nFail, toc(t0));
    end
    fprintf('=== EDD16 分片1(1-25) 完成: 新增 %d, 失败 %d, 总耗时 %.1fs ===\n', nDone, nFail, toc(t0));
end
