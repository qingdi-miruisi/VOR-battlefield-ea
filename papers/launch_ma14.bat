@echo off
cd /d "D:\harness工作\中国科学：数学(总)\算法\algorithm"
start /b "ma14_bench" D:\matlab_2026a\bin\matlab.exe -batch "addpath(''experiments''); ma14_bg(); disp(''MA14 BENCH DONE'')" > results\ma14_log.txt 2>&1
exit
