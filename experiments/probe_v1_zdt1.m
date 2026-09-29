cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
fid = fopen('results/v1_zdt1_probe.txt','w');
f1 = 'results/vor_bench/VOR_ZDT1_s1.mat';
if exist(f1,'file')
    vv1 = load(f1);
    fprintf(fid, 'V1 VOR ZDT1 s1: IGD=%.4f PPS=%d\n', vv1.igd, vv1.pps);
else
    fprintf(fid, 'V1 VOR ZDT1 s1: file not found\n');
end
f2 = 'results/vor_bench/EDD_ZDT1_s1.mat';
if exist(f2,'file')
    vv2 = load(f2);
    fprintf(fid, 'V1 EDD ZDT1 s1: IGD=%.4f PPS=%d\n', vv2.igd, vv2.pps);
end
fclose(fid);
disp('probe written');
