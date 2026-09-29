cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('algorithms'); addpath('algorithms\utils');
p = OfficialProblem('MaF14', 3, 30);
fid = fopen('results/maf14_dim.txt','w');
fprintf(fid, 'MaF14: nVar=%d nObj=%d\n', p.nVar, p.nObj);
fclose(fid);
disp('probe written');
