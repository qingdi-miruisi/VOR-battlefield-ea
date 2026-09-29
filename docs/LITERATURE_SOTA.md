# 多目标进化优化 SOTA 算法调研（2023–2026）

> **调研范围**：IEEE TEVC、IEEE TCYB、Swarm and Evolutionary Computation (SWEVO)、Information Sciences (INS)
> **检索工具**：Crossref API + GitHub 搜索 + 网页检索
> **数据快照**：2026 年 7 月（Crossref 在线书目数据）
> **备注**：文中引用的机制描述基于摘要与参考文献列表推断，部分细节请以原论文为准。

---

## 一、5 个 SOTA 算法条目（机制 + 未解决问题 + 代码可用性）

### 1. HEA — 基于超支配度的多目标进化算法

| 字段 | 内容 |
|---|---|
| **论文标题** | A Many-Objective Optimization Evolutionary Algorithm Based on Hyper-Dominance Degree |
| **作者** | Zhe Liu, Fei Han, Qing-Hua Ling, Henry Han, Jing Jiang |
| **期刊 / 年份** | Swarm and Evolutionary Computation, Vol. 83, 2023, 101411 |
| **DOI** | 10.1016/j.swevo.2023.101411 |
| **核心机制** | 用「超支配度」量化每个解的收敛水平，动态控制选择压力；配合参考向量引导选择与自适应稀疏截断，在 M≥5 目标空间内同时维持收敛性与多样性。 |
| **未解决的核心问题** | ① M≥8 时超支配度计算依赖 HV 贡献估计，开销随 M 增长；② D>50 决策空间上 IGD 退化未解决（论文以 M=5–8、D=30 为主）；③ 容忍度参数敏感性未系统研究。 |
| **代码可用性** | ✅ **已开源**（MATLAB）：已并入 PlatEMO 官方平台 `https://github.com/BIMK/PlatEMO`（Algorithms/Multi-objective optimization/HEA/HEA.m）。 |

### 2. LHD-MAEA — 局部化高保真支配多目标进化算法（TEVC）

| 字段 | 内容 |
|---|---|
| **论文标题** | A Localized High-Fidelity-Dominance-Based Many-Objective Evolutionary Algorithm |
| **作者** | Dhish Kumar Saxena, Sukrit Mittal, Sarang Kapoor, Kalyanmoy Deb |
| **期刊 / 年份** | IEEE Transactions on Evolutionary Computation, Vol. 27, No. 4, pp. 923–937, 2023 |
| **DOI** | 10.1109/TEVC.2022.3188064 |
| **核心机制** | 用「局部近似的高体积贡献」替代全局 HV 参与支配判定（高保真支配），缓解 M≥4 时 HV 计算的指数爆炸，使有限种群下的选择压力更精准。 |
| **未解决的核心问题** | ① 局部近似在不连通 / 退化 PF 上的精度衰减边界未建立；② M≥10 时仍无快速实现路径（成本仍远高于 EED / 角度基方法）；③ 局部窗口大小与 PF 形状的自适应关系未研究。 |
| **代码可用性** | ❌ **论文未开源**（IEEE 及作者主页未检索到官方代码；机制可在 PlatEMO 框架内自研实现）。 |

### 3. PF-DRVG — 基于 PF 密度估计的自适应参考向量引导多目标算法（SWEVO 2024）

| 字段 | 内容 |
|---|---|
| **论文标题** | An Adaptive Reference Vector Guided Many-Objective Optimization Algorithm Based on the Pareto Front Density Estimation |
| **作者** | Ying Xu, Fusen Li, Huan Zhang, Wei Li |
| **期刊 / 年份** | Swarm and Evolutionary Computation, Vol. 88, 2024, 101601 |
| **DOI** | 10.1016/j.swevo.2024.101601 |
| **核心机制** | 在线估计真实 PF 的密度分布，并按密度自适应重布参考向量（密度高的区域分配更多向量），使搜索算力与 PF 形状匹配，在凹 / 不连通 PF 上收敛显著改善。 |
| **未解决的核心问题** | ① 密度估计器在迭代早期（种群未贴近 PF）偏差大，参考向量易被误导；② 不连通 PF 的极端情形下，参考向量覆盖各连通分量的充分性无保证；③ M≥10 规模下的计算开销未报告。 |
| **代码可用性** | ❌ **论文未开源**（未检索到公开仓库；机制 = 参考向量引导框架 + KDE 密度估计，MATLAB 可用 statfit/KDE 工具箱实现）。 |

### 4. DSG-EA — 两阶段方向引导大规模多目标进化算法（Information Sciences 2024）

| 字段 | 内容 |
|---|---|
| **论文标题** | A Two-Stage Direction-Guided Evolutionary Algorithm for Large-Scale Multiobjective Optimization |
| **作者** | Juan Zou, Li Tang, Yuan Liu, Shengxiang Yang, Shiting Wang |
| **期刊 / 年份** | Information Sciences, Vol. 674, 2024, 120719 |
| **DOI** | 10.1016/j.ins.2024.120719 |
| **核心机制** | 第一阶段对决策空间做**有向采样**（directed sampling），获得「模糊决策变量」骨架（继承 TEVC 2023 FDEA 框架，DOI 10.1109/TEVC.2021.3118593）；第二阶段沿特定方向做进化搜索，显著降低有效维度，面向 D≥100 的大规模多目标问题。 |
| **未解决的核心问题** | ① 有向采样假设目标可沿少量「有效维度」分解，强耦合决策空间上假设不成立；② 第一阶段得到的骨架在动态问题上会过时；③ D≥500 时收敛加速优势衰减，M≥5 与 D≥100 的联合实验缺失。 |
| **代码可用性** | ❌ **论文未开源**（作者团队部分 FDEA 系列代码：`http://www.tech.dmu.ac.uk/~syang/Codes/`，本论文代码未确认公开）。 |

