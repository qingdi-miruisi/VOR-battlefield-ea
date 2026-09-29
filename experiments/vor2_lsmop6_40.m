cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

% 快速诊断：只跑 40 代（D=300 太慢，看 GDV 是否在 gen>=15 触发）
prob = OfficialProblem('LSMOP6', 3, 300);
PF = prob.ParetoFront(500);
alg = VOR(100, 40, 1);
[Pop, R] = alg.optimize(prob);
i40 = IGD(R.F, PF);
m1 = R.mechanism;
f1 = R.fastPath;
i15 = R.igdHistory(15);
i20 = R.igdHistory(20);
i30 = R.igdHistory(30);
i40h = R.igdHistory(40);
fid = fopen('results/vor2_lsmop6_40.txt','w');
fprintf(fid, 'VOR-v2 LSMOP6 40gen s1: IGD=%.4f PPS=%d fast=%d mech=%s GDVK=%d\n', i40, size(R.F,1), f1, m1, R.GDVK);
fprintf(fid, 'IGD: g15=%.4f g20=%.4f g30=%.4f g40=%.4f\n', i15, i20, i30, i40h);
fclose(fid);
disp('lsmop6 40gen written');
