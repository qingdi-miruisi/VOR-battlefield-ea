% LSMOP 12-alg Friedman 重算：EDDV8 替换旧 EDD 列
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');

testSet = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','DTLZ2_300D_M3'};
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

v8   = loadAlg('largascale_edd_v7\{test}_EDDV7_s{s}.mat', testSet, nT);
old  = loadAlg('largescale_final\EDD\EDD_{test}_s{s}.mat', testSet, nT);
fd   = loadAlg('largescale_extended\FDSEA\FDSEA_{test}_s{s}.mat', testSet, nT);
gt   = loadAlg('largescale_extended\GDVTSF\GDVTSF_{test}_s{s}.mat', testSet, nT);
ib   = loadAlg('largescale_extended\MOEA-IB\MOEA-IB_{test}_s{s}.mat', testSet, nT);

fprintf('valid cols: V8=%d old=%d FD=%d GT=%d IB=%d\n', ...
    sum(~isnan(v8)), sum(~isnan(old)), sum(~isnan(fd)), sum(~isnan(gt)), sum(~isnan(ib)));

% 5-alg Friedman IGD
allIGD = [old; v8; fd; gt; ib];
names = {'oldEDD','EDDV8','FDSEA','GDVTSF','MOEAIB'};
nAlg = 5;
fIGD = zeros(nAlg, nT);
for p = 1:nT
    vals = allIGD(:,p);
    valid = ~isnan(vals);
    nV = sum(valid);
    if nV < 3, continue; end
    vSub = vals(valid);
    [sv, ov] = sort(vSub, 'ascend');
    ranks = zeros(nV,1);
    i = 1;
    while i <= nV
        j = i;
        while j < nV && sv(j+1) == sv(j), j = j+1; end
        avgR = (i+j)/2;
        for k = i:j, ranks(ov(k)) = avgR; end
        i = j+1;
    end
    pos = find(valid);
    for m = 1:nV, fIGD(pos(m),p) = ranks(m); end
end
meanR = mean(fIGD, 2, 'omitnan');
[~, order] = sort(meanR);
fprintf('\n=== 5-alg LSMOP Friedman IGD meanRank ===\n');
for a = 1:nAlg
    if isnan(meanR(order(a)))
        fprintf('  ?: %s (NaN)\n', names{order(a)});
    else
        fprintf('  rank%d: %s (%.3f)\n', a, names{order(a)}, meanR(order(a)));
    end
end
