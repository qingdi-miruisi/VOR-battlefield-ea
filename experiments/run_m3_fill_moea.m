% run_m3_fill_moea - 补 3 个慢算法（AGEMOEA/SMSEMOA/MOEAD）在 35 个 M=3 问题上的数据
% 设计：只补【缺失 seed】（isfile 跳过已有）；顺序 3 算法 × 35 问题 × 30 seed，每 seed 立刻原生 save。
% 预计时长：AGEMOEA ~3h + SMSEMOA ~7h + MOEAD ~1h ≈ 11h（MOGWO/RVEA/SPEA2/NSGA 已完成或快完成，不在此列）。
% 用法（独立进程）：
%   matlab -batch "cd(root); addpath('experiments'); run_m3_fill_moea"
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
run_m3_fill_moea();

function run_m3_fill_moea()
    root = pwd;
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

    algs = {'AGEMOEA','SMSEMOA','MOEAD'};
    probs = {'MaF1','MaF2','MaF3','MaF4','MaF5','MaF6','MaF7','MaF8','MaF9', ...
             'MaF10','MaF11','MaF12','MaF13','MaF14','MaF15', ...
             'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9', ...
             'EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
    popSize = 100;
    maxGen  = 200;
    seeds   = 1:30;

    tAll = tic;
    nDone = 0; nSkip = 0; nFail = 0;
    for a = 1:numel(algs)
        aname = algs{a};
        fprintf('===== %s start =====\n', aname);
        for p = 1:numel(probs)
            pname = probs{p};
            prob = OfficialProblem(pname, 3, 0);
            PF   = prob.ParetoFront(500);
            ref  = prob.setRefPoint(PF).refPoint;
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
                fprintf('  [%d] %s/%s s%d  done=%d skip=%d fail=%d  %.0fs\n', ...
                    s, aname, pname, seed, nDone, nSkip, nFail, toc(tAll));
            end
        end
        fprintf('===== %s done =====\n', aname);
    end
    fprintf('run_m3_fill_moea finished: done=%d skip=%d fail=%d in %.1f min\n', ...
        nDone, nSkip, nFail, toc(tAll)/60);
end
