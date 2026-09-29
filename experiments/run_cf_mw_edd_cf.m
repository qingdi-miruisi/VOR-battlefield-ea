function run_cf_mw_edd_cf()
% 任务2：EDD_cf（门控放宽版）在 CF1-10 + MW1-14 × 30 种子
% N=100 G=200 maxFE≈20215 种子1:30 → results/cf_edd_cf/<PN>_EDD_cf_s<k>.mat
% 每跑完一题报 IGD/HV 中位；断点续跑（已存 .mat 跳过）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = 1:14, probs{end+1} = ['MW' num2str(i)]; end
    nP = numel(probs);
    outDir = 'results\cf_edd_cf';
    if ~isdir(outDir), mkdir(outDir); end
    N = 100; G = 200;
    totT0 = tic;
    for p = 1:nP
        pn = probs{p};
        wrap = OfficialProblem(pn, 2, 10);
        D = wrap.D; M = wrap.M;
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        igdArr = nan(1,30); hvArr = nan(1,30); ppsArr = nan(1,30);
        t0 = tic;
        for s = 1:30
            fn = fullfile(outDir, [pn '_EDD_cf_s' num2str(s) '.mat']);
            if isfile(fn), L = load(fn); igdArr(s)=L.out.IGD; hvArr(s)=L.out.HV; ppsArr(s)=L.out.PPS; continue; end
            rng(s);
            alg = EDD_cf(N, G, s);
            [Pop, Res] = alg.run(wrap);
            [fn2, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn2==1);
            if isempty(nd), nd = 1:size(Pop.objs,1); end
            F = Pop.objs(nd,:);
            out.IGD = IGD(F, PF); out.HV = HV(F, ref);
            out.nFE = Res.nFE; out.PPS = numel(nd);
            save(fn, 'out', '-v7.3');
            igdArr(s)=out.IGD; hvArr(s)=out.HV; ppsArr(s)=out.PPS;
        end
        igdMed = median(igdArr(~isnan(igdArr))); hvMed = median(hvArr(~isnan(hvArr))); ppsMed = median(ppsArr(~isnan(ppsArr)));
        fprintf('%s  (M=%d D=%d) 30种子中位 IGD=%.4g HV=%.4g PPS=%d  耗时=%.0fs\n', ...
            pn, M, D, igdMed, hvMed, ppsMed, toc(t0));
    end
    fprintf('=== EDD_cf CF/MW 24题×30种子 全部完成，总耗时=%.0f min ===\n', toc(totT0)/60);
end
