function smoke_edd_v2()
% 冒烟：LSMOP1 N=100 G=200 s1，EDDV2（双源交叉+全维polish）vs 旧 EDD 对照
% 注意：clear classes 会清掉 OfficialProblem 等 handle 对象，clear 后必须重建
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('LSMOP1', 3, 300);
    PF   = wrap.ParetoFront(500);
    ref  = wrap.setRefPoint(PF).refPoint;

    % 旧 EDD 对照
    rng(1);
    algOld = EDD(100, 200, 1);
    [PopO, ResO] = algOld.run(wrap);
    [fnO, ~] = NDSort(PopO.objs, PopO.cons, 1); ndO = find(fnO==1);
    if isempty(ndO), ndO = 1:size(PopO.objs,1); end
    igdO = IGD(PopO.objs(ndO,:), PF); hvO = HV(PopO.objs(ndO,:), ref);
    fprintf('旧 EDD    LSMOP1 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d\n', numel(ndO), igdO, hvO, ResO.nFE);

    % EDDV2（重建 wrap，避免 run 内部 clear 影响）
    wrap2 = OfficialProblem('LSMOP1', 3, 300);
    PF2   = wrap2.ParetoFront(500);
    ref2  = wrap2.setRefPoint(PF2).refPoint;
    rng(1);
    algV2 = EDDV2(100, 200, 1);
    [PopV, ResV] = algV2.run(wrap2);
    [fnV, ~] = NDSort(PopV.objs, PopV.cons, 1); ndV = find(fnV==1);
    if isempty(ndV), ndV = 1:size(PopV.objs,1); end
    igdV = IGD(PopV.objs(ndV,:), PF2); hvV = HV(PopV.objs(ndV,:), ref2);
    fprintf('EDDV2     LSMOP1 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d mech=%s\n', ...
        numel(ndV), igdV, hvV, ResV.nFE, ResV.mechanism);
    fprintf('提升: IGD %.4g -> %.4g (%.1f%%)  HV %.4g -> %.4g (%.1f%%)\n', ...
        igdO, igdV, (igdO-igdV)/igdO*100, hvO, hvV, (hvV-hvO)/max(hvO,1e-9)*100);
    if igdV < igdO
        fprintf('>>> v2 IGD 改善，可进阶段3.3\n');
    else
        fprintf('>>> v2 IGD 未改善（仍 %.4g vs 旧 %.4g），需回 3.2 换方案\n', igdV, igdO);
    end
end
