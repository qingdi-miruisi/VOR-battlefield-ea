cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('algorithms'); addpath('algorithms\utils');
p = OfficialProblem('MaF14', 3, 30);
fid = fopen('results/maf14_probe2.txt','w');
fprintf(fid, 'MaF14: nVar=%d nObj=%d\n', p.nVar, p.nObj);
% 直接调 EDD apdGeneration 看 reshape 是否报错
try
    e = EDD(100, 10, 1);
    [V, ~] = UniformPoint(100, p.nObj, 'NBI');
    V2 = reshape(V, 100, 2);
    fprintf(fid, 'EDD V reshape to 2 cols: OK, V2 size %dx%d\n', size(V2,1), size(V2,2));
catch ME
    fprintf(fid, 'EDD V reshape to 2 cols FAILED: %s\n', ME.message);
end
fclose(fid);
disp('probe written');
