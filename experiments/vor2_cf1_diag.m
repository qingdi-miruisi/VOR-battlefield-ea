cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\CF');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;
prob = OfficialProblem('CF1', 3, 10);
PF = prob.ParetoFront(500);
alg = VOR(100, 200, 1);
[Pop, R] = alg.optimize(prob);
i1 = IGD(R.F, PF);
fid = fopen('results/vor2_cf1_diag.txt','w');
fprintf(fid, 'VOR-v2 CF1 s1: IGD=%.4f PPS=%d fast=%d mech=%s hasCon=%d\n', i1, size(R.F,1), R.fastPath, R.mechanism, R.hasCon);
for g = [1,5,10,20,30,50,80,100,150,200]
    fprintf(fid, 'g%d=%.4f\n', g, R.igdHistory(g));
end
fclose(fid);
disp('cf1 diag written');
