%% run_vor_d300.m — 仅重跑 VOR 的 D=300 两题（LSMOP6/DTLZ2_300D）x 10 种子
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes;

resDir = 'results/vor2_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end

probNames = {'LSMOP6','DTLZ2_300D'};
nSeed = 10;

probObj = cell(1, numel(probNames));
PFstore = cell(1, numel(probNames));
refstore = cell(1, numel(probNames));
for pi = 1:numel(probNames)
    pName = probNames{pi};
    switch pName
        case 'LSMOP6',     probObj{pi} = OfficialProblem('LSMOP6', 3, 300);
        case 'DTLZ2_300D', probObj{pi} = DTLZ2_300D_M3();
    end
    PFstore{pi} = probObj{pi}.ParetoFront(500);
    refstore{pi} = probObj{pi}.setRefPoint(PFstore{pi}).refPoint;
    fprintf('=== %s (M=%d D=%d) ===\n', pName, probObj{pi}.nObj, probObj{pi}.nVar);
end

for pi = 1:numel(probNames)
    pName = probNames{pi};
    prob = probObj{pi}; PF = PFstore{pi}; ref = refstore{pi};
    for s = 1:nSeed
        try
            alg = VOR(100,200,s);
            t0=tic; [P,R]=alg.optimize(prob); el=toc(t0);
            igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
            fname = sprintf('VOR_%s_s%d.mat', pName, s);
            save(fullfile(resDir,fname),'R','PF','ref','igd','hv','pps','el','aName','pName','-v7.3');
            fprintf('VOR %-10s s%-2d IGD=%9.4f HV=%8.4f PPS=%3d (%.2fs)\n', pName, s, igd, hv, pps, el);
        catch ME
            fprintf('VOR %-10s s%-2d FAIL: %s\n', pName, s, ME.message);
        end
    end
end
disp('VOR D300 BENCH COMPLETE');
