cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
fid = fopen('results/v1_vs_v2_probe.txt','w');
% V1 VOR (results/vor_bench)
f1 = 'results/vor_bench/VOR_ZDT1_s1.mat';
if exist(f1,'file'), vv1 = load(f1); fprintf(fid, 'V1 VOR ZDT1 s1: IGD=%.4f PPS=%d\n', vv1.igd, vv1.pps); end
f2 = 'results/vor_bench/VOR_LSMOP1_s1.mat';
if exist(f2,'file'), vv2 = load(f2); fprintf(fid, 'V1 VOR LSMOP1 s1: IGD=%.4f PPS=%d\n', vv2.igd, vv2.pps); end
f3 = 'results/vor_bench/VOR_LSMOP6_s1.mat';
if exist(f3,'file'), vv3 = load(f3); fprintf(fid, 'V1 VOR LSMOP6 s1: IGD=%.4f PPS=%d\n', vv3.igd, vv3.pps); end
f4 = 'results/vor_bench/VOR_MaF14_s1.mat';
if exist(f4,'file'), vv4 = load(f4); fprintf(fid, 'V1 VOR MaF14 s1: IGD=%.4f PPS=%d\n', vv4.igd, vv4.pps); end
f5 = 'results/vor_bench/VOR_CF1_s1.mat';
if exist(f5,'file'), vv5 = load(f5); fprintf(fid, 'V1 VOR CF1 s1: IGD=%.4f PPS=%d\n', vv5.igd, vv5.pps); end
f6 = 'results/vor_bench/VOR_DTLZ2_300D_s1.mat';
if exist(f6,'file'), vv6 = load(f6); fprintf(fid, 'V1 VOR DTLZ2_300D s1: IGD=%.4f PPS=%d\n', vv6.igd, vv6.pps); end
% EDD baseline
for ai = 1:5
    probNames = {'ZDT1','LSMOP1','LSMOP6','MaF14','CF1'};
    fn = sprintf('results/vor_bench/EDD_%s_s1.mat', probNames{ai});
    if exist(fn,'file'), ve = load(fn); fprintf(fid, 'EDD %s s1: IGD=%.4f PPS=%d\n', probNames{ai}, ve.igd, ve.pps); end
end
fclose(fid);
disp('probe written');
