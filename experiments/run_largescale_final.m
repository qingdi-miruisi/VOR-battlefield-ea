function run_largescale_final(algName)
    % 10 题全量（LSMOP1-9 D=300 M=3 + DTLZ2_300D_M3），11 算法 × 30 种子
    % 用法：run_largescale_final('EDD') / ('NSGA2') / ('HCEAV4') ...
    % 数据存 results/largescale_final/<algName>/
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils');
    addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;

    if ~isdir(fullfile('results\largescale_final', algName)), mkdir(fullfile('results\largescale_final', algName)); end

    % 10 题定义：9 LSMOP (M=3 D=300) + DTLZ2_300D_M3
    probNames = cell(0); probObjs = cell(0);
    for i = 1:9
        pn = ['LSMOP' num2str(i)];
        probNames{end+1} = pn;
        probObjs{end+1} = OfficialProblem(pn, 3, 300);
    end
    probNames{end+1} = 'DTLZ2_300D_M3';
    probObjs{end+1} = DTLZ2_300D_M3();

    nP = numel(probNames);
    nDone = 0; nFail = 0; nSkip = 0; t0 = tic;

    % 构造算法对象工厂（EDD 用 v12 锁定版，其余用同名类）
    for p = 1:nP
        pn = probNames{p}; prob = probObjs{p};
        PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
        doneThis = 0;
        for s = 1:30
            fn = fullfile('results\largescale_final', algName, ...
                          sprintf('%s_%s_s%d.mat', algName, pn, s));
            if isfile(fn), nSkip = nSkip + 1; continue; end
            try
                alg = makeAlgo(algName, 100, 200, s);
                [Pop, Res] = alg.optimize(prob);
                out.IGD = IGD(Res.F, PF);
                out.HV  = HV(Res.F, ref);
                out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                save(fn, 'out', '-v7.3');
                nDone = nDone + 1; doneThis = doneThis + 1;
            catch err
                nFail = nFail + 1;
                fprintf('FAIL %s %s s%d: %s\n', algName, pn, s, err.message);
            end
        end
        fprintf('%s %s: done=%d skip=%d (total done=%d skip=%d fail=%d elapsed=%.0fs)\n', ...
            algName, pn, doneThis, doneThis, nDone, nSkip, nFail, toc(t0));
    end
    fprintf('=== %s 10 题全量完成: 新增 %d, 跳过 %d, 失败 %d, 总耗时 %.1fs ===\n', ...
        algName, nDone, nSkip, nFail, toc(t0));
end

function alg = makeAlgo(name, N, G, seed)
    switch name
        case 'EDD',   alg = EDD(N, G, seed);
        case 'HCEA',   alg = HCEA(N, G, seed);
        case 'HCEAV4', alg = HCEAV4(N, G, seed);
        case 'NSGA2',  alg = NSGA2(N, G, seed);
        case 'NSGA3',  alg = NSGA3(N, G, seed);
        case 'SPEA2',  alg = SPEA2(N, G, seed);
        case 'AGEMOEA',alg = AGEMOEA(N, G, seed);
        case 'SMSEMOA',alg = SMSEMOA(N, G, seed);
        case 'MOGWO',  alg = MOGWO(N, G, seed);
        case 'RVEA',   alg = RVEA(N, G, seed);
        case 'MOEAD',  alg = MOEAD(N, G, seed);
        otherwise
            error('未知算法 %s', name);
    end
end
