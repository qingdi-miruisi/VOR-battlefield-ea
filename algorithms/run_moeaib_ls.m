function run_moeaib_ls()
% run_moeaib_ls — 在 LSMOP1-9 + DTLZ2_300D_M3 上跑 MOEA-IB（PlatEMO 官方代码）
% 注：PlatEMO 中类名为 MOEAIB（无连字符）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    addpath('algorithms\MOEA_IB\WOF');
    addpath('algorithms\MOEA_IB\ReMO');
    addpath('algorithms\MOEA_IB');
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

    algName = 'MOEAIB';   % PlatEMO 类名无连字符
    outDir  = ['results\largescale_extended\MOEA-IB'];
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
            fn = fullfile(outDir, ['MOEA-IB_' pn '_s' num2str(s) '.mat']);
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
                fprintf('  MOEA-IB %s s%d: IGD=%.4g HV=%.4g PPS=%d\n', pn, s, out.IGD, out.HV, out.PPS);
            catch err
                nFail = nFail + 1;
                fprintf('FAIL MOEA-IB %s s%d: %s\n', pn, s, err.message);
            end
        end
        fprintf('=== MOEA-IB %s: done=%d skip=%d fail=%d  elapsed=%.0fs ===\n', ...
            pn, nDone, nSkip, nFail, toc(t0));
    end
    fprintf('>>> MOEA-IB 全部 10 题: done=%d skip=%d fail=%d 总耗时 %.1f min <<<\n', ...
        nDone, nSkip, nFail, toc(t0)/60);
end

function [Population, Result] = runPlatEMOAlgo(algName, problem, N, G, maxFE, seed)
    rng(seed);
    alg = feval(algName);
    if isa(problem, 'OfficialProblem')
        offProb = problem.officialObj;
    else
        offProb = problem;
    end
    offProb.N      = N;
    offProb.maxFE  = maxFE;
    offProb.FE     = 0;
    alg.main(offProb);
    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F      = PopSOL.objs; decs = PopSOL.decs; cons = PopSOL.cons;
    else
        F = offProb.objs; decs = offProb.decs; cons = offProb.cons;
    end
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
