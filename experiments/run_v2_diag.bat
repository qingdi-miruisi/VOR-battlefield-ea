@echo off
cd "D:\harness工作\中国科学：数学(总)\算法\algorithm"
"D:\matlab_2026a\bin\matlab.exe" -batch "cd('D:\harness工作\中国科学：数学(总)\算法\algorithm'); addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official'); addpath('problems_official\LSMOP'); addpath('algorithms'); addpath('algorithms\utils'); clear classes; vor2_lsmop6_150(); vor2_diag_two(); disp('DIAG_DONE');" > "results\v2_diag_run.log" 2>&1
echo DIAG_LAUNCHED > "results\v2_diag_status.txt"
