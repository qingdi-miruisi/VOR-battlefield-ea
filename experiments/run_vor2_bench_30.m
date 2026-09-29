%% run_vor2_bench_30.m — VOR-v2 基准补跑到 30 seeds（5 算法 x 6 题 x seeds 11:30）
% 复用 run_vor2_bench.m 的问题定义；只补跑 seed 11–30（1–10 已存在 results/vor2_bench/）。
% 输出：results/vor2_bench/{algo}_{problem}_s{seed}.mat（与 10-seed 同目录同格式）
% 日志：results/vor2_bench/run30_log.txt（逐 run 追加，便于监控进度）
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
logFile = fullfile(resDir,'run30_log.txt');
if exist(logFile,'file'), delete(logFile); end
fid = fopen(logFile,'w');
fprintf(fid, '=== run_vor2_bench_30: %s ===\n', datestr(now));

probNames = {'MaF14','LSMOP6','CF1','DTLZ2_300D','ZDT1','LSMOP1'};
algoList  = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
seedLo = 11; seedHi = 30;

% 预构造问题
probObj = cell(1,numel(probNames)); PFstore = cell(1,numel(probNames)); refstore = cell(1,numel(probNames));
for pi = 1:numel(probNames)
    switch probNames{pi}
        case 'MaF14',      probObj{pi} = OfficialProblem('MaF14', 3, 30);
        case 'LSMOP6',     probObj{pi} = OfficialProblem('LSMOP6', 3, 300);
        case 'CF1',        probObj{pi} = OfficialProblem('CF1',  3, 10);
        case 'DTLZ2_300D', probObj{pi} = DTLZ2_300D_M3();
        case 'ZDT1',       probObj{pi} = ZDT1(30);
        case 'LSMOP1',     probObj{pi} = OfficialProblem('LSMOP1', 3, 300);
    end
    PFstore{pi} = probObj{pi}.ParetoFront(500);
    refstore{pi} = probObj{pi}.setRefPoint(PFstore{pi}).refPoint;
    fprintf(fid, '=== %s (M=%d D=%d) ready ===\n', probNames{pi}, probObj{pi}.nObj, probObj{pi}.nVar);
end

done = 0; fail = 0; total = numel(algoList)*numel(probNames)*(seedHi-seedLo+1);
for ai = 1:numel(algoList)
    for pi = 1:numel(probNames)
        for s = seedLo:seedHi
            fOut = fullfile(resDir, sprintf('%s_%s_s%d.mat', algoList{ai}, probNames{pi}, s));
            if exist(fOut,'file')
                done = done + 1;
                continue;  % 已有则跳过（幂等，可重跑续传）
            end
            try
                prob = probObj{pi}; PF = PFstore{pi}; ref = refstore{pi};
                if     strcmp(algoList{ai},'VOR'),    alg = VOR(100,200,s);
                elseif strcmp(algoList{ai},'EDD'),    alg = EDD(100,200,s);
                elseif strcmp(algoList{ai},'MOEAD'),  alg = MOEAD(100,200,s);
                elseif strcmp(algoList{ai},'RVEA'),   alg = RVEA(100,200,s);
                else                                    alg = NSGA2(100,200,s);
                end
                t0=tic; [P,R]=alg.optimize(prob); el=toc(t0);
                igd = IGD(R.F,PF); hv = HV(R.F,ref); pps = size(R.F,1);
                aName = algoList{ai}; pName = probNames{pi};
                save(fOut,'R','PF','ref','igd','hv','pps','el','aName','pName','-v7.3');
                done = done + 1;
                fprintf(fid, '%6d/%4d %-6s %-12s s%-2d IGD=%9.4f HV=%8.4f PPS=%3d (%.2fs)\n', ...
                    done, total, algoList{ai}, probNames{pi}, s, igd, hv, pps, el);
            catch ME
                fail = fail + 1;
                fprintf(fid, 'FAIL %-6s %-12s s%-2d: %s\n', ...
                    algoList{ai}, probNames{pi}, s, ME.message);
            end
        end
    end
end
fprintf(fid, '\n=== DONE: %d runs completed, %d failed ===\n', done, fail);
fclose(fid);
disp('run_vor2_bench_30 COMPLETE');
