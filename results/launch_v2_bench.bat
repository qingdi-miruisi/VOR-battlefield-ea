@echo off
cd "D:\harness工作\中国科学：数学(总)\算法\algorithm"
"D:\matlab_2026a\bin\matlab.exe" -batch "cd('D:\harness工作\中国科学：数学(总)\算法\algorithm\experiments'); run_v2_now(); disp('BENCH_V2_DONE');" > results\v2_bench_log.txt 2>&1
