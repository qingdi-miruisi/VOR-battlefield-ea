function run_ls_batch9()
    % 9 基线 × 10 题全量（LSMOP1-9 + DTLZ2_300D_M3），结果写入 results/largescale_final/<alg>/
    % 已存在的 .mat 直接跳过（isfile-skip resume 友好）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;

    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','MOEAD','HCEA','HCEAV4'};
    probNames = cell(0); probObjs = cell(0);
    for i = 1:9
        pn = ['LSMOP' num2str(i)];
        probNames{end+1} = pn;
        probObjs{end+1} = OfficialProblem(pn, 3, 300);
    end
    probNames{end+1} = 'DTLZ2_300D_M3';
    probObjs{end+1} = DTLZ2_300D_M3();
    nP = numel(probNames);

    for a = 1:numel(algs)
        an = algs{a};
        if ~isdir(fullfile('results\largescale_final', an)), mkdir(fullfile('results\largescale_final', an)); end
        t0 = tic; nTotalDone=0; nTotalFail=0; nTotalSkip=0;
        for p = 1:nP
            pn = probNames{p}; prob = probObjs{p};
            PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
            for s = 1:30
                fn = fullfile('results\largescale_final', an, sprintf('%s_%s_s%d.mat', an, pn, s));
                if isfile(fn), nTotalSkip = nTotalSkip+1; continue; end
                try
                    alg = makeAlgo(an, 100, 200, s);
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                    out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                    save(fn, 'out', '-v7.3');
                    nTotalDone = nTotalDone+1;
                catch err
                    nTotalFail = nTotalFail+1;
                    fprintf('FAIL %s %s s%d: %s\n', an, pn, s, err.message);
                end
            end
            fprintf('%s %s: done=%d skip=%d fail=%d elapsed=%.0fs\n', ...
                an, pn, nTotalDone, nTotalSkip, nTotalFail, toc(t0));
        end
        fprintf('=== %s 10 题完成: done=%d skip=%d fail=%d 总耗时 %.1fs ===\n', ...
            an, nTotalDone, nTotalSkip, nTotalFail, toc(t0));
    end
end

function alg = makeAlgo(name, N, G, seed)
    switch name
        case 'NSGA2',  alg = NSGA2(N,G,seed);
        case 'NSGA3',  alg = NSGA3(N,G,seed);
        case 'SPEA2',  alg = SPEA2(N,G,seed);
        case 'AGEMOEA',alg = AGEMOEA(N,G,seed);
        case 'SMSEMOA',alg = SMSEMOA(N,G,seed);
        case 'MOGWO',  alg = MOGWO(N,G,seed);
        case 'MOEAD',  alg = MOEAD(N,G,seed);
        case 'HCEA',   alg = HCEA(N,G,seed);
        case 'HCEAV4', alg = HCEAV4(N,G,seed);
        otherwise error('unknown %s', name);
    end
end
