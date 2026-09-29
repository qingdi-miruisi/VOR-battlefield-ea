% CF/MW 最终数据汇总：EDDV8 (cf_edd_cf 目录) 全量 IGD/HV
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');

cfV8 = 'results\cf_edd_cf';
testSet = {'CF1','CF2','CF3','CF4','CF5','CF6','CF7','CF8','CF9','CF10','MW1','MW2','MW3','MW4','MW5','MW6','MW7','MW8','MW9','MW10','MW11','MW12','MW13','MW14'};
nT = numel(testSet);
eddIGD = nan(1,nT); eddHV = nan(1,nT);
for p = 1:nT
    igd = nan(1,30); hv = nan(1,30); nFound = 0;
    for s = 1:30
        fn = sprintf('%s/%s_EDD_cf_s%d.mat', cfV8, testSet{p}, s);
        if isfile(fn)
            L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV; nFound = nFound + 1;
        end
    end
    eddIGD(p) = median(igd(~isnan(igd))); eddHV(p) = median(hv(~isnan(hv)));
    fprintf('%-8s found=%d IGD=%.4g HV=%.4g\n', testSet{p}, nFound, eddIGD(p), eddHV(p));
end
