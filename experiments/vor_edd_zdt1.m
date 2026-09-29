cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR; clear EDD;
prob = ZDT1(30);
PF = prob.ParetoFront(500);
fid = fopen('results/vor_vs_edd_zdt1.txt','w');
% EDD (APD path for ZDT1)
alg = EDD(100,200,1);
[P,R] = alg.optimize(prob);
i = IGD(R.F,PF);
fprintf(fid, 'EDD  ZDT1 s1: IGD=%.4f PPS=%d mech=%s\n', i, size(R.F,1), R.mechanism);
% VOR (APD path for ZDT1 now)
alg2 = VOR(100,200,1);
[P2,R2] = alg2.optimize(prob);
i2 = IGD(R2.F,PF);
fprintf(fid, 'VOR  ZDT1 s1: IGD=%.4f PPS=%d fast=%d mech=%s\n', i2, size(R2.F,1), R2.fastPath, R2.mechanism);
fclose(fid);
disp('written');
