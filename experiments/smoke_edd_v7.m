% 冒烟测试 EDDV7：MW1（CF/MW 崩塌战场）+ LSMOP2（已收敛实例）+ LSMOP6（崩塌实例）
% N=100 G=200 s1-3，对比 EDDV7 vs 旧 EDD vs SOTA 中位
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear IGD HV;

tests = {
    'MW1',       2, 10, 'CF/MW 崩塌战场（PPS 崩塌修复验证）';
    'LSMOP2',    3, 300, 'LSMOP 已收敛实例（WD 后期收敛验证）';
    'LSMOP6',    3, 300, 'LSMOP 崩塌实例（EED 鲁棒性保持验证）';
};

for t = 1:size(tests,1)
    pn = tests{t,1}; M = tests{t,2}; D = tests{t,3}; desc = tests{t,4};
    fprintf('\n========== %s (M=%d D=%d) %s ==========\n', pn, M, D, desc);
    wrap = OfficialProblem(pn, M, D);
    PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
    igdV7 = nan(1,3); hvV7 = nan(1,3); ppsV7 = nan(1,3);
    igdOld = nan(1,3); hvOld = nan(1,3); ppsOld = nan(1,3);
    for s = 1:3
        % EDDV7
        rng(s); algV7 = EDDV7(100, 200, s);
        [PopV7, ResV7] = algV7.run(wrap);
        [fn, ~] = NDSort(PopV7.objs, PopV7.cons, 1); nd = find(fn==1);
        if isempty(nd), nd = 1:size(PopV7.objs,1); end
        F = PopV7.objs(nd,:);
        igdV7(s) = IGD(F, PF); hvV7(s) = HV(F, ref); ppsV7(s) = numel(nd);
        % 旧 EDD
        rng(s); algOld = EDD(100, 200, s);
        [PopOld, ResOld] = algOld.run(wrap);
        [fn2, ~] = NDSort(PopOld.objs, PopOld.cons, 1); nd2 = find(fn2==1);
        if isempty(nd2), nd2 = 1:size(PopOld.objs,1); end
        F2 = PopOld.objs(nd2,:);
        igdOld(s) = IGD(F2, PF); hvOld(s) = HV(F2, ref); ppsOld(s) = numel(nd2);
        fprintf('s%d  V7: IGD=%.4g HV=%.4g PPS=%d | Old: IGD=%.4g HV=%.4g PPS=%d\n', ...
            s, igdV7(s), hvV7(s), ppsV7(s), igdOld(s), hvOld(s), ppsOld(s));
    end
    fprintf('中位  V7: IGD=%.4g HV=%.4g PPS=%d | Old: IGD=%.4g HV=%.4g PPS=%d\n', ...
        median(igdV7), median(hvV7), median(ppsV7), median(igdOld), median(hvOld), median(ppsOld));
    fprintf('V7 改善: IGD %.0f%% | HV %.0f%% | PPS %d -> %d\n', ...
        100*(median(igdV7)/median(igdOld)-1), ...
        100*(median(hvV7)/max(median(hvOld),1e-9)-1), ...
        median(ppsOld), median(ppsV7));
end
