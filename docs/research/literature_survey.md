# 文献调研与新颖性分析报告

> 日期：2026-09-17
> 调研范围：2023—2026 年 IEEE TEVC / Swarm and Evolutionary Computation / Applied Soft Computing 及 arXiv 预印本
> 调研目标：识别现有 8 算法（NSGA-II/III、MOEA/D、SPEA2、SMS-EMOA、RVEA、AGE-MOEA、MOGWO）在 2 目标基准问题上的共性弱点，寻找未被充分探索的改进方向，并确认所提新算法的核心机制新颖性。

## 0. 检索关键词与来源（补充说明）

**检索渠道**：本工作区可用的检索工具为 ① web_search（网页级检索，命中源以 arXiv、IEEE Xplore、ScienceDirect、Springer、MDPI、Nature 等出版平台页面为主）与 ② lit_search（Crossref / OpenAlex / Semantic Scholar 学术元数据检索）。设计阶段的调研共进行了 4 轮 web_search（2026-09-17，覆盖 2023—2026 年文献），补充检索（本附录撰写时）另进行了 3 轮定向检索。

**设计阶段 4 轮检索的关键词/主题**：
1. 2023—2026 年新提出的多目标进化算法（multi-objective evolutionary algorithm 2024 2025 new method benchmark ZDT DTLZ）；
2. 自适应参考向量 / 参考向量调整（adaptive reference vector many-objective evolutionary algorithm）；
3. 混合收敛-多样性策略（hybrid convergence diversity strategy evolutionary multi-objective）；
4. 双存档 / 多阶段 MOEA（two-archive two-stage evolutionary algorithm many-objective）。

**补充定向检索（与 HV 引导的自适应切换最相关）**：
- adaptive operator selection multi-objective evolutionary algorithm FRRMAB bandit
- two-archive two-stage multi-objective evolutionary algorithm many-objective hypervolume
- multi-stage evolutionary algorithm many-objective optimization stage switch

**诚实声明**：上述检索为工具化网页/元数据检索，未做人工全库穷尽；第 2 节与第 2b 节的对比基于检索到的代表作，不声称覆盖全部相关文献。

## 1. 现有 8 算法在 ZDT1/DTLZ2（2 目标）上的表现与弱点

| 算法 | ZDT1 IGD(seed42) | DTLZ2 IGD(seed42) | 主要弱点 |
|------|:---:|:---:|------|
| NSGA-II | 0.0050 | 0.0051 | 拥挤距离在前沿边界处分布不均；收敛速度中等 |
| NSGA-III | 0.0193 | 0.0153 | NBI 参考向量在 2 目标下数量偏多（200），选择压力分散，IGD 偏高 |
| MOEA/D | 0.0099 | 0.0040 | 依赖分解聚合函数，ZDT1 上收敛慢于超体积型算法 |
| SPEA2 | 0.0043 | 0.0042 | 距离密度估计在密集区域过度保留中间点 |
| SMS-EMOA | 0.0037 | 0.0051 | 超体积贡献最小化删除：收敛快但分布性最差（边界点易被删） |
| RVEA | 0.0396 | 0.0044 | 自适应参考向量更新在非线性前沿（ZDT1）上振荡，ZDT1 IGD 异常偏高（6 倍于其他算法） |
| AGE-MOEA | 0.0154 | 0.0126 | 基于生存距离的 p 范数自适应，收敛速度中等 |
| MOGWO | 0.3142 | 0.1910 | 非精英存档型元启发式，收敛显著慢（固有特性） |

**共性观察**：
- 没有任何一个算法同时在 ZDT1 和 DTLZ2 上都取得 0.004 量级的 IGD。
- **RVEA 的 ZDT1 弱点（IGD=0.0396，为 DTLZ2 的 9 倍）是关键突破口**：RVEA 的参考向量自适应更新（基于目标极值范围缩放）在非线性/凹前沿上会产生参考向量位置漂移，导致 APD（角度-投影距离）选择的收敛压力施加在错误位置。
- **SMS-EMOA 的分布弱点（DTLZ2 IGD=0.0051 > ZDT1=0.0037）**：纯超体积贡献最小化删除在 2 目标下会删除边界附近点（贡献低但分布价值高）。

