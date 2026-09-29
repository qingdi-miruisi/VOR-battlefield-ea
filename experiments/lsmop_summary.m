% EDDV8 LSMOP 全量 30-seed IGD/HV 重算
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');

testSet = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','DTLZ2_300D_M3'};
nT = numel(testSet);

% EDDV8 文件：largascale_edd_v7/<test>_EDDV7_s<s>.mat
eddV8IGD = nan(1,nT); eddV8HV = nan(1,nT);
for p = 1:nT
    igd = nan(1,30); hv = nan(1,30);
    for s = 1:30
        fn = ['results\largascale_edd_v7\' testSet{p} '_EDDV7_s' num2str(s) '.mat'];
        if isfile(fn)
            L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV;
        end
    end
    eddV8IGD(p) = median(igd(~isnan(igd))); eddV8HV(p) = median(hv(~isnan(hv)));
end

% SOTA（目录 largescale_extended/<ALG>，文件名 <ALG>_<test>_s<s>.mat）
function mIGD = loadSota(algDir, testSet, nT)
    mIGD = nan(1,nT);
    for p = 1:nT
        igd = nan(1,30);
        for s = 1:30
            fn = ['results\largescale_extended\' algDir '\' algDir '_' testSet{p} '_s' num2str(s) '.mat'];
            if isfile(fn)
                L = load(fn); igd(s) = L.out.IGD;
            end
        end
        mIGD(p) = median(igd(~isnan(igd)));
    end
end
fdseaIGD = loadSota('FDSEA', testSet, nT);
gtsfIGD  = loadSota('GDVTSF', testSet, nT);
ibIGD    = loadSota('MOEA-IB', testSet, nT);

% 旧 EDD（largescale_final/EDD，文件名 EDD_<test>_s<s>.mat）
oldIGD = nan(1,nT);
for p = 1:nT
    igd = nan(1,30);
    for s = 1:30
        fn = ['results\largescale_final\EDD\EDD_' testSet{p} '_s' num2str(s) '.mat'];
        if ~isfile(fn)
            fn = ['results\largescale_final\EDD\' testSet{p} '_EDD_s' num2str(s) '.mat'];
        end
        if isfile(fn)
            L = load(fn); igd(s) = L.out.IGD;
        end
    end
    oldIGD(p) = median(igd(~isnan(igd)));
end

% 诊断
fprintf('SOTA file check:\n');
f1 = 'results\largescale_extended\FDSEA\FDSEA_LSMOP1_s1.mat';
fprintf('  FDSEA LSMOP1_s1 found=%d IGD=%.4g\n', double(isfile(f1)), load(f1).out.IGD);
f2 = 'results\largescale_final\EDD\EDD_LSMOP1_s1.mat';
if ~isfile(f2), f2 = 'results\largescale_final\EDD\LSMOP1_EDD_s1.mat'; end
fprintf('  oldEDD LSMOP1_s1 file=%s found=%d\n', f2, double(isfile(f2)));

fprintf('\n=== EDDV8 vs SOTA vs oldEDD LSMOP IGD medians (30 seeds) ===\n');
for p = 1:nT
    fprintf('%-14s EDDV8=%.4g oldEDD=%.4g FDSEA=%.4g GDVTSF=%.4g MOEAIB=%.4g\n', ...
            testSet{p}, eddV8IGD(p), oldIGD(p), fdseaIGD(p), gtsfIGD(p), ibIGD(p));
end
