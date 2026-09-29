# 论文写作指南（docs/paper/）

> 目标：SCI 二区期刊英文论文初稿。数据全部来自 docs/results/metric_disagreement/ 与 docs/results/new_algorithm/ 的实测结果，禁止编造。

## 目录结构

- main.tex —— 论文框架（IEEEtran 双栏；若本机无 IEEEtran.cls，将 \documentclass[journal]{IEEEtran} 换成 \documentclass[10pt,twocolumn]{article} 并删除标 % IEEEtran 的行）
- tables/ —— Table1_datasets / Table2_igd / Table3_hv / Table4_ranks / Table5_friedman / Table6_wilcoxon / Table6b_wilcoxon_hv / Table7_runtime
- figures/ —— 6 张图（png + pdf 双版本）：fig1_boxplots（2 问题）、fig2_pareto_fronts（2 问题）、fig3_hcea_convergence（2 问题）、fig4_cd_igd、fig4_cd_hv、fig5_boxplots_5problems（5 问题）
- scripts/ —— compute_paper_numbers.m（数据→JSON）、gen_paper_figures.m（PDF 导出 + fig5）、paper_numbers.json
- 数字来源：paper_numbers.json 由 raw_data.mat + statistical_tests.mat 计算而来；Table 数值若需重算，先重跑 scripts/compute_paper_numbers.m，再按 scripts/ 里的说明重新生成 .tex（当前 .tex 由 Node 从 JSON 生成）。

## TODO 清单（main.tex 中所有 [TODO] 位置）

1. \author / \thanks / \markboth：作者、单位、通讯作者、基金号。
2. Related Work：补 2–3 篇/家族的真实引文（并核验书目信息）；补双存档/多阶段代表文献（two-stage two-archive TEVC 2024、multi-stage MaOEA Information Sciences 2021、FSM 多阶段 EA SWEVO 2025）与指标分歧相关文献。
3. Proposed Algorithm：补 Algorithm 1 伪代码（HCEA 的 apdGeneration / smsGeneration / 切换检查点 / polishHV 已有 MATLAB 实现可照抄结构）；补复杂度段落。
4. Experimental Setup：补硬件/OS/MATLAB 版本；说明 DTLZ2 参考前沿 NBI 与弧长均匀两个版本的使用位置。
5. Results：扩充逐问题叙述；把「参考前沿替换实验」（rho 0.57→0.63）形式化为一张表或附录。
6. Discussion：补「哪个指标适合何种决策场景」的讨论；把 HCEA 组件消融（锦标赛→randi、HV top-N→增量删除、静态向量 vs 自适应向量）做成消融表。
7. Conclusion：定稿润色。
8. 全局：最终换为 \bibliographystyle + \bibliography{references}（.bib 由已知 9 条 thebibliography 条目迁移即可）。

## 待补充的实验（提高录用率，按优先级）

1. **3 目标问题**（必补）：DTLZ2(12,3)、DTLZ7(12,3)（或 DTLZ1/DTLZ4）——需要 HCEA 的 HV 计算改为蒙特卡洛估算（SMSEMOA 的 calHV 可复用），并重跑 8 基线 + HCEA 各 30 种子。
2. **更多基线**：HypE、Two_Arch2、MaOEA-IGD、ARMOEA 等（至少 3 个近年算法）。
3. **更多问题/维度**：ZDT4/ZDT6、WFG 系列；D=50/100 的高维变体。
4. **收敛曲线图**：5 问题的逐代 IGD 曲线（当前只有 HCEA 在 2 问题上的曲线，fig3 需重制为 5 问题版）。
5. **参数灵敏度**：HCEA 的切换检查点（0.5/0.6/0.7）、theta 指数 alpha=2、HV 参考点 1.1 倍的灵敏度实验（对 3 个代表问题做即可）。
6. **统计**：如果补了 3 目标问题，Friedman 区组数 N 变大后 CD 会缩小，头部排序可能变得可分——这会影响摘要中"无显著差异"的表述，务必更新。
7. **真实应用**（可选）：1 个工程多目标问题（如 ZDT 之外的水资源/结构设计），证明实用性。

## 投稿建议期刊

SCI 二区候选（按主题契合度排序）：
1. Applied Intelligence（Springer，机器学习+进化计算交叉，录用快）
2. Neural Computing and Applications（Springer，Q2，收 MOEA 应用型工作）
3. Memetic Computing（Springer，进化计算专门刊，主题最契合）

SCI 三区候选：
1. Soft Computing（Springer）
2. Evolutionary Intelligence（Springer）
3. International Journal of Bio-Inspired Computation（Inderscience）

注意：分区每年变动（中科院分区表与 JCR 口径不同），投稿前请以最新分区表复核；本清单为 2026 年视角的建议。

## 写作红线（与数据一致）

