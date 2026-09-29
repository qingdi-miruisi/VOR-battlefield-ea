function smoke_edd_v6()
% 冒烟：MaF14_M5（D=100 M=5）N=100 G=200 s1，EDDV6（双种群+EED网格坐标隐空间）
% 验证：跑通 + FE 账 ≈20115 + IGD/HV 非 NaN + PPS 合理 + A/B 初始/最终 IGD
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO'); addpath('problems_official\MaF');
    addpath('problems_official\DTLZ'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = M5Problem('MaF14', 5, 100);
    PF   = wrap.ParetoFront(500);
    ref  = wrap.setRefPoint(PF).refPoint;
    fprintf('MaF14_M5: D=%d M=%d PF点数=%d\n', wrap.D, wrap.M, size(PF,1));

    % 旧 EDD v12 对照（D=100 走 highDim 路径）
    rng(1);
    algOld = EDD(100, 200, 1);
    [PopO, ResO] = algOld.run(wrap);
    [fnO, ~] = NDSort(PopO.objs, PopO.cons, 1); ndO = find(fnO==1);
    if isempty(ndO), ndO = 1:size(PopO.objs,1); end
    igdO = IGD(PopO.objs(ndO,:), PF); hvO = HV(PopO.objs(ndO,:), ref);
    fprintf('旧 EDD    MaF14_M5 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d\n', numel(ndO), igdO, hvO, ResO.nFE);

    % EDDV6
    wrap2 = M5Problem('MaF14', 5, 100);
    PF2   = wrap2.ParetoFront(500);
    ref2  = wrap2.setRefPoint(PF2).refPoint;
    rng(1);
    algV6 = EDDV6(100, 200, 1, 'full');
    [PopV, ResV] = algV6.run(wrap2);
    [fnV, ~] = NDSort(PopV.objs, PopV.cons, 1); ndV = find(fnV==1);
    if isempty(ndV), ndV = 1:size(PopV.objs,1); end
    igdV = IGD(PopV.objs(ndV,:), PF2); hvV = HV(PopV.objs(ndV,:), ref2);
    Na = 50; Nb = 50;
    fprintf('EDDV6     MaF14_M5 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d abl=%s\n', ...
        numel(ndV), igdV, hvV, ResV.nFE, ResV.ablation);
    fprintf('  A 半 初始IGD=%.4g 最终IGD=%.4g\n', ResV.igdA_init, ResV.igdA_fin);
    fprintf('  B 半 初始IGD=%.4g 最终IGD=%.4g\n', ResV.igdB_init, ResV.igdB_fin);
    fprintf('对比: IGD %.4g -> %.4g (%.1f%%)  HV %.4g -> %.4g (%.1f%%)\n', ...
        igdO, igdV, (igdO-igdV)/max(igdO,1e-9)*100, hvO, hvV, (hvV-hvO)/max(hvO,1e-9)*100);
    if ~isfinite(igdV) || ~isfinite(hvV)
        fprintf('>>> v6 冒烟失败：IGD/HV 非有限值\n');
    elseif ResV.nFE > 20500
        fprintf('>>> v6 冒烟失败：nFE=%d 超预算（>20500）\n', ResV.nFE);
    else
        fprintf('>>> v6 冒烟通过：nFE=%d IGD=%.4g HV=%.4g PPS=%d\n', ResV.nFE, igdV, hvV, numel(ndV));
    end
end
