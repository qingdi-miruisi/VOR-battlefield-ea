function run_main(startP, endP, nSeeds)
% RUN_MAIN - 主实验脚本（增量落盘版）
% 10 算法 × 30 问题 × 30 种子；每完成 1 个 (算法, 问题, 种子) 即写 .mat，
% 支持断点续跑（检查 results/ 下已有文件则跳过）。
% 算法：NSGA2 NSGA3 MOEAD SPEA2 SMSEMOA RVEA AGEMOEA MOGWO HCEA HCEAV2
% 指标：IGD、HV（统一参考点 = 1.1*max(PF)）
% 公平性：所有算法同 popSize=100, maxGen=200，30 个固定种子 1:30。
%
% 用法（MATLAB 命令窗）：
%   cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
%   addpath('experiments');
%   run_main(1, 30)      % 跑全部（默认 30 种子）
%   run_main(1, 5, 10)   % 试跑前 5 个问题、10 个种子

    %--- 默认参数 ---
    if nargin < 1, startP = 1; end
    if nargin < 2, endP = 30; end
    if nargin < 3, nSeeds = 30; end

    %--- 路径设置 ---
    projectRoot = fileparts(mfilename('fullpath'));   % experiments/
    root = fileparts(projectRoot);                    % algorithm/
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

    resDir = fullfile(root, 'results', 'main');
    if ~exist(resDir, 'dir'), mkdir(resDir); end

    %--- 实验矩阵（官方原版 UF/MaF/LSMOP/CF，CMO 手写版） ---
    algs = {'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO','HCEA','HCEAV2'};
    % 问题列表：{名称, M 目标数（0=默认 2）}；UF/MaF/LSMOP/CF 走官方原版
    problems = { ...
        'ZDT1',0; 'ZDT2',0; 'ZDT3',0; 'ZDT4',0; 'ZDT5',0; 'ZDT6',0; ...
        'DTLZ1',0; 'DTLZ2',0; 'DTLZ3',0; 'DTLZ4',0; 'DTLZ5',0; 'DTLZ7',0; ...
        'WFG1',0; 'WFG2',0; 'WFG3',0; 'WFG4',0; 'WFG5',0; 'WFG6',0; 'WFG7',0; 'WFG8',0; 'WFG9',0; ...
        'UF1',0; 'UF2',0; 'UF5',0; 'UF6',0; ...
        'CMO1',0; 'CMO5',0; ...
        'MaF1',3; 'MaF2',3; 'MaF3',3; 'MaF4',3; 'MaF5',3; 'MaF11',3};
    nProbs = size(problems, 1);
    startP = max(1, min(nProbs, startP));
    endP = max(startP, min(nProbs, endP));
    nSeeds = min(nSeeds, 30);

    popSize = 100;
    maxGen  = 200;
    seeds   = 1:nSeeds;

    tAll = tic;
    nDone = 0; nSkip = 0; nFail = 0;

    for p = startP : endP
        pname = problems{p,1};
        pM    = problems{p,2};
        % 官方原版 UF/MaF/LSMOP/CF 经 OfficialProblem 适配器（零公式改动）；
        % 手写版 ZDT/DTLZ/WFG/CMO 直接 feval
        isOfficial = (strcmpi(pname(1:2),'UF') || strcmpi(pname(1:3),'MaF') ...
                      || strncmpi(pname,'LSMOP',5) || strncmpi(pname,'CF',2));
        if isOfficial
            prob = OfficialProblem(pname, pM, 30);
        else
            if pM > 2
                prob = feval(pname, pM);
            else
                prob = feval(pname);
            end
        end
        PF   = prob.ParetoFront(500);
        ref  = prob.setRefPoint(PF).refPoint;

        for a = 1:numel(algs)
            aname = algs{a};
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
                    out.IGD = IGD(Res.F, PF);
                    out.HV  = HV(Res.F, ref);
                    out.nFE = Res.nFE;
                    out.elap = Res.elap;
                    out.PPS = size(Res.F, 1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1;
                catch ME
                    nFail = nFail + 1;
                    fprintf('  FAIL %s %s s%d: %s\n', aname, pname, seed, ME.message);
                end
                fprintf('  [%d/%d] %s/%s s%d  done=%d skip=%d fail=%d  %.0fs\n', ...
                    p, nProbs, aname, pname, seed, nDone, nSkip, nFail, toc(tAll));
            end
        end
    end

    fprintf('run_main finished: done=%d skip=%d fail=%d in %.1f min\n', ...
        nDone, nSkip, nFail, toc(tAll)/60);
end
