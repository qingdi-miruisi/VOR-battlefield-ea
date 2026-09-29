% EDDV8 最终数据汇总：合并 Friedman（含 EDDV8 列）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
testNames = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','DTLZ2_300D_M3'};
nT = numel(testNames);

eddDir = 'results/largascale_edd_v7';
oldDir = 'results/largescale_final/EDD';
fdseaDir = 'results/largescale_extended/FDSEA';
gtsfDir  = 'results/largescale_extended/GDVTSF';
ibDir    = 'results/largescale_extended/MOEA-IB';

% EDDV8 文件名: <testName>_EDDV7_s<s>.mat
eddIGD = nan(1,nT); eddHV = nan(1,nT);
for p = 1:nT
    igd = nan(1,30); hv = nan(1,30);
    for s = 1:30
        fn = sprintf('%s/%s_EDDV7_s%d.mat', eddDir, testNames{p}, s);
        if isfile(fn), L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV; end
    end
    eddIGD(p) = median(igd(~isnan(igd))); eddHV(p) = median(hv(~isnan(hv)));
end

% 其它算法文件名: <prefix>_<testName>_s<s>.mat
function [mIGD, mHV] = medBoth(dir, prefix, testNames, nT)
    mIGD = zeros(1,nT); mHV = zeros(1,nT);
    for p = 1:nT
        igd = nan(1,30); hv = nan(1,30);
        for s = 1:30
            fn = sprintf('%s/%s_%s_s%d.mat', dir, prefix, testNames{p}, s);
            if isfile(fn), L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV; end
        end
        mIGD(p) = median(igd(~isnan(igd))); mHV(p) = median(hv(~isnan(hv)));
    end
end
[oldIGD, oldHV] = medBoth(oldDir, 'EDD', testNames, nT);
[fdIGD,  fdHV]  = medBoth(fdseaDir, 'FDSEA', testNames, nT);
[gtIGD,  gtHV]  = medBoth(gtsfDir, 'GDVTSF', testNames, nT);
[ibIGD,  ibHV]  = medBoth(ibDir, 'MOEA-IB', testNames, nT);

fprintf('\n=== EDDV8 IGD 中位数（30 seeds）===\n');
for p = 1:nT, fprintf('%-16s IGD=%.4g HV=%.4g\n', testNames{p}, eddIGD(p), eddHV(p)); end

% 合并 Friedman（5 算法 IGD）
allIGD = [oldIGD; eddIGD; fdIGD; gtIGD; ibIGD];
allNames = {'OldEDD','EDDV8','FDSEA','GDVTSF','MOEAIB'};
nAlg = 5;
fIGD = zeros(nAlg, nT);
for p = 1:nT
    vals = allIGD(:,p);
    [sv, ov] = sort(vals, 'ascend');
    ranks = zeros(nAlg,1);
    i = 1;
    while i <= nAlg
        j = i;
        while j < nAlg && sv(j+1) == sv(j), j = j+1; end
        avgR = (i + j)/2;
        for k = i:j, ranks(ov(k)) = avgR; end
        i = j+1;
    end
    fIGD(:,p) = ranks;
end
meanR = mean(fIGD, 2);
[~, order] = sort(meanR);
fprintf('\n=== 5-alg 合并 Friedman IGD meanRank（含 EDDV8）===\n');
for a = 1:nAlg
    fprintf('  rank%d: %s (%.3f)\n', a, allNames{order(a)}, meanR(order(a)));
end

% HV Friedman
allHV = [oldHV; eddHV; fdHV; gtHV; ibHV];
fHV = zeros(nAlg, nT);
for p = 1:nT
    vals = allHV(:,p);
    [sv, ov] = sort(vals, 'descend');
    ranks = zeros(nAlg,1);
    i = 1;
    while i <= nAlg
        j = i;
        while j < nAlg && sv(j+1) == sv(j), j = j+1; end
        avgR = (i + j)/2;
        for k = i:j, ranks(ov(k)) = avgR; end
        i = j+1;
    end
    fHV(:,p) = ranks;
end
meanRHV = mean(fHV, 2);
[~, orderH] = sort(meanRHV);
fprintf('\n=== 5-alg 合并 Friedman HV meanRank（含 EDDV8）===\n');
for a = 1:nAlg
    fprintf('  rank%d: %s (%.3f)\n', a, allNames{orderH(a)}, meanRHV(orderH(a)));
end
