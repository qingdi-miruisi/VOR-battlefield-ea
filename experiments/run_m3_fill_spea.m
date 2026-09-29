% run_m3_fill_spea.m - 独立脚本：补 SPEA2 剩余 35 问题 × 30 种子（断点续跑）
% 用法（独立 MATLAB 进程）：
%   matlab -batch "cd('D:\harness工作\中国科学：数学(总)\算法\algorithm'); run('experiments\run_m3_fill_spea.m');"
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms'); addpath('algorithms\utils');
addpath('problems_official'); addpath('problems_official\UF');
addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\ZXH_CF');
addpath('problems_official\EMO');

resDir = 'results\main';
probs = {'MaF1','MaF2','MaF3','MaF4','MaF5','MaF6','MaF7','MaF8','MaF9', ...
         'MaF10','MaF11','MaF12','MaF13','MaF14','MaF15', ...
         'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9', ...
         'EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
algs = {'SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
popSize = 100; maxGen = 200; seeds = 1:30;

tAll = tic; nDone = 0; nSkip = 0; nFail = 0;
for ai = 1:numel(algs)
    aname = algs{ai};
    fprintf('===== %s =====\n', aname);
    for pi = 1:numel(probs)
        pname = probs{pi};
        prob = OfficialProblem(pname, 3, 0);
        PF   = prob.ParetoFront(500);
        ref  = prob.setRefPoint(PF).refPoint;
        for si = 1:numel(seeds)
            seed = seeds(si);
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
            fprintf('  [%d/%d] %s/%s s%d done=%d skip=%d fail=%d %.0fs\n', ...
                si, numel(seeds), aname, pname, seed, nDone, nSkip, nFail, toc(tAll));
        end
    end
end
fprintf('run_m3_fill_spea finished: done=%d skip=%d fail=%d in %.1f min\n', ...
    nDone, nSkip, nFail, toc(tAll)/60);
