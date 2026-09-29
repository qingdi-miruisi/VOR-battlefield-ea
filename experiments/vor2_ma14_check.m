cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

% 读 vor2_bench 现有 MaF14 s1 的落盘值 + 现场重跑一次对比
bfile = 'results/vor2_bench/VOR_MaF14_s1.mat';
bv = load(bfile);
benchIgd = bv.igd;
benchFast = bv.R.fastPath;
benchMech = bv.R.mechanism;

prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
alg = VOR(100, 200, 1);
[Pop, R] = alg.optimize(prob);
liveIgd = IGD(R.F, PF);
liveFast = R.fastPath;
liveMech = R.mechanism;

fid = fopen('results/vor2_ma14_check.txt','w');
fprintf(fid, 'vor2_bench落盘: IGD=%.4f fast=%d mech=%s\n', benchIgd, benchFast, benchMech);
fprintf(fid, '当前代码现场重跑: IGD=%.4f fast=%d mech=%s\n', liveIgd, liveFast, liveMech);
fclose(fid);
disp('check written');
