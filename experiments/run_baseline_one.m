function run_baseline_one(anName)
    % 单个基线补齐 80 扩展集 → results/baselines_ext（断点续跑，按基线并行）
    % 注意：某算法内部无参 clear 会清掉局部变量，用 persistent 保存算法名/问题表（persistent 不被 clear 清除）
    persistent anCell probTable nameCell;
    if isempty(anCell)
        anCell = {anName};
        cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
        addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
        addpath('problems\wfg_toolbox');
        addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
        addpath('problems_official\UF'); addpath('problems_official\CF');
        addpath('problems_ext');
        clear classes; clear IGD HV;
        if ~isdir('results\baselines_ext'), mkdir('results\baselines_ext'); end
        [probTable, nameCell] = extProbs();
    end
    an = anCell{1};
    nDone = 0; nSkip = 0; nFail = 0; t0 = tic;
    for p = 1:numel(nameCell)
        pn = nameCell{p}; prob = probTable{p};
        doneThis = 0;
        for s = 1:30
            an = anCell{1};   % 每轮从 persistent 取（persistent 不被 clear 清除）
            fn = fullfile('results\baselines_ext', sprintf('%s_%s_s%d.mat', an, pn, s));
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
    fprintf('=== %s 完成: 新增 %d, 跳过 %d, 失败 %d, 总耗时 %.1fs ===\n', an, nDone, nSkip, nFail, toc(t0));
end
