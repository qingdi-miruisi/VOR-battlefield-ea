cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;
prob = OfficialProblem('LSMOP6', 3, 300);
PF = prob.ParetoFront(500);
resDir = 'results/vor2_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end
for s = 1:10
    alg = VOR(100,200,s);
    [P,R] = alg.optimize(prob);
    igd = IGD(R.F,PF); pps = size(R.F,1);
    save(fullfile(resDir,sprintf('VOR_LSMOP6_s%d.mat',s)),'R','PF','igd','pps','-v7.3');
    fprintf('LSMOP6 s%d IGD=%.4f PPS=%d fast=%d mech=%s\n', s, igd, pps, R.fastPath, R.mechanism);
end
disp('LSMOP6 10seeds DONE');
