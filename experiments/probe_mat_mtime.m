cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
now = datestr(now,'yyyy-mm-dd HH:MM:SS');
f1 = 'results/vor2_bench/VOR_MaF14_s1.mat';
f2 = 'results/vor2_bench/VOR_LSMOP6_s1.mat';
d1 = dir(f1); d2 = dir(f2);
fid = fopen('results/v5_mtime.txt','w');
fprintf(fid, 'current_time: %s\n', now);
if ~isempty(d1)
    fprintf(fid, 'VOR_MaF14_s1.mat mod: %s bytes: %d\n', datestr(d1(1).date), d1(1).bytes);
else
    fprintf(fid, 'VOR_MaF14_s1.mat NOT FOUND\n');
end
if ~isempty(d2)
    fprintf(fid, 'VOR_LSMOP6_s1.mat mod: %s bytes: %d\n', datestr(d2(1).date), d2(1).bytes);
else
    fprintf(fid, 'VOR_LSMOP6_s1.mat NOT FOUND\n');
end
fclose(fid);
disp('mtime probe written');
