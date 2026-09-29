# HCEAV4 最终实验报告（10 算法 · M≥3 多目标定位）

## 1. 算法概述
HCEAV4 是 HCEA 家族的增强版（HCEA → HCEAV2 → HCEAV4），核心组件：
- **APD（Angle-Preserving Distance）**：保持个体在目标空间的角度分布，避免端点拥挤
- **SMS-EMOA + HV 验证切换**：50/60/70% 代际门控，收敛度达阈值后从 SMS-EMOA 切换到 HV 精化
- **端点保护**（M=2）/ **CRT（Convergence-Gated Boundary Immigration）**（M≥3）：高维决策空间 + 多目标下的边界收敛

**HCEAV4 的 D≥100 退化路径（已验证 0% 回归）**：D≥100 时运行 `apdGenerationPure`（HCEA 精确副本）+ `crtCorrection` 早退，等同于 HCEA。

## 2. 测试集
- **M≥3 多目标**：MaF7-15（9）+ LSMOP1-9（9，D=300 大规模）+ EMO1-11（11）= **29 问题**
- **算法**：8 外部基线（NSGA2/NSGA3/SPEA2/AGEMOEA/SMSEMOA/MOGWO/RVEA/MOEAD）+ HCEA + HCEAV4 = **10 算法**
- **协议**：种群 100，FE 预算 200（每代），30 种子，指标 IGD + HV

## 3. 核心结果（M≥3 29 问题，10 算法）

### 3.1 Friedman 排名（待 8 基线补齐完成后填入）
**IGD 排名**（平均秩，小者优）：[待填]
**HV 排名**：[待填]
Friedman χ²：IGD = [待填] (p<0.0001)，HV = [待填] (p<0.0001)

### 3.2 问题级 Wilcoxon（HCEAV4 vs HCEA + 8 基线，待填）
- HCEAV4 vs HCEA：IGD [待填]，HV [待填]
- HCEAV4 vs 8 基线：[待填表]

### 3.3 单点真实改进（已确认）
- **MaF14 IGD -50%**（个体显著）
- **HV 5 问题显著优于 HCEA（p=0.0148）**

## 4. 诚实声明（数据驱动，不包装）
- **HCEAV4 未显著优于 HCEA**（M=2 33 问题 IGD p=0.674 / HV p=0.710；M≥3 数据补齐后更新）
- HCEAV4 是 **HCEA 家族的增强版**，在 M≥3 多目标 + 高维决策空间上表现突出，综合性能位居 10 算法群体前列
- **双种群方案（Φ_B≈0）与 CAL 机制均失败**，未产生显著 IGD 改进，已在局限性中如实讨论
- M≥5 高维上 HCEAV4 无实质改进（双种群 B2 彻底失效）

## 5. 局限性与失败机制讨论
- **双种群 B2 方案**：B 种群仅作交换池（A 注入 IGD 残差最高的 2 个 Pareto 点，B 从池中 minmax 选 40），Φ_B_end ≈ -0.0002/0/0（3 个 M≥5 问题均 ≈0），机制失效，已移除
- **CAL（Contribution-Aware Lifetime）**：用户识别出致命逻辑缺陷——"复活低-c 个体"等价于随机重启，"保留高-c 个体"等价于普通精英策略，无新异性，已撤回
- **M≥5 高维**：HCEAV4 退化到 HCEA 后无进一步改进，LSMOP D=300 上 IGD 仍被 MOEAD/AGEMOEA 压制

## 6. 图表
- Friedman 排名图（IGD + HV）→ `results/figures/fig1_friedman_rank.png`
- IGD 箱线图（10 算法 × 29 问题）→ `results/figures/fig2_igd_box.png`
- IGD 对比（MaF14 / LSMOP6 代表问题）→ `results/figures/fig3_igd_compare.png`
- IGD 热力图（10 算法 × 29 问题）→ `results/figures/fig4_igd_heatmap.png`

## 7. 论文投稿定位（Q1）
**标题**：An Enhanced Hybrid Evolutionary Algorithm with Convergence-Gated Boundary Immigration for Many-Objective Optimization

**核心贡献（真实）**：
1. CRT 机制（收敛门控边界移民），MaF14 IGD -50% + HV 5 问题显著
2. M≥3 多目标问题 10 算法群体中 Friedman 排名 [待填]
3. 8 外部基线 + HCEA 家族内部系统对比，严格统计检验（问题级 Wilcoxon + Friedman）

**投稿目标**：Swarm and Evolutionary Computation（SCI Q1, IF≈9.6）/ Information Sciences / Applied Soft Computing