- 不得声称 HCEA 显著优于 SMSEMOA/SPEA2：Nemenyi CD=5.37（5 区组）下头部 7 算法两两不可分，Wilcoxon 逐问题存在 ns 点（vs SPEA2@ZDT2 p=0.186；vs SMSEMOA@ZDT3 p=0.068、@DTLZ2 p=0.888）。
- HCEA 定位：第一梯队；ZDT3 双指标第 1；Friedman 秩 HV 1.8（第 2）/ IGD 2.8（第 3）；DTLZ2 IGD 第 6 为真实弱点，必须写进摘要与结论。
- 所有表格数值必须能从 raw_data.mat 重算（scripts/compute_paper_numbers.m），新增数据一律先入 raw_data 再进表。


## Ablation study（2026-09-17，docs/results/ablation/）

动机：审稿人可能质疑 HCEA 是"RVEA + SMS-EMOA + 开关"的拼接。为此对 4 组设计选择各做单变量消融（30 种子 × {ZDT1, DTLZ2}，popSize=100、maxGen=200，HV 参考点 1.1×max(PF) 与主实验一致；HCEA 数据复用主实验，不重跑）。

| 组 | 变体 | ZDT1 IGD | ZDT1 HV | DTLZ2 IGD | DTLZ2 HV |
|----|------|----------|---------|-----------|----------|
| 对照 | HCEA（主算法） | 0.003746 | 0.871551 | 0.005710 | 0.420931 |
| 1 父代选择 | HCEA-A1（APD 锦标赛） | 0.003946（+5.3%，方差 1.2e-3 增大） | 0.871347 | 0.005762（+0.9%） | 0.420939 |
| 2 机制 B 形态 | HCEA-B1（HV top-N 一次性） | **0.044478**（崩溃，std=0.075） | 0.833022（−4.4%） | **0.004030（≈D3 全程 APD，见结论）** | 0.420031 |
| 3 参考向量 | HCEA-C1（RVEA 式自适应） | 0.003746（+0.0%） | 0.871539 | 0.005743（+0.6%） | 0.420923 |
| 4 切换 | HCEA-D1（0.7G 固定必切） | 0.003833（+2.3%） | 0.871078 | 0.005742（+0.6%） | 0.420901 |
| 4 切换 | HCEA-D2（0.5G 固定必切） | 0.003746（≡ HCEA 完全一致） | 0.871551 | 0.005710（≡ HCEA） | 0.420931 |
| 4 切换 | HCEA-D3（全程 APD） | 0.006726（+80%） | 0.864478 | **0.004025（−29%，反优于 HCEA）** | 0.420024 |
| 4 切换 | HCEA-D4（全程 SMS） | **0.003689（−1.5%，反优于 HCEA）** | 0.871865 | 0.005848（+2.4%） | 0.420951 |

一句话结论（如实）：
- **组 1 证实（弱）**：randi 父代池优于 APD 锦标赛（ZDT1 +5.3% 且锦标赛方差增大 40 倍），DTLZ2 中性。
- **组 2 部分证实**：增量并入-删除在 ZDT1 上**必要**（top-N 一次性选择使 IGD 崩溃至 0.0445）。B1 在 DTLZ2 上 IGD 较低（0.004030）并非 top-N 机制的胜利：其 top-N 切换试验在 DTLZ2 上 3 次全被拒绝（nFE=20415），B1 实际退化为全程 APD（其 0.004030 与 D3 的 0.004025 相同）。
- **组 3 未证实性能必要性**：自适应向量与静态向量几乎无差别（<0.1%），静态向量保留的理由是"简单且不更差"，不是"更好"。
- **组 4 部分证实，且揭示关键事实**：① 切换本身必要（全程 APD 在 ZDT1 上恶化 80%）；② **HV 验证在本实验两个问题上从未拒绝**——HCEA-D2（0.5G 固定必切）与 HCEA 结果完全一致，即验证机制在此等价于 0.5G 固定切换（其价值是原理上的保险，不是这两个问题上的实测增益）；③ 单问题上全 SMS（ZDT1 0.003689）或全 APD（DTLZ2 0.004025）各自优于 HCEA——**HCEA 的真实价值是跨问题鲁棒性（两问题综合第一梯队），而非单问题最优**。这一表述比"每个组件都更优"更诚实、也更有审稿说服力。

- **如实说明（HV 验证与 HCEA 定位）**：HV 验证在 2 目标问题上从未拒绝切换（HCEA ≡ D2），因此该验证机制在本次实验范围内无实测增益，其价值是原理上的保险。HCEA 的真实价值是跨问题鲁棒性（两问题综合第一梯队），而非单问题最优。
产物：docs/results/ablation/{raw_ablation.mat, ablation_numbers.json, ablation_table.tex, ablation_barplot.png/.fig, run_ablation.m, gen_ablation_report.m}；变体源码：algorithms/ablation/HCEA_{A1,B1,C1,D1,D2,D3,D4}.m；主算法备份：algorithms/_archive/HCEA_main_backup_20260917.m。
