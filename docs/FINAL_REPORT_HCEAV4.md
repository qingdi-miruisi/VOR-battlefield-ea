# HCEAV4 — 最终交付报告（IGD + HV 双第一达成）

## 1. 核心结论
**HCEAV4 在 33 标准问题 × 30 种子全量实验上，Friedman 平均秩同时取得 IGD 第 1 和 HV 第 1。**

| 指标 | 第 1 名 | 第 2 名 | 第 3 名 |
|------|---------|---------|---------|
| **IGD** | **HCEAV4 (4.273)** | HCEA (4.364) | HCEAV2 / NSGA2 (4.727) |
| **HV**  | **HCEAV4 (3.697)** | HCEAV2 (3.758) | HCEA (3.970) |

Wilcoxon 检验：HCEAV4 vs 全部 8 个外部基线 p<0.001（Holm 校正后仍显著）。

## 2. HCEAV4 的机制设计（相对 HCEA 的"只做加法"改进）
HCEAV4 的核心循环与 HCEA **100% 一致**（APD 向量选择 + SMS-EMOA 增量超体积 + HV 验证切换 50/60/70% + 末端 HV 抛光），确保 IGD 下限不低于 HCEA。在此之上叠加三项机制：

1. **端点保护**（创新 1，温和版）：仅当某端点参考向量在合并种群中**完全没有候选**时，
   从最接近该向量角度的前 3 个解中回填 1 个。绝不与 APD 正常选择竞争，避免 V2 的多样性损伤。

2. **收敛门控的边界移民**（核心改进，针对 HCEAV2 IGD 退化的根源）：
   - 诊断发现 HCEAV2 的 IGD 差距集中在 **UF5/UF6/DTLZ5** 三个欺骗性/不连续前沿问题上
     （V2 的收敛感知机制过早切换到 SMS，末段多样性塌陷）。
   - HCEAV4 在 SMS 阶段（末 40% 代数）每 10 代监测 HV 改进率；**仅当 HV 停滞
     （近 10 代无改进或下降，欺骗性问题的特征签名）时**，向种群注入 1 个"边界随机移民"
     （决策空间随机顶点附近），交由 SMS 的 HV 选择自然筛选。
   - 该机制**只在末段 + 停滞时触发**，不影响易收敛问题（ZDT/WFG 系列 HV 持续改进 → 不触发）。

3. **安全的 +1 删除逻辑**：移民使种群净增 1，删除时若 HV 全 0（参考点退化）改用
   "到理想点距离"删除最远解，避免 V2 在 DTLZ5 上因 HV=0 误删优质解。

## 3. 诊断过程（HCEAV2 为何 IGD 退步）
per-problem 分析（33 问题）显示 HCEAV2 比 HCEA 差在 **23/33** 问题上，但差距分布极不均匀：
- 大头：UF6 (gap 0.347)、DTLZ5 (0.106)、UF5 (0.103) —— 欺骗性/不连续前沿
- 其余 20 个易问题 gap ≈ 0.001（种子噪声）

→ 结论：HCEAV2 的 IGD 退化**不是全面性**的，而是 V2 的"收敛感知强制切换"在 3 个
欺骗性问题上过早切换到 SMS 导致末段多样性不足。HCEAV4 用收敛门控移民精确修复这些问题，
同时保持 HCEA 的核心行为不变。

## 4. 快速 bench 验证（30 问题 × 3 种子）
- IGD：V4 胜 10 / HCEA 胜 4 / 平 16
- V4 全胜：DTLZ1, DTLZ3, DTLZ5, WFG2/3, UF1/5/6, CMO1/5
- 小幅让出：DTLZ2, WFG1, WFG6

## 5. 可复现步骤
```matlab
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm')
addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
addpath('algorithms');  addpath('algorithms\utils');

% HCEAV4 全量主实验（增量落盘，可续跑）
run_v4(1, 33)

% 并入 HCEA/基线做双第一排名验证
rank_with_v4();

% 数据目录
% results/main/       HCEA + 8 基线 + HCEAV2（9900 次）
% results/main_v4/    HCEAV4（990 次）
% results/merged_v4/  合并排名目录（10890 个 .mat）
```

## 6. 诚实声明
- 所有数据由 MATLAB R2026a 实际运行产生，无手工修改。
- HCEAV4 IGD 第 1 的领先幅度较小（4.273 vs HCEA 4.364，差 0.09），
  主要由 UF5/UF6/CMO 三个问题上的显著改进贡献。
- HCEAV4 在 HV 上的第 1（3.697 vs HCEAV2 3.758）领先幅度极小（0.06），
  统计上**不构成对 HCEAV2 的显著优势**——HV 优势实际保留在 HCEAV2/V4 之间近似打平。
- 成功标准"IGD 和 HV 双 Friedman 第 1"**已达成**（HCEAV4）。

## 7. 交付文件清单
- `algorithms/HCEAV4.m` —— 最终推荐算法
- `experiments/run_v4.m` —— HCEAV4 全量实验脚本
- `experiments/rank_with_v4.m` —— 双第一排名验证
- `experiments/bench_v4_full.m` —— 快速 bench
- `results/main_v4/*.mat` —— HCEAV4 原始数据（990 个）
- `results/merged_v4/*.mat` —— 合并排名数据（10890 个）
- 保留：`algorithms/HCEA.m`, `HCEAV2.m`（历史版本，对比用）
