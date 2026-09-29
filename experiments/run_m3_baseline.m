function run_m3_baseline(startAlg, endAlg, startProb, endProb, nSeeds)
% RUN_M3_BASELINE - 8 基线 × 35 M=3 官方问题（MaF1-15, LSMOP1-9, EMO1-11）× 30 种子
% 增量落盘，支持断点续跑：跳过 results/main/ 下已有 <ALGO>_<PROB>_s<seed>.mat。
% 问题：OfficialProblem(pname, 3, 0)（D=0 表示官方默认 D；MaF 官方 D=M+9=12，
%       LSMOP 官方 D=100*M=300，EMO 官方 D=M=3）
% 指标：IGD（vs PF=prob.ParetoFront(500)），HV（ref = prob.setRefPoint(PF).refPoint）
% 落盘：results/main/<ALGO>_<PROB>_s<seed>.mat，out = struct('IGD','HV','nFE','elap','PPS')
%
% 用法：
%   cd(root); addpath('experiments');
%   run_m3_baseline(1, 8, 1, 35)        % 全量
%   run_m3_baseline(1, 1, 1, 3)         % 试跑 NSGA2 前 3 个问题
%
% 断点续跑：重跑同一调用即可，已存在文件自动跳过。

    if nargin < 1, startAlg = 1; end
    if nargin < 2, endAlg = 8; end
    if nargin < 3, startProb = 1; end
    if nargin < 4, endProb = 35; end
    if nargin < 5, nSeeds = 30; end

    projectRoot = fileparts(mfilename('fullpath'));   % experiments/
    root = fileparts(projectRoot);                    % algorithm/
    cd(root);
    addpath(fullfile(root, 'problems'));
    addpath(fullfile(root, 'problems', 'wfg_toolbox'));
    addpath(fullfile(root, 'algorithms'));
    addpath(fullfile(root, 'algorithms', 'utils'));
    addpath(fullfile(root, 'problems_official'));
    addpath(fullfile(root, 'problems_official', 'UF'));
    addpath(fullfile(root, 'problems_official', 'MaF'));
    addpath(fullfile(root, 'problems_official', 'LSMOP'));
    addpath(fullfile(root, 'problems_official', 'CF'));
    addpath(fullfile(root, 'problems_official', 'ZXH_CF'));
    addpath(fullfile(root, 'problems_official', 'EMO'));

    resDir = fullfile(root, 'results', 'main');
    if ~exist(resDir, 'dir'), mkdir(resDir); end

    %--- 8 基线（用户指定顺序）+ 35 M=3 问题（MaF1-15, LSMOP1-9, EMO1-11）---
    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    probs = {'MaF1','MaF2','MaF3','MaF4','MaF5','MaF6','MaF7','MaF8','MaF9', ...
             'MaF10','MaF11','MaF12','MaF13','MaF14','MaF15', ...
             'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9', ...
             'EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
    nAlgs = numel(algs); nProbs = numel(probs);
    startAlg = max(1, min(nAlgs, startAlg));
    endAlg   = max(startAlg, min(nAlgs, endAlg));
    startProb = max(1, min(nProbs, startProb));
    endProb   = max(startProb, min(nProbs, endProb));
    nSeeds = min(nSeeds, 30);

    popSize = 100;
    maxGen  = 200;
    seeds   = 1:nSeeds;

    tAll = tic;
    nDone = 0; nSkip = 0; nFail = 0;

    for a = startAlg : endAlg
        aname = algs{a};
        for p = startProb : endProb
            pname = probs{p};
            % D=0 → OfficialProblem 内部官方默认 D（MaF: M+9, LSMOP: 100M, EMO: M）
            prob = OfficialProblem(pname, 3, 0);
            PF   = prob.ParetoFront(500);
            ref  = prob.setRefPoint(PF).refPoint;
            fprintf('--- %s / %s (M=3, D=%d) ---\n', aname, pname, prob.D);
            for s = 1:numel(seeds)
                seed = seeds(s);
                fn = fullfile(resDir, sprintf('%s_%s_s%d.mat', aname, pname, seed));
                if isfile(fn)
                    nSkip = nSkip + 1;
                    continue;
                end
                try
                    alg = feval(aname, popSize, maxGen, seed);
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD  = IGD(Res.F, PF);
                    out.HV   = HV(Res.F, ref);
                    out.nFE  = Res.nFE;
                    out.elap = Res.elap;
                    out.PPS  = size(Res.F, 1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1;
                catch ME
                    nFail = nFail + 1;
                    fprintf('  FAIL %s %s s%d: %s\n', aname, pname, seed, ME.message);
                end
                fprintf('  [%d/%d] %s/%s s%d  done=%d skip=%d fail=%d  %.0fs\n', ...
                    p, endProb-startProb+1, aname, pname, seed, nDone, nSkip, nFail, toc(tAll));
            end
        end
    end

    fprintf('run_m3_baseline finished: done=%d skip=%d fail=%d in %.1f min\n', ...
        nDone, nSkip, nFail, toc(tAll)/60);
end
