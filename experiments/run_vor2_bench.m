%% run_vor2_bench.m — VOR-v2 全量基准（6 题 x 5 算法 x 10 种子）
% 包含 SOTA 对标（EDDV9 内核交换 = GDVTSF/FDSEA/MOEA-IB 三人组合并）。
% 输出：results/vor2_bench/{algo}_{problem}_s{seed}.mat
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils'); addpath('algorithms\GDVTSF');
addpath('algorithms\WOF'); addpath('algorithms\FDSEA');
addpath('algorithms\MOEA_IB\WOF'); addpath('algorithms\MOEA_IB\ReMO'); addpath('algorithms\MOEA_IB');
clear classes;

resDir = 'results/vor2_bench';
if ~exist(resDir,'dir'), mkdir(resDir); end

% 问题定义（名称, 构造函数句柄, M, D）— 扁平 cell
probNames = {'MaF14','LSMOP6','CF1','DTLZ2_300D','ZDT1','LSMOP1'};
algoList = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
nSeed = 10;

% 预构造所有问题对象（共享 PF/ref）
probObj = cell(1, numel(probNames));
PFstore = cell(1, numel(probNames));
refstore = cell(1, numel(probNames));
for pi = 1:numel(probNames)
    pName = probNames{pi};
    switch pName
        case 'MaF14',      probObj{pi} = OfficialProblem('MaF14', 3, 30);
        case 'LSMOP6',     probObj{pi} = OfficialProblem('LSMOP6', 3, 300);
        case 'CF1',        probObj{pi} = OfficialProblem('CF1',  3, 10);
        case 'DTLZ2_300D', probObj{pi} = DTLZ2_300D_M3();
        case 'ZDT1',       probObj{pi} = ZDT1(30);
        case 'LSMOP1',     probObj{pi} = OfficialProblem('LSMOP1', 3, 300);
    end
    PFstore{pi} = probObj{pi}.ParetoFront(500);
    refstore{pi} = probObj{pi}.setRefPoint(PFstore{pi}).refPoint;
    fprintf('=== %s (M=%d D=%d) ===\n', pName, probObj{pi}.nObj, probObj{pi}.nVar);
end

for ai = 1:numel(algoList)
    aName = algoList{ai};
    for pi = 1:numel(probNames)
        pName = probNames{pi};
        prob = probObj{pi}; PF = PFstore{pi}; ref = refstore{pi};
        for s = 1:nSeed
            try
                if strcmp(aName,'VOR'),    alg = VOR(100,200,s);
                elseif strcmp(aName,'EDD'), alg = EDD(100,200,s);
                elseif strcmp(aName,'MOEAD'), alg = MOEAD(100,200,s);
                elseif strcmp(aName,'RVEA'), alg = RVEA(100,200,s);
                elseif strcmp(aName,'NSGA2'), alg = NSGA2(100,200,s);
                else alg = EDDV9(100,200,s); end
                t0=tic; [P,R]=alg.optimize(prob); el=toc(t0);
                igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
                fname = sprintf('%s_%s_s%d.mat', aName, pName, s);
                pNameStore = pName;
                save(fullfile(resDir,fname),'R','PF','ref','igd','hv','pps','el','aName','pName','-v7.3');
                fprintf('%-6s %-16s s%-2d IGD=%9.4f HV=%8.4f PPS=%3d (%.2fs)\n', ...
                    aName, pName, s, igd, hv, pps, el);
            catch ME
                fprintf('%-6s %-16s s%-2d FAIL: %s\n', aName, pName, s, ME.message);
            end
        end
    end
end

%% ---- 汇总 ----
fprintf('\n=== 汇总 (10 seeds 均值 ± 标准差) ===\n');
fprintf('%-6s %-14s %14s %12s %8s\n','Algo','Problem','IGD(mean±std)','HV(mean±std)','PPS');
agg = struct('algo',aName,'prob',pName,'igd',igd,'hv',hv,'pps',pps,'el',el);
for ai = 1:numel(algoList)
    for pi = 1:numel(probDefs)
        aName = algoList{ai}; pName = probDefs{pi}{1};
        igdV = []; hvV = []; ppsV = [];
        for s = 1:nSeed
            f = sprintf('%s/%s_%s_s%d.mat', resDir, aName, pName, s);
            if exist(f,'file')
                S = load(f);
                igdV(end+1) = S.igd; hvV(end+1) = S.hv; ppsV(end+1) = S.pps;
            end
        end
        if ~isempty(igdV)
            fprintf('%-6s %-14s %6.4f±%5.4f %6.4f±%5.4f %4d\n', ...
                aName, pName, mean(igdV), std(igdV), mean(hvV), std(hvV), mean(ppsV));
        else
            fprintf('%-6s %-14s (no data)\n', aName, pName);
        end
    end
end
disp('VOR2 BENCH COMPLETE');
