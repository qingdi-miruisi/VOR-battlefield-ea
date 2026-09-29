function run_ls_dtlz2_backfill(algName)
    % 补齐 DTLZ2_300D_M3 单题（30 种子），10 基线共用
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    if ~isdir(fullfile('results\largescale_final', algName)), mkdir(fullfile('results\largescale_final', algName)); end
    prob = DTLZ2_300D_M3();
    PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
    nDone=0; nSkip=0; nFail=0; t0=tic;
    for s = 1:30
        fn = fullfile('results\largescale_final', algName, sprintf('%s_DTLZ2_300D_M3_s%d.mat', algName, s));
        if isfile(fn), nSkip = nSkip+1; continue; end
        try
            alg = makeAlgo(algName, 100, 200, s);
            [Pop, Res] = alg.optimize(prob);
            out.IGD = IGD(Res.F,PF); out.HV = HV(Res.F,ref);
            out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
            save(fn,'out','-v7.3');
            nDone = nDone+1;
        catch err
            nFail = nFail+1;
            fprintf('FAIL %s s%d: %s\n', algName, s, err.message);
        end
    end
    fprintf('%s DTLZ2_300D_M3: done=%d skip=%d fail=%d elapsed=%.0fs\n', algName, nDone, nSkip, nFail, toc(t0));
end

function alg = makeAlgo(name, N, G, seed)
    switch name
        case 'HCEA',   alg = HCEA(N,G,seed);
        case 'HCEAV4', alg = HCEAV4(N,G,seed);
        case 'NSGA2',  alg = NSGA2(N,G,seed);
        case 'NSGA3',  alg = NSGA3(N,G,seed);
        case 'SPEA2',  alg = SPEA2(N,G,seed);
        case 'AGEMOEA',alg = AGEMOEA(N,G,seed);
        case 'SMSEMOA',alg = SMSEMOA(N,G,seed);
        case 'MOGWO',  alg = MOGWO(N,G,seed);
        case 'RVEA',   alg = RVEA(N,G,seed);
        case 'MOEAD',  alg = MOEAD(N,G,seed);
        otherwise error('unknown %s', name);
    end
end
