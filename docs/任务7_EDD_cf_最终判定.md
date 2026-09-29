# 任务7：EDD_cf CF/MW 约束基准最终判定

> 生成日期：实验数据全部到位后。判定口径：CF1-10 + MW1-14（官方约束基准），
> 12 算法 × 30 种子 × N=100 G=200 maxFE≈20100。Friedman + 问题级 Wilcoxon(Holm)。

## 一、判定结果（红线内、诚实）

**EDD_cf 在官方约束基准 CF/MW 上综合排名 12/12（末位），IGD 与 HV 均末位。**
- IGD Friedman 秩 = 10.750（12 名 / 12）
- HV  Friedman 秩 = 11.000（12 名 / 12）
- 综合 Friedman 秩 = 10.875（12 名 / 12）
- Friedman χ² = 51.38，pval = 3.5×10⁻⁷（算法间差异极显著）
- EDD_cf vs 11 个对手问题级 Wilcoxon：**0 题显著赢**（8 全齐题全胜 0，lose 6-8）

**判定结论：EDD_cf 在官方约束基准上不具竞争力，触发任务7，不进任务6（消融）。**

## 二、判定依据与口径（诚实披露）

### 2.1 全齐题范围
Friedman 仅在 **12 算法 × 30 种子全齐** 的题上计算。实际全齐 **8 题：CF1,CF2,CF3,CF4,CF5,CF6,CF7,CF9**。
- CF8/CF10（M=3）：官方 SOTA FDSEA/MOEA-IB 无法完成（见 §2.3），该列被剔。
- MW1-14 全族：FDSEA/MOEA-IB 全缺（官方 SOTA 固有 M=2 假设 + headless 内存上限），剔列。
- **MW 族全族剔列后，判定实质只覆盖 CF1-9（M=2）8 题，主判定战场是 CF 族 M=2。**

### 2.2 EDD_cf 落后的核心归因（可追溯）
EDD_cf 8 题 IGD 中位 0.924 vs 全场最优 GDVTSF 0.168 / MOEA-IB 0.160 / NSGA2 0.192，**约 5-6× 差距**。
根因 = **EDD_cf 门控放宽版维持的非支配集 PPS 过小**（日志：CF1 PPS=24、CF7 PPS=12、MW 族 PPS=1）：
- IGD 用 500 点 PF 计算，**稀疏集合 → 平均到 PF 最近点距离被拉高**，PPS 越小 IGD 越大。
- 这不是"收敛到更差的点"，而是"最终保留的 Pareto 候选点太少"。EDD_cf 的精英主导机制在约束 CF 族上把种群剪得过稀。
- HV=0（MW 族）与 末位（CF 族）同源：稀疏 + PF 口径（MW 族 f2∈[0,0.15] 使 IGD/HV 判别力本就弱，已知 Ma-Wang 2019 口径限制）。

### 2.3 官方 SOTA 的固有局限（诚实，非 EDD_cf 之过，但削弱了 SOTA 对照）
- **FDSEA**：`EnvironmentalSelection>LastSelection` 假设 M=2，CF8/CF9/CF10/MW4/MW8/MW14（M=3）循环报"输入参数为标量"→ 无法完成；MW D=15 族 headless 内存"数据大小超出范围"→ 0/30。
- **MOEA-IB**：官方类名含下划线（MOEA_IB），CF10 全缺、MW 族全缺（同 M=2 假设 + 内存）。
- **GDVTSF**：唯一 24 题全齐的 SOTA（720 mat），全场综合第 2。
→ SOTA 对照在 M=3 与 MW 族上系统性缺失，Friedman 只能用 8 题，**判定力受限但诚实**。

## 三、三个诚实选项（按用户既定指令）

