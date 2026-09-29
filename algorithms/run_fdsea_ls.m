function run_fdsea_ls()
% run_fdsea_ls — 在 LSMOP1-9 + DTLZ2_300D_M3 上跑 FDSEA（PlatEMO 官方代码）
% 公平协议：N=100, G=200, maxFE=N*(G+1)=20100, seeds=1:30
% 输出：results/largescale_extended/FDSEA/FDSEA_<prob>_s<seed>.mat
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    % addpath 顺序很关键：官方 utility → 官方 problem → 官方 algorithm → 本项目
    addpath('algorithms\FDSEA');
    addpath('algorithms');
    addpath('problems');
    addpath('problems\wfg_toolbox');
    addpath('problems_official');
    addpath('problems_official\LSMOP');
    addpath('problems_official\EMO');
    addpath('problems_official\UF');
    addpath('problems_official\CF');
    addpath('problems_ext');

    clear classes; clear IGD HV;

    N     = 100;
    G     = 200;
    maxFE = N*(G+1);

    algName = 'FDSEA';
    outDir  = ['results\largescale_extended\' algName];
    if ~isdir(outDir), mkdir(outDir); end

    probNames = cell(0); probObjs = cell(0);
    for i = 1:9
        pn = ['LSMOP' num2str(i)];
        probNames{end+1} = pn;
        probObjs{end+1}  = OfficialProblem(pn, 3, 300);
    end
    probNames{end+1} = 'DTLZ2_300D_M3';
    probObjs{end+1}  = DTLZ2_300D_M3();

    nP = numel(probNames); nDone = 0; nFail = 0; nSkip = 0; t0 = tic;

    for p = 1:nP
        pn   = probNames{p};
        prob = probObjs{p};
        PF   = prob.ParetoFront(500);
        ref  = prob.setRefPoint(PF).refPoint;

        for s = 1:30
            fn = fullfile(outDir, [algName '_' pn '_s' num2str(s) '.mat']);
            if isfile(fn), nSkip = nSkip + 1; continue; end
            try
                rng(s);
                [Pop, Res] = runPlatEMOAlgo(algName, prob, N, G, maxFE, s);
                out.IGD  = IGD(Res.F, PF);
                out.HV   = HV(Res.F, ref);
                out.nFE  = Res.nFE;
                out.elap = Res.elap;
                out.PPS  = size(Res.F, 1);
                save(fn, 'out', '-v7.3');
                nDone = nDone + 1;
                fprintf('  FDSEA %s s%d: IGD=%.4g HV=%.4g PPS=%d\n', pn, s, out.IGD, out.HV, out.PPS);
            catch err
                nFail = nFail + 1;
                fprintf('FAIL FDSEA %s s%d: %s\n', pn, s, err.message);
            end
        end
        fprintf('=== FDSEA %s: done=%d skip=%d fail=%d  elapsed=%.0fs ===\n', ...
            pn, nDone, nSkip, nFail, toc(t0));
    end
    fprintf('>>> FDSEA 全部 10 题: done=%d skip=%d fail=%d 总耗时 %.1f min <<<\n', ...
        nDone, nSkip, nFail, toc(t0)/60);
end

% ----------------------------------------------------------------
function [Population, Result] = runPlatEMOAlgo(algName, problem, N, G, maxFE, seed)
% 官方 PlatEMO 算法包装器：把 classdef ALGORITHM 接口适配到 struct 结果
    rng(seed);

    alg = feval(algName);

    % 取官方问题对象
    if isa(problem, 'OfficialProblem')
        offProb = problem.officialObj;
    else
        offProb = problem;
    end
    offProb.N      = N;
    offProb.maxFE  = maxFE;
    offProb.FE     = 0;

    % 官方 main 内部用 while NotTerminated，靠 FE 终止
    alg.main(offProb);

    % 取最终种群
    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F      = PopSOL.objs;
        decs   = PopSOL.decs;
        cons   = PopSOL.cons;
    else
        F = offProb.objs; decs = offProb.decs; cons = offProb.cons;
    end

    % 非支配前沿
    [fn, ~] = NDSort(F, zeros(size(F,1), 0), 1);
    nd = find(fn == 1);
    if isempty(nd), nd = 1:size(F,1); end

    Result.F    = F(nd, :);
    Result.nFE  = offProb.FE;
    Result.elap = alg.metric.runtime;

    Population.decs = decs(nd, :);
    Population.objs = F(nd, :);
    Population.cons = cons(nd, :);
end
