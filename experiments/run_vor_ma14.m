%% run_vor_ma14.m — re-run MaF14 (lost data) + verify EDD determinism
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('algorithms'); addpath('algorithms\utils');
clear classes;
resDir = 'results/vor_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end

nSeed = 10;
prob = OfficialProblem('MaF14', 3, 30);
PF = prob.ParetoFront(500);
ref = prob.setRefPoint(PF).refPoint;
fprintf('MaF14 M=%d D=%d\n', prob.nObj, prob.nVar);
algoList = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
for ai = 1:numel(algoList)
    aName = algoList{ai};
    for s = 1:nSeed
        try
            if strcmp(aName,'VOR'),    alg = VOR(100,200,s);
            elseif strcmp(aName,'EDD'), alg = EDD(100,200,s);
            elseif strcmp(aName,'MOEAD'), alg = MOEAD(100,200,s);
            elseif strcmp(aName,'RVEA'), alg = RVEA(100,200,s);
            else alg = NSGA2(100,200,s); end
            t0=tic; [P,R]=alg.optimize(prob); el=toc(t0);
            igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
            fname = sprintf('%s_MaF14_s%d.mat', aName, s);
            pName = 'MaF14';
            save(fullfile(resDir,fname),'R','PF','ref','igd','hv','pps','el','aName','pName','-v7.3');
            fprintf('%-6s s%-2d IGD=%9.4f HV=%8.4f PPS=%3d (%.2fs)\n', aName, s, igd, hv, pps, el);
        catch ME
            fprintf('%-6s s%-2d FAIL: %s\n', aName, s, ME.message);
        end
    end
end
disp('MA14 REBENCH DONE');
