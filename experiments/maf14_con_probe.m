cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('algorithms'); addpath('algorithms\utils');
p = OfficialProblem('MaF14', 3, 30);
fid = fopen('results/maf14_con_probe.txt','w');
X0 = p.Initialization(1).decs;
c0 = p.CalCon(X0);
fprintf(fid, 'MaF14 c0 = %s\n', mat2str(c0));
% 多采几个点看约束是否恒为 0（占位约束）
for i = 1:5
    Xi = p.Initialization(1).decs;
    ci = p.CalCon(Xi);
    fprintf(fid, 'point %d c=%s\n', i, mat2str(ci));
end
fclose(fid);
disp('con probe written');
