% 生成 12-alg LSMOP PPS 数据（EDDV8 旧 EDD 相同）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');
testSet = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','DTLZ2_300D_M3'};
nT = numel(testSet);
function mPPS = loadPPS(fnPat, testSet, nT)
    mPPS = nan(1,nT);
    for p = 1:nT
        pps = nan(1,30);
        for s = 1:30
            fn = ['results\' fnPat];
            fn = strrep(fn, '{test}', testSet{p});
            fn = strrep(fn, '{s}', num2str(s));
            if isfile(fn)
                L = load(fn); pps(s) = L.out.PPS;
            end
        end
        mPPS(p) = mean(pps(~isnan(pps)));
    end
end
v8 = loadPPS('largascale_edd_v7\{test}_EDDV7_s{s}.mat', testSet, nT);
old = loadPPS('largescale_final\EDD\EDD_{test}_s{s}.mat', testSet, nT);
fprintf('EDDV8 PPS means:\n');
for p = 1:nT, fprintf('  %-14s %.1f\n', testSet{p}, v8(p)); end
fprintf('oldEDD PPS means:\n');
for p = 1:nT, fprintf('  %-14s %.1f\n', testSet{p}, old(p)); end
