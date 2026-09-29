# 进度快照（关机前记录，2026-09-17）

## 当前任务：8 问题扩展（Task A/B/C/D）

### 已完成
- [x] Task A：MOGWO 统一 200 代，5 个 2 目标问题 x 30 种子 -> mogwo_200gen.mat（全部 30/30）
- [x] 新增 problems/DTLZ1.m（PlatEMO master 原版 CalObj/GetOptimum）
- [x] HCEA.m 增加 M>=3 支持：calHV/hvContrib/机制B deltaS 用蒙特卡洛（calHVM, HYPE k=1, nSample=1000）；M=2 精确路径位级不变（10 次重跑 max diff=0）
- [x] 备份：algorithms/_archive/HCEA_main_backup_M3v2_20260917.m、HCEA_main_backup_M3_20260917.m、HCEA_main_backup_20260917.m
- [x] 修复 alpha bug：calHVM/HVMC 的 alpha = zeros(1,N)（原 zeros(1,min(k,N)) 在 dS>1 时越界）

### 进行中
- [ ] Task B：9 算法 x 3 目标（DTLZ1/DTLZ2/DTLZ7 @ 12,3）x 30 种子 -> m3_raw_data.mat
  - 状态：未开始（坏数据已删，从头重跑）
  - runner：docs/results/metric_disagreement/run_m3.m（run_m3(algIdx, probIdx, seeds)，断点续跑）
  - algIdx: 1=NSGA2 2=NSGA3 3=MOEAD 4=SPEA2 5=SMSEMOA 6=RVEA 7=AGEMOEA 8=MOGWO 9=HCEA
  - probIdx: 1=DTLZ1_M3 2=DTLZ2_M3 3=DTLZ7_M3
  - 顺序：快算法(1,2,3,4,6,7) -> HCEA(9) -> SMSEMOA(5) -> MOGWO(8, 约45s/次, 2种子/块)
  - HV：基线 HVMC(nSample=10000)，HCEA 用 HCEA.calHV(nSample=1000)
  - 注意：M=3 时 HVMC/calHVM 消耗全局随机流（unifrnd），蒙特卡洛固有噪声，报告中如实说明

### 待办
- [ ] Task C：合并 8 问题 -> raw_data_8problems.mat；重算 Friedman/Wilcoxon/Nemenyi CD（k=9,N=8, CD 约 4.25）；更新 summary.xlsx、statistical_tests.xlsx、paper tables/figures、README_PAPER.md
- [ ] Task D：DTLZ1 收敛自检（IGD>0.5 标注）、HCEA M=3 切换比例、MOGWO M=3 坍缩检查（uniqueRows_M3）
- [ ] 最终报告

## 断点续跑方法
- Task B：addpath('...\docs\results\metric_disagreement'); run_m3(algIdx, probIdx, seeds)；已完成条目自动跳过。
- Task A 已完成勿重跑；其余 8 算法 2 目标数据沿用 raw_data.mat，不要动。
