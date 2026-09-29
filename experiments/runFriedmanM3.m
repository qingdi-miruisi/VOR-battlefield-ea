function runFriedmanM3()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments');
    clear classes; clear IGD HV;
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear IGD HV;
    friedman_m3;
end
