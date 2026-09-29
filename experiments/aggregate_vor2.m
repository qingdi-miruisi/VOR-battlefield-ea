%% aggregate_vor2.m — 从 results/vor2_bench/*.mat 聚合 VOR-v2 全量基准
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
algoList = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
probList = {'MaF14','LSMOP6','CF1','DTLZ2_300D','ZDT1','LSMOP1'};
nSeed = 10;
resDir = 'results/vor2_bench';

fid = fopen('aggregate_raw.txt','w');
fprintf(fid, '=== VOR-v2 全量基准 (10 seeds, 6 problems, 6 algos) ===\n\n');
fprintf(fid, '%-8s %-14s %14s %12s %10s\n','Algo','Problem','IGD(mean+std)','HV(mean+std)','PPS(mean)');
fprintf(fid, '%s\n', repmat('-', 1, 60));
for ai = 1:numel(algoList)
    for pi = 1:numel(probList)
        aName = algoList{ai}; pName = probList{pi};
        igdV = []; hvV = []; ppV = [];
        for s = 1:nSeed
            fn = sprintf('%s/%s_%s_s%d.mat', resDir, aName, pName, s);
            if exist(fn,'file')
                S = load(fn);
                igdV(end+1) = S.igd;
                if isfield(S,'hv') && ~isempty(S.hv), hvV(end+1) = S.hv; else, hvV(end+1) = NaN; end
                ppV(end+1) = S.pps;
            end
        end
        if ~isempty(igdV)
            hvMean = nanmean(hvV); hvStd = nanstd(hvV);
            fprintf(fid, '%-8s %-14s %6.4f+%06.4f %6.4f+%06.4f %6.1f\n', ...
                aName, pName, mean(igdV), std(igdV), hvMean, hvStd, mean(ppV));
        else
            fprintf(fid, '%-8s %-14s (no data)\n', aName, pName);
        end
    end
    fprintf(fid, '\n');
end
% IGD ranking per problem
fprintf(fid, '=== 每题 IGD 排名 (1=最优) ===\n');
for pi = 1:numel(probList)
    pName = probList{pi};
    igdRank = cell(1, numel(algoList)); igdMean = zeros(1, numel(algoList));
    for ai = 1:numel(algoList)
        aName = algoList{ai};
        igdV = [];
        for s = 1:nSeed
            fn = sprintf('%s/%s_%s_s%d.mat', resDir, aName, pName, s);
            if exist(fn,'file')
                S = load(fn); igdV(end+1) = S.igd;
            end
        end
        igdMean(ai) = mean(igdV);
    end
    [~, ord] = sort(igdMean, 'ascend');
    fprintf(fid, '%s: ', pName);
    for ai = 1:numel(algoList)
        fprintf(fid, '%s=%d位(%s) ', algoList{ai}, rank(ai,ord), 'IGD');
    end
    fprintf(fid, '\n');
end
fclose(fid);
disp('aggregate_raw.txt written');
function rk = rank(idx, ord)
    for k = 1:numel(ord)
        if ord(k) == idx, rk = k; return; end
    end
    rk = 0;
end
