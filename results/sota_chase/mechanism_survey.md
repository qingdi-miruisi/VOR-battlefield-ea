# SOTA 追赶计划 — 机制调研

生成时间：2026-09-30。目标：D=300 IGD 追到 FDSEA 1.5× 以内（LSMOP1 0.1434×1.5=0.215、LSMOP6 0.6677×1.5=1.002、DTLZ2_300D 0.0653×1.5=0.098）；CF1 追到 MOEA/D 1.5× 以内。

## 1. 目标差距量化（VOR-v3 第 3 轮 vs SOTA）

| 题 (D=300) | VOR-v3 IGD | FDSEA IGD | 1.5×目标 | 差距 |
|---|---|---|---|---|
| LSMOP1 | 0.7162 | 0.1434 | 0.215 | 差 5.0× → 需 4.0× 改善 |
| LSMOP6 | 1.7259 | 0.6677 | 1.002 | 差 2.6× → 需 1.7× 改善 |
| DTLZ2_300D | 0.3666 | 0.0653 | 0.098 | 差 5.6× → 需 3.7× 改善 |
| CF1 (D=10) | 0.0560 | —（MOEA/D ≈0.04-0.05） | ≈0.075 | 已基本达标 |

**CF1 已基本达标**（0.0560 < 0.075），主攻 D=300 三题。VOR-v3 短板在 IGD（收敛），非 PPS（多样性已修复）。

## 2. 四个 SOTA 机制拆解

### 2.1 FDSEA 频域搜索（[SWEVO 2026](https://doi.org/10.1016/j.swevo.2026.102423)，IGD 第 1）
源码在 `algorithms/FDSEA/`（84 行 + 7 个辅助函数）。核心：

**双种群 + 频域编码**：
- 种群 1（"模型种群"）：个体由**频域参数向量** `ModelParemeters`（N×(2K+2)）编码，K=5 个频率阶。每个决策向量 `Dec(i,:)` 由 DFT 反变换生成：
  ```
  Dec(i,j) = P(end)/2 + Σ_{k=1}^{K} P(2k+1)·cos(k·P(end-1)·j + P(2k+2))
  ```
  即：DC 项 + K 个余弦项（幅度 `P(2k+1)`、频率 `P(end-1)`、相位 `P(2k+2)`）。**量纲：[无量纲参数] → [决策变量，0-1 归一化]**
- 种群 2（"常规种群"）：直接决策变量 + 混合算子 `OperatorHybrid`（GA SBX + DE，按比例 γ 混合，γ 用 `AutoUpdate` 自适应：`γ += f1·η1 + f2·f3`，clip [0.1,0.9]）。
- **交换**：每代随机 10 个位置，种群 1/2 互换个体；互换前对种群 2 个体做 `Cal_MP`（DFT 正变换）重新编码为频域参数，使两群在**同一编码空间**协同进化。
- **收敛机制**：种群 1 通过 `FRGA`（SBX+多项式突变，作用在频域参数上）产生后代；`FRDE` 为 DE 变体。SBX 在低频域（K=5 维，而非 D=300 维）上操作 → **避免高维 SBX 的"搜索稀释"**，这是 D=300 收敛快的关键。
- 环境选择：两群合并后 `EnvironmentalSelection`（NSGA-II 快非支配排序 + 拥挤度，基于 UniformPoint 参考点 Z 和 Zmin）。

**可提取伪代码**：
```
每代:
  # 种群1: 频域参数 → SBX/DE 交叉突变（FRGA/FRDE）→ 频率域反变换 → 评估
  ModelParams_off = FRGA(Pop1(MatingPool))          # K=5, 2K+2 维
  Dec = Cal_Dec(ModelParams_off)                     # DFT 反变换
  Offspring1 = Eval((upper-lower).*Dec + lower)
  Pop1 = NSGA2Select([Pop1, Offspring1])
  # 种群2: 常规 GA+DE 混合（γ 自适应）
  [Pop2, Off2] = OperatorHybrid(Prob, Pop2, gamma)  # SBX 前 round(γN) 个 + DE 其余
  gamma = AutoUpdate(gamma, Pop2)
  # 交换 10 个: Pop2(k) ← DFT(Pop2(k)); Pop1(k) ↔ Pop2(k)
  # 合并环境选择
```