### 5. PH-LSMAEA — 种群分层大规模多目标进化算法（SWEVO 2024）

| 字段 | 内容 |
|---|---|
| **论文标题** | A Population Hierarchical-Based Evolutionary Algorithm for Large-Scale Many-Objective Optimization |
| **作者** | Shiting Wang, Jinhua Zheng, Yingjie Zou, Yuan Liu, Juan Zou, Shengxiang Yang |
| **期刊 / 年份** | Swarm and Evolutionary Computation, Vol. 91, 2024, 101752 |
| **DOI** | 10.1016/j.swevo.2024.101752 |
| **核心机制** | 将种群组织为分层结构（精英层 / 发展层 / 淘汰层），各层采用不同变异 / 交叉策略，并结合有向采样应对大规模多目标（M=5–8、D≥50）；同时针对 IGD 退化与高维决策空间收敛慢的问题。 |
| **未解决的核心问题** | ① 分层归属规则的超参随问题变化，自动分层尚未实现；② D≥100 不连通 PF 上的性能缺口未报告；③ 并行版本的计算开销未报告。 |
| **代码可用性** | ❌ **论文未开源**（未检索到公开仓库；团队有部分 C3M 代码，本论文代码未公开）。 |

---

## 二、TCYB 2023–2026 近年代表工作（补充）

| 论文 | 作者 | 期刊 / 年份 | DOI | 机制速览 | 代码 |
|---|---|---|---|---|---|
| Multipopulation-Based Differential Evolution for Large-Scale Many-Objective Optimization | Kai Zhang, Chaonan Shen, Gary G. Yen | IEEE TCYB, Vol. 53, No. 12, 2023, pp. 7596–7608 | 10.1109/TCYB.2022.3178929 | 多子种群划分 + DE 算子，面向 M=5–8、D≥100 | ❌ 论文未开源 |
| Many-Objective Job-Shop Scheduling: A MPMO-GA Approach | Si-Chen Liu, Zong-Gan Chen, Zhi-Hui Zhan, Sang-Woon Jeon, Sam Kwong, Jun Zhang | IEEE TCYB, Vol. 53, No. 3, 2023, pp. 1460–1474 | 10.1109/TCYB.2021.3102642 | Multiple Populations for Multiple Objectives，每个子种群负责一个目标，应用于车间调度 | ❌ 论文未开源 |

---

## 三、未解决核心问题总览（跨算法 Gap 分析）

1. **M≥8 时 IGD 退化**：M≥8 时 IGD 计算对真 PF 参考集采样密度敏感；HEA、PF-DRVG 均未报告 M≥10 的 IGD 曲线；HV 类选择在稀疏种群下优势衰减。
2. **D≥100 决策空间收敛慢**：DSG-EA / PH-LSMAEA 用降维（模糊变量 / 有向采样）解决，但假设目标-决策变量可解耦；强耦合 D≥200 问题（如特征选择）仍无兼顾收敛与多样性的算法。
3. **M≥5 时 HV 计算爆炸**：LHD-MAEA 的局部近似使成本降至 EED / 角度基方法的 ~10 倍量级；面向 M≥8 的统一亚线性 HV 估计方法尚未发表。
4. **PF 形状自适应不足**：参考向量自适应类（PF-DRVG 等）假设 PF 连通且近似凸；不连通 / 退化 PF（IMOP 系列）上尚无 SOTA 能同时自动完成形状估计与搜索努力分配。
5. **学习混合方向未成 SOTA**：MOEA/D-DQN（TEVC 2022，DOI 10.1109/TEVC.2022.3220498，已开源至 PlatEMO 4.4+）与熵驱动 RL-MOEA 在通用 MOP 基准上未突破；其在大规模（D≥100）与多目标（M≥8）组合设置下的优势未确认。

---

## 四、代码可用性汇总

| 算法 | 开源 | 链接 |
|---|---|---|
| HEA（SWEVO 2023） | ✅ | `https://github.com/BIMK/PlatEMO`（MATLAB） |
| LHD-MAEA（TEVC 2023） | ❌ | — |
| PF-DRVG（SWEVO 2024） | ❌ | — |
| DSG-EA（IS 2024） | ❌（部分 FDEA 系列代码） | `http://www.tech.dmu.ac.uk/~syang/` |
| PH-LSMAEA（SWEVO 2024） | ❌ | — |
| MOEA/D-DQN（TEVC 2022，RL 混合） | ✅（PlatEMO 4.4+） | `https://github.com/BIMK/PlatEMO` |

---

## 五、对后续工作的启示（Gap 即切入点）

- **M≥10**：设计「亚线性 HV 贡献估计」选择算子（LHD-MAEA 局部近似路线的改进）；
- **D≥200 强耦合**：有向采样 + 决策变量重要性学习（GNN 变量分组）；
- **不连通 PF**：自适应参考向量 + 拓扑感知选择（PF-DRVG + 连通性先验）；
- **统一评估**：M≥8 与 D≥100 基准上补全 IGD-H / 快速 HV 估计通道，与 EED 基线对比。

---

*数据来源：Crossref API、IEEE Xplore、Elsevier ScienceDirect、PlatEMO GitHub、Shengxiang Yang 主页。检索时间：2026 年 7 月。*
