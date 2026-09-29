function run_cf_mw_edd()
% 任务1：EDD v12 在 CF1-10 + MW1-14 × 30 种子（N=100 G=200 maxFE=20100）
% 数据落盘：results/cf_edd/<PN>_EDD_s<k>.mat（key: out=struct(IGD,HV,nFE,elap,PPS)）
% 每题完成报 IGD/HV 中位。约束走 OfficialProblem.CalCon 桥接（Evaluation→SOLUTION.cons）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF2'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    % 24 题：CF1-10（M=2/3, D=10）+ MW1-14（M=2, D=15）
    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = 1:14, probs{end+1} = ['MW' num2str(i)]; end
    nP = numel(probs);
    outDir = 'results\cf_edd';
    if ~isdir(outDir), mkdir(outDir); end
    N = 100; G = 200;

    for p = 1:nP
        pn = probs{p};
        wrap = OfficialProblem(pn, 2, 10);   % M/D 默认由官方类 Setting() 填，此处占位
        D = wrap.D; M = wrap.M;
        PF = wrap.ParetoFront(500);
        ref = wrap.setRefPoint(PF).refPoint;
        nCon = 0;
        % 验证约束桥接：CalCon 应返回非空（CF/MW 有约束）
        X0 = wrap.lower + rand(1, D) .* (wrap.upper - wrap.lower);
        c0 = wrap.CalCon(X0);
        if ~isempty(c0), nCon = size(c0,2); end
        igdMed = NaN; hvMed = NaN;
        for s = 1:30
            fn = fullfile(outDir, [pn '_EDD_s' num2str(s) '.mat']);
            if isfile(fn), continue; end
            rng(s);
            alg = EDD(N, G, s);
            [Pop, Res] = alg.run(wrap);
            [fnr, ~] = NDSort(Pop.objs, Pop.cons, 1);
            nd = find(fnr==1); if isempty(nd), nd = 1:size(Pop.objs,1); end
            F = Pop.objs(nd,:);
            out.IGD = IGD(F, PF); out.HV = HV(F, ref);
            out.nFE = Res.nFE; out.elap = Res.elap; out.PPS = numel(nd);
            save(fn, 'out', '-v7.3');
        end
        % 每题完成：读全部 30 种子算中位
        igdArr = nan(1,30); hvArr = nan(1,30);
        for s = 1:30
            L = load(fullfile(outDir, [pn '_EDD_s' num2str(s) '.mat']));
            igdArr(s) = L.out.IGD; hvArr(s) = L.out.HV;
        end
        igdMed = median(igdArr(~isnan(igdArr)));
        hvMed = median(hvArr(~isnan(hvArr)));
        fprintf('%s  (M=%d D=%d nCon=%d) 30种子中位 IGD=%.4g HV=%.4g\n', pn, M, D, nCon, igdMed, hvMed);
    end
    fprintf('=== EDD CF/MW 30种子全部完成 ===\n');
end