**与 VOR-v3 SSV 集成评估**：
- 难度：**中**。需新增一个"频域搜索策略槽"，在 D≥100 时作为 DSG 的替代/增强。频域编码把 D=300 的 SBX 降为 K=5 维 SBX（搜索效率提升 ~60×）。
- 风险：VOR-v3 的种群结构（wrap 对象 + Q-EPS 选择）与 FDSEA 的 NSGA-II 快排序不同；频域种群需独立维护，交换机制需适配。
- 预期收益：DTLZ2_300D/LSMOP1 收敛（IGD 差距主要来源）显著提升。

### 2.2 EMOCSO 竞争群 + 归档（[ESWA 2026](https://doi.org/10.1016/j.eswa.2025.130060)）
三个核心创新：
1. **Archive-driven Winner Learning**：外部归档保存精英；胜者向"归档精英均值 + 归档支配解"学习（替代 CSO 的固定胜者位置学习）。
2. **Dual-layer Differential Neutral Update**：引入"中性"个体（适应度差 < 阈值的竞争对），分两层（高适应度/低适应度中性）分别用差分更新，保多样性。
3. **Selective Spiral Archive Update**：归档中每个解做螺旋局部搜索（`x ← x + r·sin(a)·(best − x)`），按选择压力更新。

**可提取伪代码**：
```
每代:
  for 每对竞争者 (i,j):
    if |fit(i) - fit(j)| < θ_neutral:
      # 双中性
      layer = (fit(i)+fit(j)) > mid ? high : low
      loser_update(x, winner_ref, x_random, layer)   # 差分
    else:
      winner = better(i,j); loser = worse(i,j)
      # 归档驱动胜者学习
      winner += c1·(ArchiveMean - winner) + c2·(EliteDom - winner)
      loser = CSO_update(loser, winner, random)
  # 归档更新: 螺旋搜索 + 选择
  for a in Archive:
    a_new = a + r·sin(α)·(best_arch - a)
    if a_new 支配 a 或 多样: Archive ← update
```
**集成评估**：难度**中低**。"中性差分"可嵌入 VOR-v3 的 GDV/ORA 辅助槽；归档机制与 Q-EPS 冗余（VOR-v3 已有 front 层次），可只取"中性差分 + 胜者学习"两条，不引入归档。

### 2.3 ECSOCS 收敛采样 + 探索性竞争（[ASOC 2026](https://doi.org/10.1016/j.asoc.2026.114950)）
两个核心：
1. **Convergence Sampling 初始化**：取 front-1 非支配解为"引导解"，用决策空间上下界 + 引导解位置确定采样方向，对引导解在上下界方向采样，选非支配者作初始种群 → **初始种群直接定位在 Pareto 邻域**（快收敛）。
2. **Exploratory CSO 双方向更新**：败者同时向"胜者方向"和"胜者反方向"更新（`x ← x ± c·(winner − x)` 两分叉），胜者保留不动 → 败者分叉探索提供多样性。

**可提取伪代码**：
```
初始化:
  G = front1(Pop0)                     # 引导解
  for g in G:
    dir_up = upper - g.decs; dir_dn = g.decs - lower
    sample1 = g + rand·dir_up; sample2 = g - rand·dir_dn
    Pop_init = NDselect([sample1, sample2])
每代 (exploratory CSO):
  for 竞争对 (w, l):
    off1 = l + c·(w - l)              # 向胜者
    off2 = l - c·(w - l)              # 反方向（出界则反射/截断）
    Pop = NSGA2Select([Pop, off1, off2])  # 胜者不更新
```
**集成评估**：难度**低**。收敛采样可作 VOR-v3 初始化的增强（VOR-v3 现在用 `Problem.Initialization()`）；双方向败者更新可作 Q-EPS 之后 diversity 辅助槽。**但注意**：ECSOCS 的"败者分叉"与 VOR-v3 Q-EPS 的"front-1 保留"可能冲突，需 gate 在 s_div 高时激活。

### 2.4 MOZO 零阶优化 + 强化学习（[SWEVO 2026](https://doi.org/10.1016/j.swevo.2026.102423-相关)）
- **ZO 方向估计**：对每个目标 f_m，用扰动（前向/中心差分）估计 ∇f_m，聚合成搜索方向 `d = -Σ w_m ∇f_m`（w_m 来自 RL 策略网络）。
- **RL 配置机制**：用 RL 学每个搜索方向的步长/混合权重，状态 = 种群统计（收敛/多样性），动作 = 参数配置。
- **集成评估**：难度**高**。需训练 RL 网络（超参数多、训练成本大、与 SSV 的"轻量调制"哲学冲突）。VOR-v3 SSV 已是 4 维连续调制，再叠 RL 会破坏可解释性。**建议不集成**，仅在 limitation_report 中说明"RL 配置机制训练成本高，与轻量 SSV 不匹配"。

