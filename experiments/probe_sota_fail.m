function probe_sota_fail()
% 诊断 FDSEA/MOEA-IB 在 CF/MW 上的间歇性 FAIL（"在内存中计算，数据大小超出范围"）
% 定位：是构造、Solve 还是 NDSort/IGD/HV 提取阶段
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('algorithms\_platemo_official');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear classes; clear IGD HV;

    N = 100; G = 200; maxFE = N*(G+1);

    cases = {
        'FDSEA',    'algorithms\FDSEA',                  'CF8',   5;
        'FDSEA',    'algorithms\FDSEA',                  'MW7',   1;
        'MOEA-IB',  'algorithms\MOEA_IB',                'CF8',   1;
        'MOEA-IB',  'algorithms\MOEA_IB',                'MW7',   1;
        'GDVTSF',   'algorithms\GDVTSF',                 'CF8',   5
    };
    for c = 1:size(cases,1)
        alg = cases{c,1}; ep = cases{c,2}; pn = cases{c,3}; s = cases{c,4};
        fprintf('\n=== %s %s s%d ===\n', alg, pn, s);
        % 官方 SOTA 算法类名
        clsMap = {'FDSEA','GDVTSF','MOEA_IB'};
        dirMap = {'algorithms\FDSEA','algorithms\GDVTSF','algorithms\MOEA_IB\WOF','algorithms\MOEA_IB\ReMO','algorithms\MOEA_IB'};
        if strcmp(alg,'FDSEA'),  cls='FDSEA';  epAll={'algorithms\FDSEA'}; end
        if strcmp(alg,'GDVTSF'), cls='GDVTSF'; epAll={'algorithms\GDVTSF'}; end
        if strcmp(alg,'MOEA-IB'),cls='MOEA_IB';epAll={'algorithms\MOEA_IB\WOF','algorithms\MOEA_IB\ReMO','algorithms\MOEA_IB'}; end
        for k=1:numel(epAll), addpath(epAll{k}); end
        try
            rng(s);
            offProb = feval(pn); offProb.Setting();
            offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
            t0=tic;
            algObj = feval(cls, 'save', -1, 'outputFcn', @noopOutput);
            algObj.Solve(offProb);
            fprintf('  Solve OK elap=%.1fs FE=%d\n', toc(t0), offProb.FE);
            F = algObj.result{end,2}.objs;
            [fn,~] = NDSort(F, zeros(size(F,1),0), 1);
            nd = find(fn==1); if isempty(nd), nd=1:size(F,1); end
            fprintf('  提取 OK PPS=%d (NDSort/IGD 阶段正常)\n', numel(nd));
        catch err
            fprintf('  FAIL: %s\n', err.message);
            for i=1:min(3,numel(err.stack))
                fprintf('    @ %s (line %d)\n', err.stack{i}.name, err.stack{i}.line);
            end
        end
        for k=1:numel(epAll), rmpath(epAll{k}); end
    end
end
function noopOutput(a,p)
end
