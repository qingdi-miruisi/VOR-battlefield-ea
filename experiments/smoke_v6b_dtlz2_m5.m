function smoke_v6b_dtlz2_m5()
% 第三诊断（A）：DTLZ2_300_M5（M=5 D=300 解析球面 PF）EDDV6 v6b vs 旧 EDD
% 判 θ 机制在单峰题上是否偏离旧 EDD（偏离>5% → 进任务2/3；≈旧 EDD → 进第四诊断 C）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO');
    addpath('problems_official\MaF'); addpath('problems_official\DTLZ'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = M5Problem('DTLZ2', 5, 300);
    PF   = wrap.ParetoFront(500);
    ref  = wrap.setRefPoint(PF).refPoint;
    fprintf('DTLZ2_M5: D=%d M=%d PF点数=%d\n', wrap.D, wrap.M, size(PF,1));

    rng(1);
    algOld = EDD(100, 200, 1);
    [PopO, ResO] = algOld.run(wrap);
    [fnO, ~] = NDSort(PopO.objs, PopO.cons, 1); ndO = find(fnO==1);
    if isempty(ndO), ndO = 1:size(PopO.objs,1); end
    igdO = IGD(PopO.objs(ndO,:), PF); hvO = HV(PopO.objs(ndO,:), ref);
    fprintf('旧 EDD    DTLZ2_M5 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d\n', numel(ndO), igdO, hvO, ResO.nFE);

    wrap2 = M5Problem('DTLZ2', 5, 300);
    PF2   = wrap2.ParetoFront(500);
    ref2  = wrap2.setRefPoint(PF2).refPoint;
    rng(1);
    algV6 = EDDV6(100, 200, 1, 'full');
    [PopV, ResV] = algV6.run(wrap2);
    [fnV, ~] = NDSort(PopV.objs, PopV.cons, 1); ndV = find(fnV==1);
    if isempty(ndV), ndV = 1:size(PopV.objs,1); end
    igdV = IGD(PopV.objs(ndV,:), PF2); hvV = HV(PopV.objs(ndV,:), ref2);
    fprintf('EDDV6 v6b DTLZ2_M5 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d\n', numel(ndV), igdV, hvV, ResV.nFE);
    fprintf('  A 半 最终IGD=%.4g  B 半 最终IGD=%.4g\n', ResV.igdA_fin, ResV.igdB_fin);
    dev = abs(igdO-igdV)/max(igdO,1e-9)*100;
    fprintf('偏离度: IGD %.4g -> %.4g (%.1f%%)\n', igdO, igdV, dev);
    if dev > 5
        fprintf('>>> v6b 在 DTLZ2_M5 偏离旧 EDD >5%%，θ 机制在单峰题发力，进任务2/3\n');
    else
        fprintf('>>> v6b 在 DTLZ2_M5 偏离旧 EDD <5%%，θ 机制未偏离，进第四诊断 C（消融）\n');
    end
end
