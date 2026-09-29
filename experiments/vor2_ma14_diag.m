cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
alg = VOR(100, 200, 1);
[Pop, R] = alg.optimize(prob);
i1 = IGD(R.F, PF);
f1 = R.fastPath;
m1 = R.mechanism;
ig5 = R.igdHistory(5);
ig10 = R.igdHistory(10);
ig20 = R.igdHistory(20);
ig45 = R.igdHistory(45);
ig50 = R.igdHistory(50);
ig100 = R.igdHistory(100);
ig200 = R.igdHistory(200);
nF = size(R.F, 1);
fid = fopen('results/vor2_ma14_diag.txt', 'w');
fprintf(fid, 'VOR-v2 MaF14 s1: IGD=%.4f PPS=%d fastPath=%d mech=%s\n', i1, nF, f1, m1);
fprintf(fid, 'IGD trajectory: g5=%.3f g10=%.3f g20=%.3f g45=%.3f g50=%.3f g100=%.3f g200=%.3f\n', ...
    ig5, ig10, ig20, ig45, ig50, ig100, ig200);
fclose(fid);
disp('diag written');