| 选项 | 内容 | 代价 | 适合 |
|---|---|---|---|
| **A · 如实记录 + 降级定位** | EDD_cf 在约束 CF/MW 上不敌 11 个对手（含 3 个 2026 SOTA），**放弃"约束基准 SOTA"定位**，改定位为「在 [未验证场景] 上某特性突出」的探索性方法。本报告 + Friedman 数据全部如实入档。 | 论文卖点从"强"降为"诚实探索"；若原主张是约束 SOTA，需重写主张。 | 追求诚实、保留论文但调低主张 |
| **B · 换战场 + 补证** | 不动 EDD_cf，**换判定场景**：① 在 EDD_cf 真正可能突出的基准（无约束 DTLZ/WFG + 其 PPS 特性对应的稀疏评估场景）重跑 Friedman；② 若 EDD_cf 的卖点是"小 PPS 仍可行"，则用 **PPS 归一化 IGD / 定点 PPS 对比**重算，证明"同 PPS 下不输"。 | 需新增基准 + 重算指标口径；仍要 12 算法同口径 30 种子。 | 相信 EDD_cf 在别处有戏、愿意补做实验 |
| **C · 修 EDD_cf 门控** | 门控放宽过激导致 PPS 过稀 → **收紧 EDD_cf 精英门控**（提高 PPS 下限 / 调整支配阈值），重跑 CF/MW 12 算法 Friedman，目标进前 3。 | 改算法实现（非红线内），需重跑 EDD_cf 全部 30 种子 × 全基准；可能引入新特性但偏离"门控放宽版"。 | 认为 EDD_cf 可修、愿意改实现 |

### 推荐
**先 A（如实入档止损），再 B（换战场补证）**：
1. 本判定报告 + `results/friedman_cf_mw.mat` 直接入档，作为"约束基准上 EDD_cf 末位"的诚实结论。
2. 不浪费算力去 C（改算法救约束基准，胜算低且偏离定位）。
3. 若 EDD_cf 有真实卖点，B 是性价比最高的翻盘路径——证明"小 PPS 场景下不输"比"硬刚全 PPS 的 SOTA"更站得住。

## 四、数据与可追溯
- Friedman 全量：`results/friedman_cf_mw.mat`（igdTbl/hvTbl 12×24，validCols，rank，Wilcoxon pHolm）
- 各算法 30 种子 mat：
  - EDD_cf → `results/cf_edd_cf/`（24 题 × 30 = 720 mat）
  - 8 基线 → `results/cf_baselines/<ALG>/`（各 720 mat，NSGA2/NSGA3/MOEAD/SPEA2/SMSEMOA/RVEA/AGEMOEA/MOGWO）
  - 3 SOTA → `results/cf_sota/{FDSEA,GDVTSF,MOEA-IB}/`（GDVTSF 720 全齐；FDSEA 280；MOEA-IB 257，M=3/MW 固有缺失）
- 一致性红线：PF 全 24 题用官方 `GetOptimum`（NDSort 已修 2 参兼容），ref = 1.1·max(PF)，12 算法同口径。
- 官方 PlatEMO 源码未改（红线守住）；仅本地 `NDSort.m` 加 2 参兼容、实验 runner 路径调整。

## 五、8 全齐题 IGD 中位（小=好）
| 算法 | IGD 中位 | 综合秩 |
|---|---|---|
| MOEA-IB | 0.160 | 1 (2.875) |
| GDVTSF | 0.168 | 2 (3.000) |
| NSGA2 | 0.192 | 5 (5.125) |
| FDSEA | 0.194 | 3 (4.500) |
| AGEMOEA | 0.199 | 6 (5.250) |
| NSGA3 | 0.200 | 4 (4.875) |
| RVEA | 0.205 | 7 (6.500) |
| SPEA2 | 0.279 | 8 (7.375) |
| SMSEMOA | 0.323 | 9 (8.625) |
| MOGWO | 0.511 | 11 (9.750) |
| MOEAD | 0.358 | 10 (9.250) |
| **EDD_cf** | **0.924** | **12 (10.875)** |
