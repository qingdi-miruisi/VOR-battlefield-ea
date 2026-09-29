function smoke_edd_dsg()
% 冒烟：LSMOP1 N=100 G=200 s1，EDD 当前版（只验证跑通 + IGD 量级，非改进验证）
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
    alg = EDD(100, 200, 1);
    [Pop, Res] = alg.run(wrap);
    [fn, ~] = NDSort(Pop.objs, Pop.cons, 1);
    nd = find(fn==1);
    if isempty(nd), nd = 1:size(Pop.objs,1); end
    F = Pop.objs(nd,:);
    ig = IGD(F, PF); hv = HV(F, ref);
    fprintf('EDD 当前版 LSMOP1 s1: PPS=%d IGD=%.4g HV=%.4g nFE=%d mech=%s switchGen=%d\n', ...
        numel(nd), ig, hv, Res.nFE, Res.mechanism, Res.switchGen);
end
