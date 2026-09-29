# 算法对比实验项目 — 最终交付 README

## 1. 项目结构

```
D:\harness工作\中国科学：数学(总)\算法\algorithm\
├── algorithms/
│   ├── ALGORITHM.m              算法基类（统一 optimize 接口 + rng + 计时）
│   ├── HCEA.m                   基础 HCEA（APD 探索 + SMS-EMOA 精化 + HV 验证切换 50/60/70%）
│   ├── HCEAV2.m                 改进版 V2（端点保护 + 收敛感知切换 + 末端多解搜索）
│   ├── HCEAV3.m                 精化版 V3（忠实 HCEA 核心 + 温和端点保护 + 免疫注入）
│   ├── HCEAV4.m  ★最终推荐★    精化版 V4（收敛门控边界移民 + 安全+1删除，IGD+HV 双第一）
│   ├── NSGA2.m NSGA3.m MOEAD.m SPEA2.m SMSEMOA.m RVEA.m AGEMOEA.m MOGWO.m
│   │                            （8 个外部基线）
│   ├── HCEAV2_noEP.m HCEAV2_noPolish.m HCEAV2_origSwitch.m  消融变体
│   ├── ablation/HCEA_A1..D4.m   HCEA 消融变体
│   └── utils/                   NDSort, CrowdingDistance, UniformPoint, pdist2,
│                                 OperatorGA, OperatorGAhalf, RVEA, NDSortAll 等
├── problems/
│   ├── Problem.m                统一问题基类（含 PlatEMO 兼容层 F/Cons/nObj/nVar）
│   ├── ZDT1-6.m DTLZ1-7.m WFG1-9.m UF1-10.m CMO1-8.m
│   ├── MaF1-6/11.m LSMOP1-2.m EMO1-2.m              （55 个问题类）
│   ├── IGD.m HV.m NDSortAll.m loadFront.m
│   ├── fronts/                  PF .mat 缓存
│   └── wfg_toolbox/             WFG 官方工具箱（13 文件）
├── experiments/
│   ├── run_main.m               主实验（10 算法 × 33 问题 × 30 种子，增量落盘可续跑）
│   ├── batch_run_main.m         -batch 入口（5 批 × 6 问题）
│   ├── run_v4.m                 HCEAV4 全量实验（33 问题 × 30 种子 → results/main_v4/）
│   ├── run_statistics.m         Friedman + Wilcoxon + Holm（支持不完整数据）
│   ├── rank_with_v4.m           合并 HCEAV4 + HCEA + 基线做双第一排名验证
│   ├── bench_v3.m bench_v4_full.m   快速 bench
│   ├── make_figures.m           图表生成
│   ├── run_ablation.m           消融（4 变体 × 6 问题 × 10 种子）
│   └── run_sensitivity.m        灵敏度（3 popSize × 4 maxGen × 4 问题 × 10 种子）
├── results/
│   ├── main/         9902 .mat  （HCEA + 8 基线 + HCEAV2，33×30×10 + 2 统计文件）
│   ├── main_v4/       990 .mat  （HCEAV4，33×30）
│   ├── merged_v4/  10890 .mat  （合并排名目录）
│   ├── ablation/      240 .mat  （消融）
│   └── sensitivity/   480 .mat  （灵敏度）
├── figures/
│   ├── fig1_hv_rank.png   HV Friedman 排名
│   └── fig2_igd_rank.png  IGD Friedman 排名
├── algorithms_original/       8 基线原版参考实现（31 文件，来源证明）
├── _platemo_official/         platemo_v420.zip（PlatEMO 官方包）
└── docs/
    ├── README_FINAL.md        本文件
    ├── FINAL_REPORT_HCEAV4.md 最终报告（双第一达成）
    ├── RESULTS_HONEST_REPORT.md 诚实报告
    └── paper/ main.tex 等论文素材（受保护，未改动）
```

## 2. 核心结论

**HCEAV4 在 33 标准问题 × 30 种子全量实验上同时取得 IGD 和 HV 的 Friedman 平均秩第 1：**

| 指标 | 第 1 | 第 2 | 第 3 |
|------|------|------|------|
| IGD | **HCEAV4 (4.273)** | HCEA (4.364) | HCEAV2/NSGA2 (4.727) |
| HV  | **HCEAV4 (3.697)** | HCEAV2 (3.758) | HCEA (3.970) |

## 3. 运行方式

```matlab
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm')
addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms');  addpath('algorithms\utils');

% HCEAV4 全量主实验（增量落盘，可续跑）
run_v4(1, 33)

% 双第一排名验证
rank_with_v4();

% 单项冒烟测试
prob = ZDT1(); PF = prob.ParetoFront(500);
alg = HCEAV4(100, 200, 1); [P, R] = alg.optimize(prob);
IGD(R.F, PF)
```

## 4. 复现步骤与随机种子
- 种子：固定 1:30（每问题 30 个独立种子）
- 公平性：所有算法统一 popSize=100, maxGen=200
- 数据落盘：每完成 1 个（算法×问题×种子）立即存 .mat，中断可续跑
- 统计：`run_statistics` 自动处理不完整数据（按各 (算法,问题) 对的可用种子数取中位数）

## 5. 诚实声明
- HCEAV4 IGD 第 1 领先 HCEA 幅度较小（4.273 vs 4.364，差 0.09），主要由
  UF5/UF6/CMO 三个欺骗性问题的改进贡献。
- HV 第 1 领先 HCEAV2 幅度极小（3.697 vs 3.758，差 0.06），统计上不构成
  对 HCEAV2 的显著优势——HV 优势保留在 HCEAV2/V4 之间近似打平。
- 8 个外部基线按文献原版实现，仅加 Problem 兼容层，核心逻辑未改。
- 55 个问题全部按官方公式实现，WFG 使用官方工具箱，ZDT/DTLZ/MaF/UF 按论文公式手写。

## 6. 已完成的清理
- 删除 C 盘临时目录的 MCP 辅助 .m 文件（5 个 Editor_* + matlab-mcp-server-2426556714）
- 删除根目录测试残留（test_fflush.txt, test_file_flush.txt, _batch_run_igds.m, run_one_test.m）
- 删除空占位目录（algorithms/latest, new, original; platemo_extract; docs/baselines; figure/）
- 删除 _platemo_official 下与 problems/ 重复的散文件
- 删除 results/bench_v4.mat（bench 中间产物）
- 保留：results/main, main_v4, merged_v4, ablation, sensitivity 全部成功数据
- 保留：algorithms_original/ 与 _platemo_official/platemo_v420.zip（原版来源证明）
