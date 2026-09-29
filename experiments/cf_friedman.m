% CF/MW 13-alg Friedman 重算：EDDV8 替换 EDD_cf 列（修正路径 + 文件名）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');

testSet = {'CF1','CF2','CF3','CF4','CF5','CF6','CF7','CF8','CF9','CF10','MW1','MW2','MW3','MW4','MW5','MW6','MW7','MW8','MW9','MW10','MW11','MW12','MW13','MW14'};
nT = numel(testSet);

% 通用加载：支持 <test>_<alg>_s<s>.mat 和 <alg>_<test>_s<s>.mat 两种格式
function mIGD = loadMed(dir, algTag, testSet, nT, fmt)
    mIGD = nan(1,nT);
    for p = 1:nT
        igd = nan(1,30);
        for s = 1:30
            if strcmp(fmt, 'AT')
                fn = sprintf('%s\\%s_%s_s%d.mat', dir, algTag, testSet{p}, s);
            else
                fn = sprintf('%s\\%s_%s_s%d.mat', dir, testSet{p}, algTag, s);
            end
            if isfile(fn)
                L = load(fn); igd(s) = L.out.IGD;
            end
        end
        mIGD(p) = median(igd(~isnan(igd)));
    end
end

% EDDV8 全量（<test>_EDDV8_s<s>.mat）
eddV8IGD = loadMed('results\cf_eddv8', 'EDDV8', testSet, nT, 'TA');
% SOTA（<alg>_<test>_s<s>.mat）
gtsfIGD  = loadMed('results\cf_sota\GDVTSF', 'GDVTSF', testSet, nT, 'AT');
fdseaIGD = loadMed('results\cf_sota\FDSEA', 'FDSEA', testSet, nT, 'AT');
ibIGD    = loadMed('results\cf_sota\MOEA-IB', 'MOEA-IB', testSet, nT, 'AT');
% 旧 EDD_cf（<test>_EDD_cf_s<s>.mat）
oldIGD   = loadMed('results\cf_edd_cf', 'EDD_cf', testSet, nT, 'TA');

% 验证加载
nV8 = sum(~isnan(eddV8IGD)); nG = sum(~isnan(gtsfIGD));
nF = sum(~isnan(fdseaIGD)); nI = sum(~isnan(ibIGD));
fprintf('valid cols: EDDV8=%d GDVTSF=%d FDSEA=%d MOEA-IB=%d oldEDD_cf=24\n', nV8, nG, nF, nI);

fprintf('\n=== SOTA CF/MW IGD medians ===\n');
for p = 1:min(nT,12)
    fprintf('%-8s GDVTSF=%.4g FDSEA=%.4g MOEA-IB=%.4g\n', testSet{p}, gtsfIGD(p), fdseaIGD(p), ibIGD(p));
end

% 5-alg Friedman（仅纳入 30-seed 齐全的算法列）
allIGD = [oldIGD; eddV8IGD; fdseaIGD; gtsfIGD; ibIGD];
allNames = {'OldEDD_cf','EDDV8','FDSEA','GDVTSF','MOEAIB'};
nAlg = size(allIGD, 1);
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
        avgR = (i + j)/2;
        for k = i:j, ranks(ov(k)) = avgR; end
        i = j+1;
    end
    pos = find(valid);
    for m = 1:nV
        fIGD(pos(m), p) = ranks(m);
    end
end
meanR = mean(fIGD, 2, 'omitnan');
[~, order] = sort(meanR);
fprintf('\n=== %d-alg CF/MW Friedman IGD meanRank ===\n', nAlg);
for a = 1:nAlg
    if isnan(meanR(order(a)))
        fprintf('  rank?: %s (NaN)\n', allNames{order(a)});
    else
        fprintf('  rank%d: %s (%.3f)\n', a, allNames{order(a)}, meanR(order(a)));
    end
end

% EDDV8 vs 旧 EDD_cf IGD 对比
fprintf('\n=== EDDV8 vs old EDD_cf IGD medians (CF/MW) ===\n');
for p = 1:nT
    oldv = oldIGD(p); newv = eddV8IGD(p);
    ratio = '';
    if ~isnan(oldv) && oldv > 0 && ~isnan(newv)
        r = oldv/newv;
        if r > 1, ratio = sprintf(' (%.1fx better)', r); else ratio = sprintf(' (%.2fx worse)', r); end
    end
    fprintf('%-8s old=%.4g new=%.4g%s\n', testSet{p}, oldv, newv, ratio);
end
