# EDDV8 最终报告（原 EDDV7 文件，EDDV8 为 EDDV7 的增强版）

## 0. 版本判定
- **EDDV8（= 本代码库 `algorithms/EDDV7.m`，文件名保留 EDDV7 前缀但内容为 EDDV8）** 为最终锁定版本（2026-09-27）。
- EDDV9（整核 SOTA 化委托框架）经 2026-09-27 实测**无优势、已弃用**：
  - CF1/CF5 上 IGD ≈ 1e-3（单核委托即 SOTA 重跑），但**无任何超越**（CF5 官方 SOTA IGD≈1e-4）；
  - 三核同会话（FDSEA+GDVTSF+MOEA-IB）因内存/类冲突不可行；
  - SOTA 官方核不支持动态 subFE 分配（固定 1/N），无法实现自适应。
  - 结论：**1st 目标在范围内不可达**（需全新机制而非 SOTA 重组）。EDDV8 为最优可发表版。

## 1. EDDV8 相对 EDDV7 的改进（CF/MW 战场）
| 题 | EDDV7 IGD med | EDDV8 IGD med | 倍率 |
|---|---|---|---|
| MW11 | 4.851 | 0.02714 | 178.6× |
| MW7 | 2.650 | 0.03159 | 83.9× |
| MW3 | 2.655 | 0.06093 | 43.6× |
| MW13 | 6.786 | 0.2724 | 24.9× |
| MW8 | 2.381 | 0.1425 | 16.7× |
| MW2 | 2.091 | 0.1166 | 17.9× |
| MW1 | 10.484 | 2.063 | 5.1× |
| CF2 | 0.465 | 0.08966 | 5.0× |
| CF6 | 0.548 | 0.1571 | 3.5× |
| CF9 | 0.564 | 0.1963 | 2.8× |
| **CF10** | 0.6954 | **81.69** | **0.0085×（恶化）** |

**PPS 崩塌（诚实定位）**：EDDV8 的 PPS 崩塌从 EDDV7 的 12/24（PPS=1.0）
**减少到 6/24**（CF10, MW1, MW4, MW5, MW9, MW12），但仍有 11/24 题
PPS≤10。约束感知 NSGA-2 选择**部分**（非完全）消除了 PPS 崩塌。

## 2. EDDV8 全量 30 seeds 结果

### LSMOP 战场（10 题：LSMOP1-9 + DTLZ2_300D_M3）
| 问题 | EDDV8 IGD | 最佳 SOTA IGD | 排名 |
|---|---|---|---|
| LSMOP1 | 0.8578 | FDSEA 0.1525 | 4/5 |
| LSMOP2 | 0.4259 | GDVTSF 0.077 | 4/5 |
| LSMOP3 | 0.8628 | FDSEA 0.8619 | 4/5（tie） |
| LSMOP4 | 0.4998 | FDSEA 0.1518 | 4/5 |
| LSMOP5 | 0.9411 | FDSEA 0.377 | 4/5 |
| LSMOP6 | 1.631 | FDSEA 0.6553 | 4/5 |
| LSMOP7 | 1.33 | GDVTSF 0.865 | 4/5 |
| LSMOP8 | 0.9411 | FDSEA 0.0924 | 4/5 |
| LSMOP9 | 1.548 | MOEA-IB 1.158 | 4/5 |
| DTLZ2_300D_M3 | 0.7351 | FDSEA 0.0619 | 4/5 |

**5-alg Friedman IGD meanRank**：FDSEA 1.200 > GDVTSF 2.400 > MOEA-IB 2.600 > oldEDD/EDDV8 tied 4.400

**12-alg Friedman IGD meanRank**：FDSEA 1.500 > MOEA-IB 2.333 > GDVTSF 2.611 > **EDDV8 6.389（= old EDD 排名）** > MOGWO 6.611 > ...

### CF/MW 战场（24 题：CF1-10, MW1-14）
**5-alg Friedman IGD meanRank**：MOEA-IB 0.792 > FDSEA 1.375 > GDVTSF 1.625 > **EDDV8 2.833** > old EDD_cf 3.750

**GDVTSF 严格主导 CF/MW**（MW1 0.0567 vs EDDV8 2.063，36 倍差距；CF 族 IGD 0.001–0.53 vs EDDV8 0.09–81.69）。

**MW 族 HV≈0（所有算法）**：Ma-Wang 2019 PF f2∈[0,0.15]，ref=1.1*max(PF) 太紧 — 预期行为，需 caption 注明。

## 3. 诚实定位（论文必须维持）
- EDDV8 **不是**任一战场的 1st。
- LSMOP：与旧 EDD tied 4.40/5，落后 FDSEA 1.20 / GDVTSF 2.40 / MOEA-IB 2.60。
- CF/MW：4th of 5（2.833），落后 MOEA-IB/FDSEA/GDVTSF；旧 EDD_cf 3.750 → EDDV8 2.833（改善）。
- PPS 崩塌仅部分修复（11/24 PPS≤10；6/24 PPS=1，含 CF10 IGD 81.69 灾难性 outlier）。
- 根因：SOTA 的算子架构（FDSEA 频域搜索 + NSGA-III LastSelection；GDVTSF kmeans 聚类 + GDV + TSO + WOF；MOEA-IB ReMO + WOF 变量分组）在探索/开发质量上结构性优于 EDD 的 epsilon 网格 + DSG。仅改 EDD 选择/算子无法弥合 4–10 倍的 IGD 差距。

## 4. 红线约束
- N=100, G=200, maxFE≈20100, seeds 1–30；PF=官方 GetOptimum；ref=1.1*max(PF)；不造数；不改官方 PlatEMO 源码；`algorithms/EDD.m`（v12）与 `EDD_cf.m` 未动。
- 预算放宽 G=400 对 EDDV8 无帮助（瓶颈 = 局部算子质量，非 FE 预算）。

## 5. EDDV9 弃用结论
- 单核委托 = SOTA 重跑，无任何超越。
- 三核同会话：内存/类冲突不可行。
- SOTA 官方核不支持动态 subFE 分配（固定 1/N）。
- **1st 目标在范围内不可达**（需全新机制而非 SOTA 重组）。

## 6. 可发表结论
- EDDV8 为 EDD 家族在红线约束下的最优形态。
- 论文定位：(i) LSMOP 上与旧 EDD tied 4th–5th/12，消除传统基线崩塌；(ii) CF/MW 上 PPS 崩塌部分缓解（MW1 IGD 11.2→2.1，5×）；(iii) 诚实报告 11/24 CF/MW 残存 PPS 崩塌边界。
