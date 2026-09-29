cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes;
if exist('results/vor2_bench','dir')
    rmdir('results/vor2_bench','s');
end
mkdir('results/vor2_bench');
run_vor2_bench();
aggregate_vor2();
disp('ALL_DONE');
