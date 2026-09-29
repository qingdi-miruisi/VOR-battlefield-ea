# HCEAV2 多目标优化器 — 交付说明

## 1. 项目结构

```
algorithm/
├── problems/           55 个问题类（ZDT/DTLZ/WFG/UF/CMO/MaF/EMO/LSMOP/CEC）
│   ├── Problem.m       统一基类（含 PlatEMO 兼容层 F/Cons/nObj/nVar）
│   ├── NDSortAll.m     向量化非支配排序（per-objective repmat，O(n·m)）
│   ├── loadFront.m     PF 生成 + .mat 缓存（fronts/ 子目录）
│   ├── IGD.m, HV.m     标准指标
│   └── fronts/         预生成的 PF .mat 缓存
├── algorithms/
│   ├── ALGORITHM.m     算法基类（统一 optimize 接口）
│   ├── NSGA2/NSGA3/MOEAD/SPEA2/SMSEMOA/RVEA/AGEMOEA/MOGWO.m  （8 个基线）
│   ├── HCEA.m          原 HCEA（APD+SMS 双机制，HV 验证切换 50/60/70%）
│   ├── HCEAV2.m        本文改进（3 项创新，详见 §2）
│   ├── HCEAV2_noEP.m / HCEAV2_noPolish.m / HCEAV2_origSwitch.m  消融变体
│   └── utils/          NDSort, CrowdingDistance, UniformPoint, pdist2, RVEA 等
├── experiments/
│   ├── run_main.m              主实验（10 算法 × 33 问题 × 30 种子，增量落盘，可续跑）
│   ├── batch_run_main.m       -batch 入口（5 批 × 6 问题）
│   ├── run_statistics.m       Friedman + Wilcoxon + Holm（支持不完整数据）
│   ├── make_figures.m         图表生成
│   ├── run_ablation.m         消融（4 变体 × 6 问题 × 10 种子）
│   └── run_sensitivity.m      灵敏度（3 popSize × 4 maxGen × 4 问题 × 10 种子）
├── results/
│   ├── main/          9900 个 .mat（10×33×30）+ stats_HV.mat + stats_IGD.mat
│   ├── ablation/      240 个 .mat（4×6×10）
│   └── sensitivity/   灵敏度数据（生成中）
├── figures/
│   ├── fig1_hv_rank.png       HV Friedman 排名
│   └── fig2_igd_rank.png      IGD Friedman 排名
└── docs/
    ├── RESULTS_HONEST_REPORT.md   诚实报告（含完整统计）
    └── paper/main.tex           （受保护，未改动）
```

## 2. HCEAV2 的 3 项创新（vs 原 HCEA）

1. **端点保护 APD**：APD 候选集生成时，若前沿端点附近（fmin 区域）无候选，强制插入 2 个
   沿坐标轴方向的小步扰动，保证 M=2 端点密度（原 HCEA 在 DTLZ 类问题上端点容易丢失）。
2. **末端多解搜索**（polishFrom=0.9G 起每 5 代）：取 HV 贡献最差的 ceil(N/20) 个点，
   每点生成 1 个定向 + 1 个随机候选，按 HV 贡献保留更优者。M≥3 用蒙特卡洛逐解贡献
   （已修复为返回完整 N 长度向量，被 ref 过滤点贡献为 0）。
3. **收敛感知切换**：在原 3 检查点（50/60/70%）基础上新增每 5 代 HV 改进率监测，
   连续 2 个 5 代窗口改进率 < 1e-3 时强制切换 APD→SMS。

## 3. 主实验结果（Friedman 平均秩，33 问题 × 30 种子）

| 指标 | 第 1 名 | 第 2 名 | HCEAV2 是否第 1 |
|------|---------|---------|----------------|
| HV   | **HCEAV2 (3.27)** | HCEA (3.30) | ✅ 是 |
| IGD  | HCEA (3.73) | **HCEAV2 (4.18)** | ❌ 否 |

- HCEAV2 对 8 个基线全部 Wilcoxon p<0.001（Holm 校正后仍显著）。
- 成功标准"IGD 和 HV 双第 1"**未完全达成**：HV 第 1 ✅，IGD 第 2 ❌。

## 4. 消融实验（4 变体 × 6 问题 × 10 种子）
见 `results/ablation/`。主要发现：
- 关闭末端搜索（noPolish）在 WFG 上 IGD 略升（0.340 vs 0.350，DTLZ3 106.9 vs 103.4）。
- 其余变体在 ZDT/DTLZ 上 IGD 接近（说明端点保护与切换机制在 2 目标上贡献较小）。

## 5. 可复现步骤

```matlab
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm')
addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms');  addpath('algorithms\utils');

% 主实验（增量落盘，可续跑）
run_main(1, 33)

% 统计
run_statistics('results\main', 'IGD');
run_statistics('results\main', 'HV');

% 消融 / 灵敏度
run_ablation(1, 6, 10);
run_sensitivity(10);

% 图表
make_figures('results\main', 'figures');
```

## 6. 诚实声明
- 所有数据由 MATLAB R2026a 实际运行产生，无手工修改。
- HCEAV2 在 HV 上超越 HCEA 的幅度很小（平均秩差 0.03），统计上**不构成显著优势**；
  IGD 上 HCEAV2 明显逊于 HCEA（0.45）。
- 5 个最新基线（PREA/CCMO/CMOEA-CD/MOBO-OSD/many-objective）**未实现**。
- 论文素材（main.tex、README_PAPER.md、raw_data_8problems.mat）均未改动。
