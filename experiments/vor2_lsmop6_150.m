cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

% 用 150 代跑（比 200 快 25%），看 GDV 是否触发 + IGD 趋势
prob = OfficialProblem('LSMOP6', 3, 300);
PF = prob.ParetoFront(500);
alg = VOR(100, 150, 1);
[Pop, R] = alg.optimize(prob);
i150 = IGD(R.F, PF);
m1 = R.mechanism;
f1 = R.fastPath;
i15 = R.igdHistory(15);
i20 = R.igdHistory(20);
i30 = R.igdHistory(30);
i50 = R.igdHistory(50);
i100 = R.igdHistory(100);
i150h = R.igdHistory(150);
fid = fopen('results/vor2_lsmop6_150.txt','w');
fprintf(fid, 'VOR-v2 LSMOP6 150gen s1: IGD=%.4f PPS=%d fast=%d mech=%s GDVK=%d\n', i150, size(R.F,1), f1, m1, R.GDVK);
fprintf(fid, 'IGD: g15=%.4f g20=%.4f g30=%.4f g50=%.4f g100=%.4f g150=%.4f\n', i15, i20, i30, i50, i100, i150h);
fclose(fid);
disp('lsmop6 150gen written');
