function run_edd_v5_lsmop()
% 第四轮：EDDV5（双种群·强化版a）在 LSMOP1-3 上 30 种子（N=100 G=200 maxFE≈20115）
% 对比旧 EDD + FDSEA/GDVTSF/MOEA-IB 新基线，统计对 FDSEA 的胜负比。
% 数据落盘：results/largescale_edd_v5/<PN>_EDDV5_s<k>.mat
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;
    outDir = 'results\largescale_edd_v5';
    if ~isdir(outDir), mkdir(outDir); end

    % ---- EDDV5 30 种子 × 3 题（纯数字循环）----
    for p = 1:3
        pn = ['LSMOP' num2str(p)];
        wrap = OfficialProblem(pn, 3, 300);
        PF   = wrap.ParetoFront(500);
        ref  = wrap.setRefPoint(PF).refPoint;
        for s = 1:30
            fn = fullfile(outDir, [pn '_EDDV5_s' num2str(s) '.mat']);
            if isfile(fn), continue; end
            rng(s);
            alg = EDDV5(100, 200, s, 'full');
            [Pop, Res] = alg.run(wrap);
            [fnr, ~] = NDSort(Pop.objs, Pop.cons, 1);
            nd = find(fnr==1); if isempty(nd), nd = 1:size(Pop.objs,1); end
            F = Pop.objs(nd,:);
            out.IGD = IGD(F, PF); out.HV = HV(F, ref);
            out.nFE = Res.nFE; out.elap = Res.nFE;
            out.PPS = numel(nd);
            save(fn, 'out', '-v7.3');
            fprintf('%s EDDV5 s%-2d IGD=%.4g HV=%.4g nFE=%d PPS=%d\n', pn, s, out.IGD, out.HV, out.nFE, out.PPS);
        end
    end

    % ---- 逐题对比：EDDV5 vs 旧EDD vs FDSEA/GDVTSF/MOEA-IB（30 种子中位 + 胜负）----
    oldDir = 'results\new_algo_v12';           % 旧 EDD: EDD_<PN>_s<k>.mat
    extDir = 'results\largescale_extended';     % 新3: FDSEA/GDVTSF/MOEA-IB
    for p = 1:3
        pn = ['LSMOP' num2str(p)];
        wrap = OfficialProblem(pn, 3, 300);
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        % 读各算法 30 种子 IGD/HV
        igdV = nan(1,30); hvV = nan(1,30);
        igdO = nan(1,30); hvO = nan(1,30);
        igdF = nan(1,30); hvF = nan(1,30);
        igdG = nan(1,30); hvG = nan(1,30);
        igdI = nan(1,30); hvI = nan(1,30);
        for s = 1:30
            L = load(fullfile(outDir, [pn '_EDDV5_s' num2str(s) '.mat']));
            igdV(s)=L.out.IGD; hvV(s)=L.out.HV;
            L = load(fullfile(oldDir, ['EDD_' pn '_s' num2str(s) '.mat']));
            igdO(s)=L.out.IGD; hvO(s)=L.out.HV;
            L = load(fullfile(extDir, 'FDSEA', ['FDSEA_' pn '_s' num2str(s) '.mat']));
            igdF(s)=L.out.IGD; hvF(s)=L.out.HV;
            L = load(fullfile(extDir, 'GDVTSF', ['GDVTSF_' pn '_s' num2str(s) '.mat']));
            igdG(s)=L.out.IGD; hvG(s)=L.out.HV;
            L = load(fullfile(extDir, 'MOEA-IB', ['MOEA-IB_' pn '_s' num2str(s) '.mat']));
            igdI(s)=L.out.IGD; hvI(s)=L.out.HV;
        end
        mV=median(igdV(~isnan(igdV))); mO=median(igdO(~isnan(igdO)));
        mF=median(igdF(~isnan(igdF))); mG=median(igdG(~isnan(igdG))); mI=median(igdI(~isnan(igdI)));
        winF=sum(igdV<igdF); loseF=sum(igdV>igdF); tieF=sum(igdV==igdF);
        winO=sum(igdV<igdO); loseO=sum(igdV>igdO);
        fprintf('\n=== %s（30 种子中位 IGD / HV）===\n', pn);
        fprintf('  EDDV5: IGD=%.4f HV=%.4f | 旧EDD: IGD=%.4f HV=%.4f\n', mV, median(hvV), mO, median(hvO));
        fprintf('  FDSEA: IGD=%.4f HV=%.4f | GDVTSF: IGD=%.4f HV=%.4f | MOEA-IB: IGD=%.4f HV=%.4f\n', ...
            mF, median(hvF), mG, median(hvG), mI, median(hvI));
        fprintf('  胜负 EDDV5:FDSEA IGD = %d:%d (tie=%d)  EDDV5:旧EDD = %d:%d\n', winF, loseF, tieF, winO, loseO);
    end
end