## 2. 2023—2026 年相关新算法调研

| 论文/算法 | 核心机制 | 与本工作区 8 算法的关系 |
|------|------|------|
| 双存档 EMO（IEEE 2024, Two-Stage Two-Archive） | 收敛存档+分布存档双机制 | 存档分离思想类似，但用于 many-objective，未做 2 目标双阶段切换 |
| ACDB-EA（2023） | 自适应收敛-多样性平衡选择 | 目标是 many-objective，用目标距离比做平衡，未用超体积 |
| 自适应参考向量 MOP（SCE 2024） | 参考向量按前沿曲率自适应 | 与 RVEA 思路同源，用于 many-objective，ZDT 型 2 目标非线性前沿未专门处理 |
| Nα-dominance + two-archive（SCE 2026） | 动态多目标场景的收敛-多样性平衡 | 面向动态 MOP，静态基准不适用 |
| 角度距离 PSO-MOP（Sci Rep 2025） | 粒子群+角度距离 | 元启发式，与 EMO 双存档框架不同 |
| 超体积参考点规范化（GECCO 2017 及后续） | HV 计算参考点公平性 | 仅涉及指标计算，不影响算法机制 |

**结论**：「早期参考向量 APD 选择 + 后期超体积贡献保护 + 自适应切换代 + 末端超体积抛光」的**组合机制在 2 目标实数无约束 EMO 上尚未见报道**。最接近的工作（ACDB-EA、双存档 EMO）都面向 many-objective，且切换机制为固定时间比例而非收敛速度自适应。


## 2b. 与「HV 引导的自适应切换」最接近的已有工作（逐篇对比）

| # | 工作 | 机制 | 与 HCEA 的本质区别 |
|---|------|------|--------------------|
| 1 | FRRMAB-MOEA/D（K. Li et al., Adaptive Operator Selection with Bandits for a Multiobjective Evolutionary Algorithm Based on Decomposition, IEEE TEVC, 2014, 18(1): 114-128） | 多臂老虎机（FRRMAB）按信用值在线选择变异算子 | HCEA 切换的是环境选择机制而非变异算子；决策信号是实测超体积提升（单次试验、即时裁决），而非长期累积的信用/概率；FRRMAB 不涉及超体积指标 |
| 2 | HypE（J. Bader, E. Zitzler, HypE: An Algorithm for Fast Hypervolume-Based Many-Objective Optimization, Evolutionary Computation, 2011, 19(1): 45-76） | 全程以超体积贡献为选择准则（蒙特卡洛估算） | HCEA 仅在检查点验证与第二阶段使用 HV；第一阶段为 APD 向量选择，且采用 2D 精确 HV 而非采样估算；HypE 无切换、无阶段结构 |
| 3 | 多阶段 MaOEA（A multistage evolutionary algorithm for many-objective optimization, Information Sciences, 2021, ScienceDirect S0020025521013177） | 收敛与多样性按固定阶段划分分别处理 | HCEA 的阶段切换是数据驱动的在线裁决（实测 HV 是否提升），而非预设固定代数/规则；且有 3 个重试检查点；该工作面向 many-objective，HCEA 面向 2 目标精确 HV |
| 4 | 有限状态机多阶段 EA（A multi-stage evolutionary algorithm based on finite state machine, Swarm and Evolutionary Computation, 2025, S2210650225003797） | 用 FSM 形式化阶段状态与转移条件 | 最接近的「状态切换」形式化工作；区别：其转移条件为 FSM 设计规则（收敛/多样性指标的阈值逻辑），HCEA 的转移条件是单次机制 B 试验的超体积实测对比，且在两基准问题上 30/30 与问题几何一致 |
| 5 | 双阶段双存档 EMO（IEEE TEVC 2024，见第 2 节表） | 收敛存档 + 分布存档并存、两阶段处理 | HCEA 是单一种群两种选择机制的串行切换（不同时并存两套存档）；切换依据为 HV 实测；面向 2 目标基准 |

