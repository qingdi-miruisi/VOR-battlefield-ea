function run_v4(startP, endP, nSeeds)
% RUN_V4 - 跑 HCEAV4 全量主实验（33 问题 × 30 种子）
% 增量落盘，支持断点续跑。结果写入 results/main_v4/（与 results/main 独立）。
    if nargin < 1, startP = 1; end
    if nargin < 2, endP = 33; end
    if nargin < 3, nSeeds = 30; end

    projectRoot = fileparts(mfilename('fullpath'));
    root = fileparts(projectRoot);
    cd(root);
    addpath(fullfile(root, 'problems'));
    addpath(fullfile(root, 'problems', 'wfg_toolbox'));
    addpath(fullfile(root, 'algorithms'));
    addpath(fullfile(root, 'algorithms', 'utils'));
    % 官方原版问题（PROBLEM 基类 + UF/MaF/LSMOP/CF 官方源码，零公式改动）
    addpath(fullfile(root, 'problems_official'));
    addpath(fullfile(root, 'problems_official', 'UF'));
    addpath(fullfile(root, 'problems_official', 'MaF'));
    addpath(fullfile(root, 'problems_official', 'LSMOP'));
    addpath(fullfile(root, 'problems_official', 'CF'));
    addpath(fullfile(root, 'problems_official', 'ZXH_CF'));

    resDir = fullfile(root, 'results', 'main_v4');
    if ~exist(resDir, 'dir'), mkdir(resDir); end

    % 扩展测试集（官方原版 MaF/LSMOP 全量）：33 → 57 问题
    problems = { ...
        'ZDT1',0; 'ZDT2',0; 'ZDT3',0; 'ZDT4',0; 'ZDT5',0; 'ZDT6',0; ...
        'DTLZ1',0; 'DTLZ2',3; 'DTLZ3',3; 'DTLZ4',0; 'DTLZ5',0; 'DTLZ7',0; ...
        'WFG1',0; 'WFG2',0; 'WFG3',0; 'WFG4',0; 'WFG5',0; 'WFG6',0; 'WFG7',0; 'WFG8',0; 'WFG9',0; ...
        'UF1',0; 'UF2',0; 'UF5',0; 'UF6',0; ...
        'CMO1',0; 'CMO5',0; ...
        'MaF1',3; 'MaF2',3; 'MaF3',3; 'MaF4',3; 'MaF5',3; 'MaF7',3; 'MaF8',3; 'MaF9',3; 'MaF10',3; 'MaF11',3; 'MaF12',3; 'MaF13',3; 'MaF14',3; 'MaF15',3; ...
        'LSMOP1',3; 'LSMOP2',3; 'LSMOP3',3; 'LSMOP4',3; 'LSMOP5',3; 'LSMOP6',3; 'LSMOP7',3; 'LSMOP8',3; 'LSMOP9',3};
    nProbs = size(problems, 1);
    startP = max(1, min(nProbs, startP));
    endP   = max(startP, min(nProbs, endP));
    nSeeds = min(nSeeds, 30);
    popSize = 100; maxGen = 200;
    seeds   = 1:nSeeds;

    tAll = tic;
    nDone = 0; nSkip = 0; nFail = 0;
    for p = startP : endP
        pname = problems{p,1};
        pM    = problems{p,2};
        % 官方原版 UF/MaF/LSMOP/CF 经 OfficialProblem 适配器（零公式改动）
        isOfficial = (startsWith(pname,'UF') || startsWith(pname,'MaF') ...
                      || startsWith(pname,'LSMOP') || startsWith(pname,'CF'));
        if isOfficial
            prob = OfficialProblem(pname, pM, 30);
        else
            if pM > 2
                prob = feval(pname, pM);
            else
                prob = feval(pname);
            end
        end
        PF  = prob.ParetoFront(500);
        ref = prob.setRefPoint(PF).refPoint;
        for s = 1:numel(seeds)
            seed = seeds(s);
            fn = fullfile(resDir, sprintf('HCEAV4_%s_s%d.mat', pname, seed));
            if isfile(fn)
                nSkip = nSkip + 1;
                continue;
            end
            try
                alg = HCEAV4(popSize, maxGen, seed);
                [Pop, Res] = alg.optimize(prob);
                out.IGD = IGD(Res.F, PF);
                out.HV  = HV(Res.F, ref);
                out.nFE = Res.nFE;
                out.elap = Res.elap;
                out.PPS = size(Res.F, 1);
                save(fn, 'out', '-v7.3');
                nDone = nDone + 1;
            catch ME
                nFail = nFail + 1;
                fprintf('  FAIL HCEAV4 %s s%d: %s\n', pname, seed, ME.message);
            end
            fprintf('  [%d/%d] HCEAV4/%s s%d  done=%d skip=%d fail=%d  %.0fs\n', ...
                p, nProbs, pname, seed, nDone, nSkip, nFail, toc(tAll));
        end
    end
    fprintf('run_v4 finished: done=%d skip=%d fail=%d in %.1f min\n', ...
        nDone, nSkip, nFail, toc(tAll)/60);
end
