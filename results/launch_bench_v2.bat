@echo off
cd /d "D:\harness工作\中国科学：数学(总)\算法\algorithm"
start /b "vor_bench_v2" D:\matlab_2026a\bin\matlab.exe -batch "addpath('experiments'); vor_bench_bg(); disp('BENCH DONE')" > results\vor_bench_log2.txt 2>&1
exit
