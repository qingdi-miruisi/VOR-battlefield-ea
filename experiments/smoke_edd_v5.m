function smoke_edd_v5()
% 冒烟：LSMOP1 N=100 G=200 s1，EDDV5（双种群·强化版a）vs 旧 EDD 对照
% 报告 A/B 的 PPS、IGD、HV + FDSEA 基线对照
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('LSMOP1', 3, 300);
    PF   = wrap.ParetoFront(500);
    ref  = wrap.setRefPoint(PF).refPoint;
    rng(1);
    algOld = EDD(100, 200, 1);
    [PopO, ResO] = algOld.run(wrap);
    [fnO, ~] = NDSort(PopO.objs, PopO.cons, 1); ndO = find(fnO==1);
    if isempty(ndO), ndO = 1:size(PopO.objs,1); end
    igdO = IGD(PopO.objs(ndO,:), PF); hvO = HV(PopO.objs(ndO,:), ref);
    fprintf('旧 EDD    LSMOP1 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d\n', numel(ndO), igdO, hvO, ResO.nFE);

    wrap2 = OfficialProblem('LSMOP1', 3, 300);
    PF2   = wrap2.ParetoFront(500);
    ref2  = wrap2.setRefPoint(PF2).refPoint;
    rng(1);
    algV5 = EDDV5(100, 200, 1, 'full');
    Na_half = 50; Nb_half = 50;   % N=100, A=前50 B=后50
    [PopV, ResV] = algV5.run(wrap2);
    % A 半 / B 半 PPS（前 Na 行 = A，后 Nb 行 = B）
    Aobj = PopV.objs(1:Na_half,:); Bobj = PopV.objs(Na_half+1:Na_half+Nb_half,:);
    ppsA = size(Aobj,1); ppsB = size(Bobj,1);
    [fnV, ~] = NDSort(PopV.objs, PopV.cons, 1); ndV = find(fnV==1);
    if isempty(ndV), ndV = 1:size(PopV.objs,1); end
    igdV = IGD(PopV.objs(ndV,:), PF2); hvV = HV(PopV.objs(ndV,:), ref2);
    fprintf('EDDV5     LSMOP1 s1: PPS=%d(全) A=%d B=%d IGD=%.4g HV=%.4g nFE=%d abl=%s\n', ...
        numel(ndV), ppsA, ppsB, igdV, hvV, ResV.nFE, ResV.ablation);
    fprintf('  A 半 IGD=%.4g  B 半 IGD=%.4g\n', IGD(Aobj, PF2), IGD(Bobj, PF2));
    fprintf('对比: IGD %.4g -> %.4g (%.1f%%)  HV %.4g -> %.4g (%.1f%%)\n', ...
        igdO, igdV, (igdO-igdV)/igdO*100, hvO, hvV, (hvV-hvO)/max(hvO,1e-9)*100);
    % FDSEA/GDVTSF/MOEA-IB 基线（已知 30 种子中位 IGD）
    fprintf('FDSEA 基线 LSMOP1 IGD≈0.1209  GDVTSF≈0.4387  MOEA-IB≈0.3869\n');
    if igdV < igdO
        fprintf('>>> v5 IGD 改善 (%.4g vs 旧 %.4g)，可进 LSMOP1-3 ×30 种子\n', igdV, igdO);
    else
        fprintf('>>> v5 IGD 未改善（%.4g vs 旧 %.4g），需评估胜负比\n', igdV, igdO);
    end
    if igdV < 0.3
        fprintf('>>> v5 接近 FDSEA 水平 (<0.3)，有望\n');
    end
end
