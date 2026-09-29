function make_metric_summary()
% MAKE_METRIC_SUMMARY  Build summary.xlsx (6 sheets) from raw_data.mat
DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
S = load([DIR 'raw_data.mat']);
IGD = S.IGD; HV = S.HV; nFE = S.nFE; elap = S.elap; errMsg = S.errMsg;
algos = S.algos; probName = S.probName;
[nP, nA, nS] = size(IGD);
xlsx = [DIR 'summary.xlsx'];
if exist(xlsx, 'file'), delete(xlsx); end

%% ---- Summary sheets (mean +- std) ----
hdr = cell(1, 1 + 2*nP);
hdr{1} = 'Algorithm';
for ip = 1:nP
    hdr{2*ip}     = [probName{ip} '_mean'];
    hdr{2*ip + 1} = [probName{ip} '_std'];
end
sumI = cell(nA + 1, 1 + 2*nP); sumI(1,:) = hdr;
sumH = sumI;
for ia = 1:nA
    sumI{ia+1, 1} = algos{ia}; sumH{ia+1, 1} = algos{ia};
    for ip = 1:nP
        ig = IGD(ip, ia, :); ig = ig(:);
        hv = HV(ip, ia, :);  hv = hv(:);
        sumI{ia+1, 2*ip}     = mean(ig, 'omitnan');
        sumI{ia+1, 2*ip + 1} = std(ig, 'omitnan');
        sumH{ia+1, 2*ip}     = mean(hv, 'omitnan');
        sumH{ia+1, 2*ip + 1} = std(hv, 'omitnan');
    end
end
xlswrite(xlsx, sumI, 'Summary_IGD');
xlswrite(xlsx, sumH, 'Summary_HV');

%% ---- Rank sheets ----
rhdr = cell(1, 1 + nP); rhdr{1} = 'Algorithm';
for ip = 1:nP, rhdr{ip+1} = probName{ip}; end
rI = cell(nA + 1, 1 + nP); rI(1,:) = rhdr;
rH = rI; rD = rI;
mI = zeros(nP, nA); mH = zeros(nP, nA);
for ip = 1:nP
    for ia = 1:nA
        mI(ip, ia) = mean(IGD(ip, ia, :), 'omitnan');
        mH(ip, ia) = mean(HV(ip, ia, :), 'omitnan');
    end
end
for ia = 1:nA
    rI{ia+1, 1} = algos{ia}; rH{ia+1, 1} = algos{ia}; rD{ia+1, 1} = algos{ia};
    for ip = 1:nP
        [~, oI] = sort(mI(ip, :)); rankI = zeros(1, nA); for k = 1:nA, rankI(oI(k)) = k; end
        [~, oH] = sort(mH(ip, :), 'descend'); rankH = zeros(1, nA); for k = 1:nA, rankH(oH(k)) = k; end
        rI{ia+1, ip+1} = rankI(ia);
        rH{ia+1, ip+1} = rankH(ia);
        rD{ia+1, ip+1} = rankI(ia) - rankH(ia);   % positive: IGD rank worse than HV rank
    end
end
xlswrite(xlsx, rI, 'Rank_IGD');
xlswrite(xlsx, rH, 'Rank_HV');
xlswrite(xlsx, rD, 'Rank_Difference');

%% ---- Raw data sheet ----
raw = cell(nP*nA*nS + 1, 8);
raw(1,:) = {'Problem', 'Algorithm', 'Seed', 'IGD', 'HV', 'nFE', 'Elapsed_s', 'Error'};
row = 1;
for ip = 1:nP
    for ia = 1:nA
        for s = 1:nS
            row = row + 1;
            raw(row, :) = {probName{ip}, algos{ia}, s, IGD(ip,ia,s), HV(ip,ia,s), ...
                           nFE(ip,ia,s), elap(ip,ia,s), errMsg{ip,ia,s}};
        end
    end
end
xlswrite(xlsx, raw, 'Raw_Data');

%% ---- Config sheet ----
cfg = {
 'Config', '';
 'popSize', 100;
 'maxGen', '200 (MOGWO: 500)';
 'seeds', '1..30';
 'problems', 'ZDT1(30) ZDT2(30) ZDT3(30) DTLZ2(12,2) DTLZ7(12,2)';
 'IGD ref', 'problem.ParetoFront(500)';
 'HV ref', 'max(problem.ParetoFront(500))*1.1 (per problem, identical across algorithms)';
 'HV method', 'exact 2D staircase';
};
xlswrite(xlsx, cfg, 'Config');

%% ---- console report ----
fprintf('=== IGD mean ===\n');
for ia = 1:nA
    fprintf('%-8s', algos{ia});
    for ip = 1:nP, fprintf(' %.5f', mI(ip, ia)); end
    fprintf('\n');
end
fprintf('=== HV mean ===\n');
for ia = 1:nA
    fprintf('%-8s', algos{ia});
    for ip = 1:nP, fprintf(' %.5f', mH(ip, ia)); end
    fprintf('\n');
end
nErr = sum(~cellfun(@isempty, errMsg), 'all');
fprintf('errors: %d of %d runs\n', nErr, nP*nA*nS);
fprintf('total elapsed: %.1f s\n', sum(elap, 'all', 'omitnan'));
fprintf('wrote %s\n', xlsx);
end
