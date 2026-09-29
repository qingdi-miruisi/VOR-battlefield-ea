@echo off
cd "D:\harness工作\中国科学：数学(总)\算法\algorithm"
"D:\matlab_2026a\bin\matlab.exe" -batch "cd('D:\harness工作\中国科学：数学(总)\算法\algorithm'); addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\CF'); addpath('problems_official\MW'); addpath('problems_official\DTLZ'); addpath('algorithms'); addpath('algorithms\utils'); clear classes; run_vor_fast4(); run_vor_d300(); aggregate_vor2(); disp('ALL_DONE');" > "results\v2_bench_v5.log" 2>&1
echo LAUNCHED > "results\v2_bench_v5_status.txt"