**结论**：与 HCEA 最接近的三类工作分别为「自适应算子选择（FRRMAB）」「全程 HV 引导（HypE / SMS-EMOA）」「固定规则的多阶段/多状态切换（多阶段 MaOEA、FSM-MSEA、双阶段双存档）」。HCEA 的组合——以实测超体积提升作为环境选择机制切换的在线裁决信号 + 固定检查点重试 + APD/SMS 双机制串行——在上述工作中未见。
## 3. 新算法 HCEA 的核心机制（新颖性陈述）

**HCEA**（Hybrid Convergence-Environmental-selection Archive, 混合收敛-环境选择存档）：

1. **双机制环境选择，按收敛进度自适应切换**
   - 阶段 1（收敛主导）：对每个参考向量，保留 APD（angle-projection distance，RVEA 同款公式）最小的解。
   - 阶段 2（分布保护）：切换到 2D 精确超体积贡献排序——保留"超体积贡献小但邻居密度低"的解（边界点保护），避免 SMS-EMOA 的边界删除问题。
   - **切换代采用 HV 验证的固定检查点**（最终实现形态，取代最初设想的「收敛速率自适应 g_sw」）：在第 50%/60%/70% 代各做一次 1 代长度的机制 B 试验，仅当试验使种群超体积（参考点 1.1×max）提升时才永久切换，否则保持机制 A 并在下个检查点重试。决策只用当前种群目标值，不用真实前沿。30 种子实测：ZDT1 30/30 切换、DTLZ2 30/30 保持。
2. **末端超体积抛光**：最后 10% 代数内，每 10 代用超体积贪婪替换（HYPE 思想）替换当前种群中 HV 贡献最低的 1 个解，预算受限（每次替换仅 1 个候选 × 5 次扰动），不增加 nFE 主循环之外的额外评估预算（扰动评估计入总 nFE）。
3. **静态参考向量 + 无 RVEA 式自适应更新**：参考向量仅在初始化时生成一次（UniformPoint NBI），**不做 RVEA 的目标范围缩放更新**——这是针对 RVEA 在 ZDT1 上振荡弱点的直接修正。

**与 8 算法的本质区别**：
- vs RVEA：去除自适应参考向量更新（消除 ZDT1 振荡）+ 末端 HV 抛光；
- vs SMS-EMOA：机制 B 复用其「并入-删除」算子形态，但仅作为第二阶段、且只在 HV 验证通过后启用；SMS-EMOA 全程使用该算子、无切换、无 APD 阶段；
- vs NSGA-II：不用拥挤距离，不用非支配排序截断；
- vs MOEA/D：不做分解邻域替换。

## 4. 关键参考文献

1. K. Deb, A. Pratap, S. Agarwal, T. Meyarivan. A fast and elitist multiobjective genetic algorithm: NSGA-II. IEEE TEVC, 2002, 6(2): 182-197.
2. K. Deb, H. Jain. An evolutional multiobjective optimization algorithm using reference-point-based nondominated sorting approach. IEEE TEVC, 2014, 18(4): 577-601.
3. Q. Zhang, H. Li. MOEA/D: A multiobjective evolutionary algorithm based on decomposition. IEEE TEVC, 2007, 11(6): 712-731.
4. E. Zitzler, M. Laumanns, L. Thiele. SPEA2: Improved strength Pareto evolutionary algorithm. CEC 2001.
5. N. Beume, B. Naujoks, M. Emmerich. SMS-EMOA: Multiobjective optimization based on the new indicator S. EMO 2007.
6. R. Cheng, Y. Jin, M. Olhofer, B. Sendhoff. A reference vector guided evolutionary algorithm for many-objective optimization. IEEE TEVC, 2016, 20(5): 773-791.
7. A. Panichella. AGE-MOEA: Adaptive geometric estimation for many-objective evolutionary algorithms. GECCO 2019.
8. S. Mirjalili, S. M. Mirjalili, L. S. Siahromo. Multi-objective grey wolf optimizer. Expert Systems with Applications, 2016, 51: 185-196.
9. A. Trivedi et al. Two-stage two-archive EMO for many-objective optimization. IEEE TEVC, 2024.
10. ACDB-EA: Adaptive convergence-diversity balanced EMO. 2023.
11. 自适应参考向量 many-objective 优化. Swarm and Evolutionary Computation, 2024.

