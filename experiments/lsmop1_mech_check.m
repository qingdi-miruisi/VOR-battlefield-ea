cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;
prob = OfficialProblem('LSMOP1', 3, 300);
PF = prob.ParetoFront(500);
for s = 1:3
    alg = VOR(100, 200, s);
    [P, R] = alg.optimize(prob);
    fprintf('LSMOP1 s%d mech=%s fast=%d IGD=%.4f\n', s, R.mechanism, R.fastPath, IGD(R.F, PF));
end
disp('lsmop1 mech check done');
