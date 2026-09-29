cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
alg1 = VOR(100,200,1);
[P1,R1] = alg1.optimize(prob);
r1 = IGD(R1.F, PF);
alg2 = VOR(100,200,2);
[P2,R2] = alg2.optimize(prob);
r2 = IGD(R2.F, PF);
alg3 = VOR(100,200,3);
[P3,R3] = alg3.optimize(prob);
r3 = IGD(R3.F, PF);
msg = sprintf('VOR-v2 MaF14 smoke: s1=%.4f PPS=%d fast=%d | s2=%.4f PPS=%d | s3=%.4f PPS=%d', ...
    r1, size(R1.F,1), R1.fastPath, r2, size(R2.F,1), r3, size(R3.F,1));
disp(msg);