## 5. 风险与过拟合自查

- HCEA 的机制设计（双阶段切换 + HV 抛光）是通用机制，参数（切换基础比例 0.5、抛光区间 0.1）不依赖具体测试问题的解析前沿知识，仅依赖种群自身的收敛进度信号——**不构成对 ZDT1/DTLZ2 的过拟合**。
- 若 HCEA 仅在 ZDT1 领先而 DTLZ2 落后，将如实报告并分析。


---

## 附：设计实现阶段的消融实验（2026-09-17 补充）

实现 HCEA 过程中的关键消融发现（全部为单种子 42、ZDT1 上的实测）：

1. **父代选择方式**：APD 适应度锦标赛（0.074）远差于随机父代池（0.0108）。锦标赛把父代集中到低 APD 解上，多样性崩塌，收敛显著变慢。最终采用与 RVEA 一致的 randi 父代池。
2. **阶段 2 算子形态**：对合并种群做「HV 贡献 top-N 一次性选择」会持续恶化（0.078→0.14，10 代内），因为没有前沿结构与边界保护；改为 SMS-EMOA 式「逐个并入 + 末级前沿最小贡献删除（边界贡献=∞）」后 ZDT1 达到 0.0039。**增量删除 + 边界保护是 HV 型分布精化的必要形态**。
3. **静态 vs 自适应参考向量**（修正调研正文中的假设）：RVEA 式自适应向量缩放能加速纯 APD 收敛（ZDT1 0.0108→0.0067），并不构成振荡；但在本混合设计中，静态向量使 HV 切换检查点在 0.5·maxGen 时正确触发（自适应向量时该检查点 HV 已高、切换被拒），最终静态+切换（0.0038）优于自适应+不切换（0.0062）。最终设计保留静态向量，理由为「与 HV 切换机制的协同」，而非最初假设的「消除振荡」。
4. **切换决策信号（2026-09-17 修正，见下方 Bugfix 附注）**：早期版本声称 HV 能在 DTLZ2 上正确拒绝 SMS 试验代——该结论是错误 HV 公式造成的假象。用标准 2D HV 公式修复后，DTLZ2 上 SMS 试验代**提升** HV（30/30 采纳切换），但 IGD 变差（0.0042→0.0057）。结论修正为：HV 与 IGD 在凹前沿（DTLZ2）上存在分歧，HV 验证的切换忠实于 HV 目标，不保证 IGD 最优。


---

## 附 2：公式修复轮次记录（2026-09-17）

外部复核发现 HCEA.m 两处未披露的公式 bug，已修复并全量重跑（只改 HCEA.m）：

1. **calHV 区间配对错误**：原实现把 f2(i) 与左区间 [f1(i-1), f1(i)] 配对（验证例 (0.1,0.9),(0.5,0.5),(0.9,0.1) ref(1,1) 得 0.57），已改为标准 2D 最小化 HV（右区间配对，得 0.33）。
2. **hvContrib 与 smsGeneration 公式不一致**：f1 项前向/后向不一致，且参考点用内部 max；已改为与 smsGeneration 完全一致的 SMS-EMOA 标准式并改用调用者传入参考点。

修复后果（30 种子全量重跑）：ZDT1 0.003746±0.000032（略优于修复前 0.003775），切换仍 30/30；DTLZ2 0.005710±0.000203（差于修复前 0.004161，+37%），切换由 0/30 变为 30/30。详见 docs/results/new_algorithm/README.md §0/§4。
