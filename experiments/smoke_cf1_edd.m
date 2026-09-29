function smoke_cf1_edd()
% 冒烟：CF1（M=2 D=10, 1 约束）N=100 G=200 s1，旧 EDD v12
% 验证：OfficialProblem.CalCon 桥接（约束非空）+ EDD 约束路径 + 单题时长
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('CF1', 2, 10);
    D = wrap.D; M = wrap.M;
    PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
    X0 = wrap.lower + rand(1, D) .* (wrap.upper - wrap.lower);
    c0 = wrap.CalCon(X0);
    nCon = size(c0, 2);
    fprintf('CF1: M=%d D=%d nCon=%d PF点数=%d  约束值=%g\n', M, D, nCon, size(PF, 1), c0);

    t0 = tic;
    rng(1); alg = EDD(100, 200, 1);
    [Pop, Res] = alg.run(wrap);
    [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn == 1);
    if isempty(nd), nd = 1:size(Pop.objs, 1); end
    igd = IGD(Pop.objs(nd,:), PF); hv = HV(Pop.objs(nd,:), ref);
    fprintf('CF1 s1 旧EDD IGD=%.4g HV=%.4g nFE=%d PPS=%d elap=%.1fs\n', ...
        igd, hv, Res.nFE, numel(nd), toc(t0));
    if nCon == 0
        fprintf('>>> 警告：CF1 约束为空（CalCon 桥接失败），EDD 实际按无约束跑\n');
    else
        fprintf('>>> CF1 约束桥接 OK（nCon=%d），EDD 走约束路径\n', nCon);
    end
end