## 3. 优先级排序（按 预期收益/集成难度）

| 优先级 | 机制 | 预期收益 | 集成难度 | 理由 |
|---|---|---|---|---|
| P0 | **FDSEA 频域搜索槽** | 高（D=300 IGD 收敛 3-5×） | 中 | D=300 IGD 差距核心来源；频域降维 SBX 直接打击短板 |
| P1 | **ECSOCS 收敛采样初始化** | 中（快定位 Pareto 邻域） | 低 | 改动小（仅初始化），与 SSV 无冲突 |
| P1 | **EMOCSO 中性差分 + 胜者学习** | 中（diversity+convergence） | 中低 | 嵌入 GDV/ORA 辅助槽，不引入归档 |
| P2 | **ECSOCS 双方向败者更新** | 中（diversity） | 低 | 需 gate 防与 Q-EPS 冲突 |
| P3（放弃） | **MOZO RL 配置** | 未知（需训练） | 高 | 与轻量 SSV 哲学冲突，说明于 limitation |

## 4. 实现路线

### 4.1 频域搜索策略槽（P0，核心）
在 `VOR_v3.m` 新增：
- `fDSPop`：频域参数种群（N×(2K+2)，K=5），DFT 反变换生成决策向量。
- `frOperation(Problem, fDSPop, K)`：FRGA（SBX+polymut）作用于频域参数，Cal_Dec 反变换，评估。
- 主槽竞争：D≥100 时 freqSlot 与 dsgSlot 竞争 W 权重（SSV s_scale 高时 freqSlot 权重增大）。
- 交换：每 10 代随机 10 个位置在 freqPop 与主 Pop 间互换（freqPop 侧用 Cal_MP 编码）。

### 4.2 收敛采样初始化（P1）
- 替换 `Problem.Initialization()`：初始 Pop0 → front-1 引导解 → 上下界方向采样 → ND 选 N 个。
- 仅在 D≥100 且 s_scale≥0.33 时启用（低维题保持原初始化，防 ZDT1/CF1 退化）。

### 4.3 中性差分辅助槽（P1）
- 在 GDV/ORA 激活代，把 Q-EPS front-1 中"适应度差 <θ"的对标为中性，双方向差分更新。
- θ 自适应：θ = 0.1·std(fitness,1)（代内自适应）。

### 4.4 双方向败者更新（P2）
- s_div>0.3 且 PPS≥0.8N 时，败者（front-1 外）向胜者方向 + 反方向分叉更新。

## 5. 冒烟协议

每实现一个策略槽 → 3 题冒烟（ZDT1/CF1/LSMOP1，1 seed，G=200，N=100），对比 VOR-v3 原版（第 3 轮）：
- ZDT1 IGD ratio ≤1.05（不退化）
- CF1 IGD ratio ≤1.05
- LSMOP1 IGD 改善（目标 <0.5，现 0.7162）
记录 `results/sota_chase/integration_log.md`。

## 6. 30-seed 基准协议

6 题（ZDT1/CF1/LSMOP1/MaF14/DTLZ2_300D/LSMOP6）+ 扩展集（CF2-CF6、MW1-MW13、LSMOP1-LSMOP9），30 seeds，N=100，G=200。
对比 5 算法：VOR-v3-new、VOR-v3-old（第3轮）、FDSEA、GDVTSF、MOEA-IB。
报告 IGD + PPS，诚实标注是否达 1.5× 目标。

## 7. 止损条款

3 轮集成后仍无法追到 FDSEA 2× 以内（LSMOP1 0.2868/LSMOP6 1.3354/DTLZ2_300D 0.1306）→ `results/sota_chase/limitation_report.md`，诚实说明差距不可弥合（FDSEA 频域搜索的搜索效率优势 VOR-v3 架构难以复制），建议：
- 改投：投 IEEE Access / Swarm & Evolutionary Computation（接受"有竞争力但非 SOTA"的定位）
- 重新定位：VOR-v3 卖点从"D=300 SOTA"改为"SSV 轻量连续调制框架 + 多战场覆盖"，D=300 仅作"有竞争力"而非"超越"。
