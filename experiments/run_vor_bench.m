%% run_vor_bench.m — VOR vs EDD vs MOEAD vs RVEA vs NSGA2, 5 problems x 10 seeds
% 战场：MaF14(M=3,D=30 PPS坍缩) / LSMOP6(D=300 HV=0塌方) / CF1(D=10约束 PPS边界)
%      DTLZ2_300D_M3(D=300 高维) / ZDT1(M=2 收敛基线，无损害验证)
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('algorithms'); addpath('algorithms\utils');
clear classes;
resDir = 'results/vor_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end
delete(fullfile(resDir,'*.mat'));

nSeed = 10;
probList = {'MaF14', 'LSMOP6', 'CF1', 'DTLZ2_300D_M3', 'ZDT1'};
algoList = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
res = struct();

for pi = 1:numel(probList)
    pName = probList{pi};
    if strcmp(pName,'MaF14'),    prob = OfficialProblem('MaF14', 3, 30);
    elseif strcmp(pName,'LSMOP6'), prob = OfficialProblem('LSMOP6', 3, 300);
    elseif strcmp(pName,'CF1'),    prob = OfficialProblem('CF1', 3, 10);
    elseif strcmp(pName,'DTLZ2_300D_M3'), prob = DTLZ2_300D_M3();
    elseif strcmp(pName,'ZDT1'),   prob = ZDT1(30);
    end
    PF = prob.ParetoFront(500);
    ref = prob.setRefPoint(PF).refPoint;
    fprintf('=== %s (M=%d D=%d) ===\n', pName, prob.nObj, prob.nVar);
    for ai = 1:numel(algoList)
        aName = algoList{ai};
        for s = 1:nSeed
            try
                if strcmp(aName,'VOR'),    alg = VOR(100,200,s);
                elseif strcmp(aName,'EDD'), alg = EDD(100,200,s);
                elseif strcmp(aName,'MOEAD'), alg = MOEAD(100,200,s);
                elseif strcmp(aName,'RVEA'), alg = RVEA(100,200,s);
                elseif strcmp(aName,'NSGA2'), alg = NSGA2(100,200,s);
                end
                t0=tic; [P,R]=alg.optimize(prob); el=toc(t0);
                igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
                res.igd{ai,pi,s} = igd; res.hv{ai,pi,s} = hv; res.pps{ai,pi,s} = pps;
                res.t{ai,pi,s} = el;
                fname = sprintf('%s_%s_s%d.mat', aName, pName, s);
                save(fullfile(resDir,fname),'R','PF','ref','igd','hv','pps','el', ...
                    'aName','pName', '-v7.3');
                fprintf('  %-6s s%-2d IGD=%9.4f HV=%8.4f PPS=%3d (%.2fs)\n', ...
                    aName, s, igd, hv, pps, el);
            catch ME
                res.igd{ai,pi,s} = NaN; res.hv{ai,pi,s}=NaN; res.pps{ai,pi,s}=NaN; res.t{ai,pi,s}=NaN;
                fprintf('  %-6s s%-2d FAIL: %s\n', aName, s, ME.message);
            end
        end
    end
end

%% Aggregate
fprintf('\n=== 汇总 (10 seeds 均值 ± 标准差) ===\n');
fprintf('%-8s %-18s %12s %12s %8s\n','Algo','Problem','IGD','HV','PPS');
for ai = 1:numel(algoList)
    for pi = 1:numel(probList)
        igd = cell2mat(res.igd{ai,pi,:}(:));
        hv  = cell2mat(res.hv{ai,pi,:}(:));
        pps = cell2mat(res.pps{ai,pi,:}(:));
        valid = ~isnan(igd);
        fprintf('%-8s %-18s %5.4f±%5.4f %6.4f±%5.4f %4d±%3d\n', ...
            algoList{ai}, probList{pi}, ...
            mean(igd(valid)), std(igd(valid)), ...
            mean(hv(valid)), std(hv(valid)), ...
            mean(pps(valid)), std(pps(valid)));
    end
end
save(fullfile(resDir,'bench_full.mat'),'res','algoList','probList','-v7.3');
fprintf('\nDone. Results in %s\n', resDir);
