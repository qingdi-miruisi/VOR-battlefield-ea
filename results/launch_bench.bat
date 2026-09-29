@echo off
D:\matlab_2026a\bin\matlab.exe -batch "cd('D:\harness工作\中国科学：数学(总)\算法\algorithm'); addpath('experiments'); vor_bench_bg(); disp('BENCH DONE')" > results\vor_bench_log.txt 2>&1
exit /b
