% 生成 12-alg LSMOP IGD 表（EDDV8 替换旧 EDD 列）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');

testSet = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9'};
nT = numel(testSet);

function mIGD = loadAlg(fnPat, testSet, nT)
    mIGD = nan(1,nT);
    for p = 1:nT
        igd = nan(1,30);
        for s = 1:30
            fn = ['results\' fnPat];
            fn = strrep(fn, '{test}', testSet{p});
            fn = strrep(fn, '{s}', num2str(s));
            if isfile(fn)
                L = load(fn); igd(s) = L.out.IGD;
            end
        end
        mIGD(p) = median(igd(~isnan(igd)));
    end
end

% 12-alg 数据
v8     = loadAlg('largascale_edd_v7\{test}_EDDV7_s{s}.mat', testSet, nT);
moead  = loadAlg('largescale_final\MOEAD\MOEAD_{test}_s{s}.mat', testSet, nT);
mogwo  = loadAlg('largescale_final\MOGWO\MOGWO_{test}_s{s}.mat', testSet, nT);
nsga2  = loadAlg('largescale_final\NSGA2\NSGA2_{test}_s{s}.mat', testSet, nT);
nsga3  = loadAlg('largescale_final\NSGA3\NSGA3_{test}_s{s}.mat', testSet, nT);
rvea   = loadAlg('largescale_final\RVEA\RVEA_{test}_s{s}.mat', testSet, nT);
smsemoa= loadAlg('largescale_final\SMSEMOA\SMSEMOA_{test}_s{s}.mat', testSet, nT);
spea2  = loadAlg('largescale_final\SPEA2\SPEA2_{test}_s{s}.mat', testSet, nT);
agemo  = loadAlg('largescale_final\AGEMOEA\AGEMOEA_{test}_s{s}.mat', testSet, nT);
fd     = loadAlg('largescale_extended\FDSEA\FDSEA_{test}_s{s}.mat', testSet, nT);
gt     = loadAlg('largescale_extended\GDVTSF\GDVTSF_{test}_s{s}.mat', testSet, nT);
ib     = loadAlg('largescale_extended\MOEA-IB\MOEA-IB_{test}_s{s}.mat', testSet, nT);

% 打印 12-alg 数据矩阵
allIGD = [v8; moead; mogwo; nsga2; nsga3; rvea; smsemoa; spea2; agemo; fd; gt; ib];
names = {'EDDV8','MOEAD','MOGWO','NSGA2','NSGA3','RVEA','SMSEMOA','SPEA2','AGEMOEA','FDSEA','GDVTSF','MOEA-IB'};

fprintf('%-10s', 'Algo');
for p = 1:nT, fprintf('%-10s', testSet{p}); end
fprintf('\n');
for a = 1:12
    fprintf('%-10s', names{a});
    for p = 1:nT
        if isnan(allIGD(a,p)), fprintf('%-10s', 'NaN'); else fprintf('%-10.3f', allIGD(a,p)); end
    end
    fprintf('\n');
end

% 逐列 rank（12-alg）
ranks = zeros(12, nT);
for p = 1:nT
    vals = allIGD(:,p);
    valid = ~isnan(vals);
    nV = sum(valid);
    if nV < 3, continue; end
    vSub = vals(valid);
    [sv, ov] = sort(vSub, 'ascend');
    r = zeros(nV,1);
    i = 1;
    while i <= nV
        j = i;
        while j < nV && sv(j+1) == sv(j), j = j+1; end
        avgR = (i+j)/2;
        for k = i:j, r(ov(k)) = avgR; end
        i = j+1;
    end
    pos = find(valid);
    for m = 1:nV, ranks(pos(m),p) = r(m); end
end
fprintf('\n');
fprintf('%-10s', 'Algo');
for p = 1:nT, fprintf('%-10s', testSet{p}); end
fprintf('\n');
for a = 1:12
    fprintf('%-10s', names{a});
    for p = 1:nT
        if isnan(ranks(a,p)), fprintf('%-10s', '---'); else fprintf('%-10.0f', ranks(a,p)); end
    end
    fprintf('\n');
end

% mean rank
meanR = mean(ranks, 2, 'omitnan');
[~, order] = sort(meanR);
fprintf('\n=== 12-alg LSMOP Friedman IGD meanRank ===\n');
for a = 1:12
    fprintf('  rank%d: %s (%.3f)\n', a, names{order(a)}, meanR(order(a)));
end
