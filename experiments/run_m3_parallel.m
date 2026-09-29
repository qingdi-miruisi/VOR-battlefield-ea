function run_m3_parallel(algIdx, probIdx, nSeeds, outFile)
% RUN_M3_PARALLEL - 单进程版（供多 MATLAB 进程并行跑 8 基线×35 问题）
% 用法：
%   matlab -batch "cd(root); addpath('experiments'); run_m3_parallel(1,1,30,'results/main/_p1.mat')"
% 本进程负责 algs{algIdx} × probs{probIdx}（单问题 × 30 种子）；结果另存 outFile（默认 results/main/_parallel/）
% 完成时由主控把 outFile 内各 seed 的 out 拆成 <ALGO>_<PROB>_s<N>.mat 落到 results/main/。
%
% 任务参数（本进程跑一个 算法×问题 单元 = 30 种子）：
%   algIdx  : 1..8（对应 algs）
%   probIdx : 1..35（对应 probs）
%   nSeeds  : 1..30

    if nargin < 1, algIdx = 1; end
    if nargin < 2, probIdx = 1; end
    if nargin < 3, nSeeds = 30; end
    if nargin < 4, outFile = ''; end

    projectRoot = fileparts(mfilename('fullpath'));
    root = fileparts(projectRoot);
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

    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    aname = algs{algIdx};
    probs = {'MaF1','MaF2','MaF3','MaF4','MaF5','MaF6','MaF7','MaF8','MaF9', ...
             'MaF10','MaF11','MaF12','MaF13','MaF14','MaF15', ...
             'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9', ...
             'EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
    pname = probs{probIdx};
    nSeeds = min(nSeeds, 30);
    popSize = 100;
    maxGen  = 200;
    seeds   = 1:nSeeds;

    resDir = fullfile(root, 'results', 'main');
    if ~exist(resDir, 'dir'), mkdir(resDir); end
    parDir = fullfile(root, 'results', 'main', '_parallel');
    if ~exist(parDir, 'dir'), mkdir(parDir); end
    if isempty(outFile), outFile = fullfile(parDir, sprintf('%s_%s.mat', aname, pname)); end

    prob = OfficialProblem(pname, 3, 0);
    PF   = prob.ParetoFront(500);
    ref  = prob.setRefPoint(PF).refPoint;

    t0 = tic;
    nDone = 0; nSkip = 0; nFail = 0;
    cellOut = cell(1, nSeeds);
    for s = 1:numel(seeds)
        seed = seeds(s);
        fn = fullfile(resDir, sprintf('%s_%s_s%d.mat', aname, pname, seed));
        if isfile(fn)
            L = load(fn);
            % 已存在文件（可能由其他进程/串行 run 写入）：直接复用其 out
            if isfield(L, 'out')
                cellOut{s}.out = L.out;
            end
            nSkip = nSkip + 1;
            continue;
        end
        try
            alg = feval(aname, popSize, maxGen, seed);
            [Pop, Res] = alg.optimize(prob);
            cellOut{s}.out.IGD  = IGD(Res.F, PF);
            cellOut{s}.out.HV   = HV(Res.F, ref);
            cellOut{s}.out.nFE  = Res.nFE;
            cellOut{s}.out.elap = Res.elap;
            cellOut{s}.out.PPS  = size(Res.F, 1);
            % 每种子立刻原生 save（用户要求"每跑完一个问题立刻 save"）
            save(fn, 'out', '-v7.3');
            nDone = nDone + 1;
        catch ME
            cellOut{s}.err = ME.message;
            nFail = nFail + 1;
            fprintf('  FAIL %s %s s%d: %s\n', aname, pname, seed, ME.message);
        end
        fprintf('  [%d/%d] %s/%s s%d  done=%d skip=%d fail=%d  %.0fs\n', ...
            s, numel(seeds), aname, pname, seed, nDone, nSkip, nFail, toc(t0));
    end
    % 聚合单元结果（供主控核对/汇总；非原生主结果）
    save(outFile, 'cellOut', 'aname', 'pname', 'PF', 'ref', 'prob', '-v7.3');
    fprintf('run_m3_parallel [%s/%s] done=%d skip=%d fail=%d in %.1f min; agg -> %s\n', ...
        aname, pname, nDone, nSkip, nFail, toc(t0)/60, outFile);
end
