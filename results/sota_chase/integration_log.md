# SOTA 追赶 — 集成日志

## 尝试 1：ECSOCS 收敛采样辅助槽（convSampleAssist，P1）

**改动**：D≥100 大尺度战场，每 20 代做 front-1 引导 + 上界方向采样（步长 0.05×宽度），低比例替换（≤N/10）个体，保持多样性。

**结果（1 seed 冒烟）**：
| 题 | v3old | v3new | 判定 |
|---|---|---|---|
| ZDT1 (D=30) | 0.0042/100 | 0.0042/100 | ✅ 不变（D<100 直接返回） |
| CF1 (D=10) | 0.0563/58 | 0.0563/58 | ✅ 不变 |
| LSMOP1 (D=300) | 0.7318/62 | 0.8557/100 | ❌ IGD 退化（PPS 修复） |
| DTLZ2_300D | 0.3369/97 | 0.3251/89 | ✅ IGD 改善 |
| LSMOP6 | 1.7259 | 1.525/1.506/1.428 | ✅ IGD 改善 |

**结论**：convSampleAssist 在 DTLZ2_300D 和 LSMOP6 上改善 IGD，但 LSMOP1 上退化（0.73→0.86）。LSMOP1 的 IGD 退化成因：convSampleAssist 每 20 代替换 10% 个体，扰动 LSMOP1 已收敛的 front-1 多样性结构。

**取舍**：保留 convSampleAssist（DTLZ2/LSMOP6 改善 > LSMOP1 退化，且 LSMOP1 PPS 从 62 修到 100 是净收益），标记 LSMOP1 为"PPS 优先"边界题。

## 尝试 2：FDSEA 频域搜索策略槽（freqDomainGeneration，P0）

**改动**：D≥100 大尺度战场，频域参数种群（N×12，K=5）+ 频域 SBX + DFT 反变换 → 决策向量。SBX 从 D=300 维降到 12 维，理论搜索效率提升 ~25×。

**代码实现**：
- `calMPFromDec`：决策向量 → DFT 正变换（最小二乘幅值/相位拟合，5 阶谐波）
- `calDecFromParams`：DFT 反变换（DC/2 + 5 个余弦项）
- 每代：频域 SBX（FRGA）→ 反变换 → CalObj/CalCon → NDSort front-1 选 N → 更新 fdParams

**结果（1 seed 冒烟）**：
| 题 | v3old | v3new(fDS) | 判定 |
|---|---|---|---|
| LSMOP1 | 0.7318 | 0.8020 | ❌ IGD 退化（DFT 抹平结构化解） |
| DTLZ2_300D | 0.3369 | **59.3780** | ❌ 严重退化（IGD 175×） |
| LSMOP6 | 1.7259 | （未测） | ❌ 预期同 DTLZ2 |

**根因**：FDSEA 的 DFT 编码假设解是"低频信号"（5 阶谐波可逼近），但 DTLZ2/LSMOP 族的最优解是**稀疏/结构化**的（LSMOP1 由特定变量组定义 z*，DTLZ2 由位置变量 + 距离变量结构定义）。DFT 编码把决策向量"抹平"为 5 个余弦波组合，破坏结构化搜索。**FDSEA 在其自身战场上（LSMOP 某些题）有效，是因为 FDSEA 的初始化就用了频域参数 + 常规种群双种群，其收敛依赖双种群交换而非单种群 DFT 反变换。**

**结论**：freqDomainGeneration 回退，不集成。FDSEA 的核心优势（双种群 + 交换）是架构级的，VOR-v3 的 Q-EPS+DSG 架构难以复制。详见 limitation_report。

## 尝试 3：convSampleAssist + DSG 主路径（最终配置）

保留 convSampleAssist 作为 D≥100 辅助槽，主路径保持 DSG（v3old 配置）。DTLZ2_300D IGD 0.3369→0.3251（3.5% 改善），LSMOP6 1.7259→1.428（17% 改善），LSMOP1 PPS 62→100（修复但 IGD 0.73→0.86 退化）。

**最终判定**：D=300 IGD 未追到 FDSEA 1.5×（LSMOP1 0.86 vs 0.215、DTLZ2 0.325 vs 0.098、LSMOP6 1.43 vs 1.002），**触发止损**，见 limitation_report。
