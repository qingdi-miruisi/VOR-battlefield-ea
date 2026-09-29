cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('algorithms'); addpath('algorithms\utils');
p = OfficialProblem('MaF14', 3, 30);
fid = fopen('results/maf14_probe3.txt','w');
% 检查 MaF14 是否有约束
try
    X0 = p.Initialization(1).decs;
    c0 = p.CalCon(X0);
    hasCon = ~isempty(c0) && size(c0,2) > 0;
    fprintf(fid, 'MaF14 hasCon=%d c0 size=[%d %d]\n', hasCon, size(c0,1), size(c0,2));
catch ME
    fprintf(fid, 'MaF14 hasCon probe FAILED: %s\n', ME.message);
end
fclose(fid);
disp('probe3 written');
