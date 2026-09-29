function smoke_mw1_diag()
% 诊断 MW1：PF 口径 + EED 路径 IGD=11 是机制崩溃还是 PF/ref 问题
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('MW1', 2, 15);
    D = wrap.D; M = wrap.M;
    PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
    fprintf('MW1 M=%d D=%d PF点数=%d refPoint=%s\n', M, D, size(PF,1), mat2str(ref,3));
    fprintf('PF(1,:)=%s  PF(end,:)=%s\n', mat2str(PF(1,:),3), mat2str(PF(end,:),3));

    % EDD_cf 跑 10 代看 front-1 演化
    rng(1); alg = EDD_cf(100, 200, 1);
    t0 = tic;
    [Pop, Res] = alg.run(wrap);
    fprintf('MW1 EDD_cf 全200代 nFE=%d elap=%.1fs PPS=%d\n', Res.nFE, toc(t0), size(Pop.objs,1));
    [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn == 1);
    if isempty(nd), nd = 1:size(Pop.objs,1); end
    igd = IGD(Pop.objs(nd,:), PF); hv = HV(Pop.objs(nd,:), ref);
    fprintf('MW1 s1 EDD_cf IGD=%.4g HV=%.4g PPS=%d\n', igd, hv, numel(nd));

    % 对照：旧 EDD（v12 APD 路径，门控未放宽）在 MW1
    rng(1); algO = EDD(100, 200, 1);
    t0 = tic;
    [PopO, ResO] = algO.run(wrap);
    [fnO, ~] = NDSort(PopO.objs, PopO.cons, 1); ndO = find(fnO == 1);
    if isempty(ndO), ndO = 1:size(PopO.objs,1); end
    igdO = IGD(PopO.objs(ndO,:), PF); hvO = HV(PopO.objs(ndO,:), ref);
    fprintf('MW1 s1 旧EDD(APD) IGD=%.4g HV=%.4g PPS=%d elap=%.1fs\n', igdO, hvO, numel(ndO), toc(t0));
end
