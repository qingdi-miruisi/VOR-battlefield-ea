cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
a1 = exist('results/v2_bench_v5_status.txt','file');
a2 = exist('results/v2_bench_v5.log','file');
fid = fopen('results/v5_probe.txt','w');
fprintf(fid, 'status=%d log=%d\n', a1, a2);
fclose(fid);
disp('probe written');
