function run_sensitivity(nSeeds)
% RUN_SENSITIVITY - HCEAV2 灵敏度分析
% 对 popSize 和 maxGen 做单因素扫描，记录 IGD/HV 均值±std
% 问题：ZDT1, DTLZ2(M=3), WFG2, UF2
% popSize 网格：{50, 100, 200}；maxGen 网格：{50, 100, 200, 400}
% 输出：results/sensitivity/sens_{问题}_{popSize}_{maxGen}.mat

    if nargin < 0, nSeeds = 10; end
    cd(fileparts(fileparts(mfilename('fullpath'))));  % 到 algorithm/
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms'); addpath('algorithms\utils');

    resDir = fullfile(pwd, 'results', 'sensitivity');
    if ~exist(resDir, 'dir'), mkdir(resDir); end

    problems = { ...
        {'ZDT1',0}, {'DTLZ2',3}, {'WFG2',0}, {'UF2',0} };
    popSizes = [50, 100, 200];
    maxGens  = [50, 100, 200, 400];

    t0 = tic;
    for p = 1:numel(problems)
        pname = problems{p}{1};
        pM    = problems{p}{2};
        if pM > 0
            prob = feval(pname, pM);
        else
            prob = feval(pname);
        end
        PF  = prob.ParetoFront(500);
        ref = prob.setRefPoint(PF).refPoint;

        for ps = popSizes
            for mg = maxGens
                for s = 1:nSeeds
                    fn = fullfile(resDir, sprintf('sens_%s_p%d_g%d_s%d.mat', pname, ps, mg, s));
                    if isfile(fn), continue; end
                    alg = HCEAV2(ps, mg, s);
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD  = IGD(Res.F, PF);
                    out.HV   = HV(Res.F, ref);
                    out.nFE  = Res.nFE;
                    out.popSize = ps;
                    out.maxGen  = mg;
                    save(fn, 'out', '-v7.3');
                end
            end
        end
        fprintf('%s done in %.1f min\n', pname, toc(t0)/60);
    end
end
