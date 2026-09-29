%% launch_v5_bg.m — 通过独立 MATLAB -batch 进程跑 VOR-v5 全量基准（脱离 MCP）
% 用法：在 MATLAB 中运行本脚本，或用 MATLAB 的 system 启动
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
% 生成 bat（bat 内部调用 matlab -batch 运行 bench_v5_runner.m）
batContent = ['@echo off\r\n', ...
    'cd /d "D:\harness工作\中国科学：数学(总)\算法\algorithm"\r\n', ...
    'call "D:\matlab_2026a\bin\matlab.exe" -batch "addpath(''experiments''); addpath(''problems''); addpath(''problems\wfg_toolbox''); addpath(''problems_official''); addpath(''problems_official\MaF''); addpath(''problems_official\LSMOP''); addpath(''problems_official\CF''); addpath(''problems_official\DTLZ''); addpath(''algorithms''); addpath(''algorithms\utils''); clear classes; cd(''D:\harness工作\中国科学：数学(总)\算法\algorithm''); run_vor_fast4(); run_vor_d300(); aggregate_vor2(); disp(''ALL_DONE'');'' > results\v2_bench_v5.log 2>&1\r\n'];
fid = fopen('experiments/run_v2_bench_v5_inner.bat','w');
fwrite(fid, batContent, 'text');
fclose(fid);
disp('inner bat written');
% 启动独立后台进程（脱离当前 MATLAB）
r = system('start /min cmd /c experiments\run_v2_bench_v5_inner.bat');
disp(['launch rc=' num2str(r)]);
