cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;
prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
ref = prob.setRefPoint(PF).refPoint;
aName = 'VOR'; pName = 'MaF14';
resDir = 'results/vor2_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end
for s = 1:10
    alg = VOR(100,200,s);
    [P,R] = alg.optimize(prob);
    igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
    save(fullfile(resDir,sprintf('VOR_MaF14_s%d.mat',s)),'R','PF','ref','igd','hv','pps','aName','pName','-v7.3');
    fprintf('MaF14 s%d IGD=%.4f HV=%.4f PPS=%d\n', s, igd, hv, pps);
end
disp('MaF14 10seeds DONE');
