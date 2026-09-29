cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

prob = ZDT1(30);
PF = prob.ParetoFront(500);
alg = VOR(100, 200, 1);
[Pop, R] = alg.optimize(prob);
i1 = IGD(R.F, PF);
f1 = R.fastPath;
m1 = R.mechanism;
i50 = R.igdHistory(50);
i100 = R.igdHistory(100);
i120 = R.igdHistory(120);
i140 = R.igdHistory(140);
i160 = R.igdHistory(160);
i180 = R.igdHistory(180);
i200 = R.igdHistory(200);
fid = fopen('results/vor2_zdt1_diag.txt','w');
fprintf(fid, 'VOR-v2 ZDT1 s1: IGD=%.4f PPS=%d fast=%d mech=%s\n', i1, size(R.F,1), f1, m1);
fprintf(fid, 'IGD: g50=%.4f g100=%.4f g120=%.4f g140=%.4f g160=%.4f g180=%.4f g200=%.4f\n', ...
    i50, i100, i120, i140, i160, i180, i200);
fclose(fid);
disp('zdt1 diag written');
