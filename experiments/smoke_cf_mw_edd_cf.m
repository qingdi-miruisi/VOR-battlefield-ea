function smoke_cf_mw_edd_cf()
% 冒烟：CF1 + MW1 s1，EDD_cf（门控放宽版），验证 CF/MW 都跑通 + EED 启用
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap1 = OfficialProblem('CF1', 2, 10);
    wrap2 = OfficialProblem('MW1', 2, 15);
    for k = 1:2
        if k == 1, pn = 'CF1'; wrap = wrap1; else, pn = 'MW1'; wrap = wrap2; end
        D = wrap.D; M = wrap.M;
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        X0 = wrap.lower + rand(1, D) .* (wrap.upper - wrap.lower);
        c0 = wrap.CalCon(X0);
        t0 = tic;
        rng(1); alg = EDD_cf(100, 200, 1);
        [Pop, Res] = alg.run(wrap);
        [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn == 1);
        if isempty(nd), nd = 1:size(Pop.objs, 1); end
        igd = IGD(Pop.objs(nd,:), PF); hv = HV(Pop.objs(nd,:), ref);
        fprintf('%s s1 EDD_cf M=%d D=%d nCon=%d highDim=%d hasCon=%d IGD=%.4g HV=%.4g PPS=%d elap=%.1fs\n', ...
            pn, M, D, size(c0,2), Res.highDim, Res.hasCon, igd, hv, numel(nd), toc(t0));
    end
end
