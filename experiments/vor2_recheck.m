cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

fid = fopen('results/vor2_recheck.txt','w');
% MaF14 (D=60 M=3)
prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
alg = VOR(100,200,1);
[Pop,R] = alg.optimize(prob);
i1 = IGD(R.F,PF);
fprintf(fid, 'MaF14 s1: IGD=%.4f PPS=%d fast=%d mech=%s GDVK=%d\n', i1, size(R.F,1), R.fastPath, R.mechanism, R.GDVK);
% DTLZ2_300D (D=300 M=3)
prob2 = DTLZ2_300D_M3();
PF2 = prob2.ParetoFront(500);
alg2 = VOR(100,200,1);
[Pop2,R2] = alg2.optimize(prob2);
i2 = IGD(R2.F,PF2);
fprintf(fid, 'DTLZ2_300D s1: IGD=%.4f PPS=%d fast=%d mech=%s GDVK=%d IGD@50=%.4f IGD@200=%.4f\n', ...
    i2, size(R2.F,1), R2.fastPath, R2.mechanism, R2.GDVK, R2.igdHistory(50), R2.igdHistory(200));
fclose(fid);
disp('recheck written');
