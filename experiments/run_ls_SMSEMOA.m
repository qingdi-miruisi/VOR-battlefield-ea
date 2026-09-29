function run_ls_SMSEMOA()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    algName = 'SMSEMOA';
    if ~isdir('results\largescale_final\SMSEMOA'), mkdir('results\largescale_final\SMSEMOA'); end
    probNames = cell(0); probObjs = cell(0);
    for i = 1:9
        pn = ['LSMOP' num2str(i)];
        probNames{end+1} = pn;
        probObjs{end+1} = OfficialProblem(pn, 3, 300);
    end
    probNames{end+1} = 'DTLZ2_300D_M3';
    probObjs{end+1} = DTLZ2_300D_M3();
    nP = numel(probNames); nDone=0; nFail=0; nSkip=0; t0=tic;
    for p = 1:nP
        pn = probNames{p}; prob = probObjs{p};
        PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
        for s = 1:30
            fn = fullfile('results\largescale_final\SMSEMOA', ['SMSEMOA_' pn '_s' num2str(s) '.mat']);
            if isfile(fn), nSkip = nSkip+1; continue; end
            try
                alg = SMSEMOA(100,200,s); [Pop, Res] = alg.optimize(prob);
                out.IGD = IGD(Res.F,PF); out.HV = HV(Res.F,ref);
                out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = size(Res.F,1);
                save(fn,'out','-v7.3');
                nDone = nDone+1;
            catch err
                nFail = nFail+1;
                fprintf('FAIL SMSEMOA %s s%d: %s\n', pn, s, err.message);
            end
        end
        fprintf('SMSEMOA %s: done=%d skip=%d fail=%d elapsed=%.0fs\n', pn, nDone, nSkip, nFail, toc(t0));
    end
    fprintf('=== SMSEMOA 10 题完成: done=%d skip=%d fail=%d 总耗时 %.1fs ===\n', nDone, nSkip, nFail, toc(t0));
end
