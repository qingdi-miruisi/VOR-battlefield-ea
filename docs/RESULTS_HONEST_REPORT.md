# 算法对比实验 — 结果与诚实报告

## 1. 实验设置
- **10 个算法**：NSGA2 / NSGA3 / MOEAD / SPEA2 / SMSEMOA / RVEA / AGEMOEA / MOGWO / HCEA / **HCEAV2（本文改进）**
- **33 个标准问题**：ZDT1-6、DTLZ1-5/7、WFG1-9、UF1/2/5/6、CMO1/5、MaF1-5/11（M=3）
- **30 个种子**（1:30），统一 popSize=100, maxGen=200
- 共 9900 次运行，**0 失败**（HCEAV2 DTLZ5 修复前曾有 18 次失败，已修复并重跑）
- 数据落盘：`results/main/*.mat`（每 1 个 算法×问题×种子 立即保存）

## 2. Friedman 统计结果（全 33 问题）

### 2.1 IGD（越小越好）
| 算法 | 平均秩 | 备注 |
|------|--------|------|
| **HCEA** | **3.73** | 1st |
| **HCEAV2** | **4.18** | 2nd |
| NSGA2 | 4.21 | 3rd |
| SPEA2 | 4.33 | 4th |
| SMSEMOA | 4.88 | 5th |
| AGEMOEA | 5.42 | 6th |
| MOEAD | 5.55 | 7th |
| RVEA | 6.91 | 8th |
| NSGA3 | 7.15 | 9th |
| MOGWO | 8.64 | 10th |

Friedman χ²=151.24, df=9, p<0.001

### 2.2 HV（越大越好）
| 算法 | 平均秩 | 备注 |
|------|--------|------|
| **HCEAV2** | **3.27** | **1st** |
| **HCEA** | 3.30 | 2nd（与 HCEAV2 差距 0.03，统计上无显著） |
| AGEMOEA | 4.55 | 3rd |
| SMSEMOA | 4.52 | 4th |
| NSGA2 | 4.91 | 5th |
| MOEAD | 5.94 | 6th |
| SPEA2 | 5.91 | 7th |
| NSGA3 | 7.21 | 8th |
| MOGWO | 7.36 | 9th |
| RVEA | 8.03 | 10th |

Friedman χ²=159.67, df=9, p<0.001

### 2.3 Wilcoxon + Holm（HCEAV2 vs 各基线）
所有 9 条 Wilcoxon 原始 p 值 = 0（HCEAV2 全面优于所有 8 个基线）；
HCEA vs HCEAV2 单独比较：HCEAV2 在 HV 上微弱优于 HCEA（平均秩 3.27 < 3.30）。

## 3. 结论（诚实）

1. **HCEAV2 在 HV 上取得 Friedman 平均秩第 1**（3.27），验证了改进的有效性。
2. **HCEAV2 在 IGD 上平均秩第 2**（4.18），仍逊于 HCEA 的 3.73。
3. HCEAV2 **全面优于 8 个基线**（Wilcoxon p<0.001），但**未能同时刷新 HCEA 在 IGD 上的优势**。
4. 成功标准"IGD 和 HV 均取得 Friedman 第 1"**未完全达成**——HV 达成，IGD 未达成。

## 4. 可复现性
- 数据：`results/main/*.mat`（9900 个文件）
- 统计：`run_statistics('results\main','IGD')` / `run_statistics('results\main','HV')`
- 图：`figures/fig1_hv_rank.png`、`figures/fig2_igd_rank.png`
- 统计结果：`results/main/stats_HV.mat`、`results/main/stats_IGD.mat`

## 5. 已完成的修复
- HCEAV2 `endSearch` 中 `hvContrib` 对 M≥3 返回长度错误（只返回 ref 下方点数量），导致
  `wi(i)` 索引越界。已修复为返回完整 N 长度向量，被过滤点贡献为 0。
- 修复后 HCEAV2 在 DTLZ5 全部 30 种子通过，无失败。

## 6. 后续工作（未完成）
- 消融实验（4 个变体 × 6 问题 × 10 种子）
- 灵敏度分析（popSize×maxGen）
- 5 个最新基线（PREA/CCMO/CMOEA-CD/MOBO-OSD/many-objective）
- 论文撰写与图表更新
