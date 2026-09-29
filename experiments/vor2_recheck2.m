cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR; clear EDD;

fid = fopen('results/vor2_recheck2.txt','w');
% MaF14 VOR vs EDD
prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
algV = VOR(100,200,1);
[PopV,RV] = algV.optimize(prob);
algE = EDD(100,200,1);
[PopE,RE] = algE.optimize(prob);
iV = IGD(RV.F,PF); iE = IGD(RE.F,PF);
fprintf(fid, 'MaF14 s1: VOR IGD=%.4f PPS=%d | EDD IGD=%.4f PPS=%d\n', iV, size(RV.F,1), iE, size(RE.F,1));

% LSMOP6 D=300
prob2 = OfficialProblem('LSMOP6', 3, 300);
PF2 = prob2.ParetoFront(500);
algV2 = VOR(100,200,1);
[PopV2,RV2] = algV2.optimize(prob2);
algE2 = EDD(100,200,1);
[PopE2,RE2] = algE2.optimize(prob2);
iV2 = IGD(RV2.F,PF2); iE2 = IGD(RE2.F,PF2);
fprintf(fid, 'LSMOP6 s1: VOR IGD=%.4f PPS=%d mech=%s | EDD IGD=%.4f PPS=%d mech=%s\n', ...
    iV2, size(RV2.F,1), RV2.mechanism, iE2, size(RE2.F,1), RE2.mechanism);

% DTLZ2_300D
prob3 = DTLZ2_300D_M3();
PF3 = prob3.ParetoFront(500);
algV3 = VOR(100,200,1);
[PopV3,RV3] = algV3.optimize(prob3);
algE3 = EDD(100,200,1);
[PopE3,RE3] = algE3.optimize(prob3);
iV3 = IGD(RV3.F,PF3); iE3 = IGD(RE3.F,PF3);
fprintf(fid, 'DTLZ2_300D s1: VOR IGD=%.4f PPS=%d mech=%s | EDD IGD=%.4f PPS=%d mech=%s\n', ...
    iV3, size(RV3.F,1), RV3.mechanism, iE3, size(RE3.F,1), RE3.mechanism);
fclose(fid);
disp('recheck2 written');
