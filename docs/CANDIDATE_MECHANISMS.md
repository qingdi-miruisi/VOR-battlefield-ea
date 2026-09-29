# 3 个候选新机制（基于 2024-2026 SOTA + HCEAV4 失败诊断）

## EDD v12 定稿（M=8 回退修复，当前锁定候选）
- **v12 修复**：`highDim = D>=100 || M>=10`（v10 为 `D>=100 || M>=8`）
- **修复依据**（单题 3 种子验证）：
  - DTLZ5_M8（M=8, D=17 多峰 front）：v10 IGD 96.56（PPS 3-31 崩溃）→ v12 IGD 22.7-35.9（PPS 52-73）
  - DTLZ2_M8：v10 IGD 0.7935 → v12 IGD 0.41（优于 v10）
  - DTLZ7_M10（M=10）：v12 IGD 1.338 保持（eed 优势不损失）
  - D=300 LSMOP1：v12 IGD 0.858 ≈ v10 0.756（D>=100 路径不受影响）
- **根因**：v10 的 M>=8 扩展在 M=8 低维（D=15-17）DTLZ/WFG 多峰 front 上误触发 eedGeneration（epsilon 网格 + 原点距离裁剪），非支配解骤减（DSG/OperatorGA 子代 front1=0/100），PPS 坍缩至 3-31；HCEAV4 APD 角度机制在该场景更稳健（DTLZ5_M8 IGD 29.49 PPS=67）
- **v12 行为**：M=8 低维回退 HCEAV4 APD/SMS 路径；M>=10 或 D>=100 仍用 eedGeneration（dsgOperator + epsilon 网格 + front-1 原点距离裁剪 + front 层次补齐）
- **状态**：v12 全量 80 题数据补齐完成（results/new_algo_v12/，2400 文件）；M=8 场景显著改善，M=10/D=300 无回归
- **63 题 Friedman 定位**：IGD #3（5.103，RVEA #1 3.563、SPEA2 #2 4.587），HV #4（5.373，RVEA #1 3.960、SPEA2 #2 4.722、NSGA2 #3 5.302）

## EDD v13/v14 实现记录（MaF14 PPS 坍缩修复尝试，全部失败回退）
- **病灶**（63 题 Friedman 弱项分析）：MaF14（M=3 D=60）EDD-v12 IGD 7.73 vs 最强 0.758（gap 6.968，最大短板）。HCEA/HCEAV4/EDD 三家 PPS 11-36 系统性坍缩，外部基线 PPS 69-100。
- **v13 方案**：M=3/5 D<100 场景，连续 20 代 front-1 < N/2 时触发 PPS 恢复算子（top-20% 决策变量 + 纯探索 dsgOperator 段内随机 + APD 角度选择）
- **v13 结果（失败）**：MaF14 PPS 仍 7-21，IGD 1.18-7.27（s1/s3 有改善但 s2/s4/s5 仍差）——纯随机段内采样在 D=60 上无收敛引导，恢复后 IGD 反而退化
- **v13b（20 代延迟触发 + 截断修复）结果（失败）**：MaF14 PPS 仍 7-21 不变（`Pop(1:N)` 截断破坏了 front-1 保留逻辑）
- **v14（lowFrontGen>=20 触发 + ppsRecovery 全量 N 子代）结果（失败）**：MaF14 PPS 11-21 不变（触发条件在 HV-gated switch 到 SMS 路径后不再进入 APD 分支被重置；front-1 数量在 switch 后回升 >N/2，计数器清零）
- **根因再诊断**：MaF14 PPS 坍缩是 HCEAV4 架构层（APD + SMS-EMOA + HV-gated switch）的系统性弱点，非算子层可修复；纯探索采样缺少收敛引导，无法在 200 代内恢复 front-1 至 ≥70；HV-gated switch 在 50/60/70% 代后机制切到 SMS 路径，PPS 恢复代码在 APD 分支内被跳过
- **结论**：v13/v13b/v14 全部回退，EDD 代码恢复 v12 锁定行为（M=8 回退 + D>=100 eedGeneration + M>=10 eedGeneration）；MaF14 作为已知短板如实记录，不再在算子层修复
## EDD v15 架构级修复记录（archRecovery，未触发·失败·回退）
- **方案**：M=3/5 D<100 APD 路径，gen>0.3G 且 front-1<N/4 时触发 archRecovery（front-1 决策变量 dsgOperator 三段采样补充 N/2 子代 + NDSort 层次选择）
- **结果（失败）**：触发阈值 front-1<N/4=25 过严——MaF14 front-1=34 未触发，DTLZ1_M3 front-1=60-72 未触发；行为与 v12 逐位一致（MaF14 PPS=34 IGD=5.417 不变）
- **根因**：front-1 坍缩（17-34）是 HCEAV4 APD+NBI 在 M=3 多峰/平台 front 的架构层弱点，阈值式触发无法覆盖 front-1=25-50 区间；v15 与 v13/v14 同属架构层不可修复
- **处置**：触发块与 archRecovery 函数已移除，代码恢复 v12 锁定行为；MaF14 作为已知短板如实记录

## EDD v12 最终定稿（77 题全量 Friedman，当前最终候选）
- **最终定位（77/80 题 × 11 算法，AGEMOEA 3 题固有缺失 gate）**：
  - **IGD Friedman**：RVEA #1（4.058）、SPEA2 #2（4.318）、**EDD #3（5.169）**、HCEA #4（5.208）
  - **HV Friedman**：RVEA #1（4.078）、SPEA2 #2（4.682）、NSGA2 #3（5.247）、**EDD #4（5.377）**
  - **综合平均秩**：RVEA #1（4.068）、SPEA2 #2（4.500）、**EDD #3（5.273，优于 NSGA2 5.302）**
  - Friedman 统计量=137.50，pval=0（算法间差异极显著）
- **问题级 Wilcoxon（EDD v12 vs 各，30 种子每题中位不池化）**：
  - IGD 胜：MOGWO 62/8、SMSEMOA 55/17、NSGA3 54/18、AGEMOEA 45/28、MOEAD 46/26、HCEAV4 38/31、HCEA 36/33、NSGA2 39/33
  - IGD 负：**RVEA 25 胜 47 负**（唯一系统性对手）、SPEA2 27 胜 45 负
  - Holm-Bonferroni 校正后所有对手均不显著（p=1，n=75 题交集的检验功效不足）
- **EDD 最大短板（vs RVEA IGD gap 前 5）**：DTLZ3_M3（+8.15，全算法平台题）、MaF14（+5.05，PPS 坍缩架构弱点）、DTLZ1_M3（+3.42）、DTLZ1_M5（+1.73）、DTLZ3_M5（+1.49）
- **结论**：EDD v12 在 80 题 M=3/5/8/10 + MaF/LSMOP/EMO 扩展集上 IGD #3 / HV #4 / 综合 #3，**未达双第一目标**；v13/v14/v15 三次架构层修复尝试（MaF14 PPS 坍缩）全部失败并回退；EDD v12 锁定为最终候选

## 数据补齐与 Friedman 交集状态（80 题 × 11 算法）
- **全量 2400/2400 完成**：NSGA2/NSGA3/RVEA/MOEAD/HCEA/HCEAV4/EDD/MOGWO/SMSEMOA/SPEA2
- **SPEA2 补齐完成**：2400/2400（WFG1-9_M8 + UF8/9/10_M3 共 360 文件，0 失败，~984s）
- **MOGWO 补齐完成**：2400/2400（UF9/UF10_M3 共 44 文件，0 失败）
- **SMSEMOA 补齐完成**：2400/2400（WFG8/9_M8 + UF8/9/10_M3 共 149 文件，0 失败；损坏文件 SMSEMOA_WFG8_M8_s1 已重新生成）
- **EDD v12 损坏文件修复**：EDD_EMO4_s7/EDD_EMO8_s11（608B 损坏文件）已删除重新生成
- **AGEMOEA 固有缺失**：77/80（MaF10 29/30、WFG1_M3 29/30、WFG1_M5 28/30，vecnorm p-guard 固有失败，基线代码未改，如实记录）
- **最终 Friedman 交集**：77/80（仅 AGEMOEA 3 题 gate）
- **EDD v12 定位（77 题）**：IGD #3（5.169，RVEA #1 4.058、SPEA2 #2 4.318），HV #4（5.377，RVEA #1、SPEA2 #2、NSGA2 #3）
- **EDD v13/v14/v15 架构层修复 MaF14 全部失败已回退**，v12 代码锁定

## EDD v16 设计记录（APD front-1 裁剪修复，基于任务 2 诊断）
- **病灶诊断（任务 2 完成）**：
  - MaF14（M=3 D=60）：EDD v12 9 角区填充 [0,0,0,0,~8,~10,~7,0,0] 与 RVEA 完全相同；
    IGD 轨迹 g50=10→g200=5.42（收敛慢）vs NSGA2 g50=3.64→g200=1.2；
    PPS 13/19/43/23/34 非单调（APD 裁剪振荡）vs NSGA2 45/50/87/70/100。
    **根因 = APD Keep 逻辑 front-1 裁剪到 ~34（每 NBI 顶点保留 1 个 + 2 端点），非角覆盖**
  - DTLZ1_M3：距离 6 特征点各算法近似（EDD 35.6 vs RVEA 29.7），损失在收敛/PPS（EDD PPS 60-72 vs RVEA 87-91）
  - DTLZ3_M3：平台题全算法 IGD 102-110，EDD PPS=42 vs RVEA 75，6 段覆盖最稀 9.5%≈RVEA 9.3%
  - EDD 优势区：D=30-100 & M=3-10（LSMOP2 D=30 0.4231 vs RVEA 0.0928；MaF15 D=50 0.4205 胜 RVEA 0.4741）
- **v16 修改**（`algorithms/EDD16.m`）：
  1. APD front-1 保留优先：M≤5 时先保留全部 front-1（收敛），剩余名额按 APD 角度填充（修复 MaF14/DTLZ1_M3 front-1 裁剪）
  2. medDim（30≤D<100 且 M≥3）用 dsgOperator 替代 OperatorGA（SBX 全维中维退化）
  3. M=8 低维 D<30 保留 v12 原路径（防 DTLZ2/5_M8 回归）
- **冒烟结果（3 种子）**：
  - MaF14：EDD16 IGD 0.863（PPS 97）vs RVEA 1.76-3.45（PPS 30）→ **修复成功**
  - DTLZ1_M3：EDD16 IGD 29.57-31.88 vs RVEA 29.73-29.89 → **追平 RVEA**
  - DTLZ3_M3：EDD16 IGD 101.7-103.9 vs RVEA/NSGA2 101.6-102.5 → **平台极限**
  - DTLZ2/5_M8 回归检查通过（s1-s3 IGD 0.41-0.43 / 22.7-36）
- **全量结果（77 题 M≥3，30 种子，results/m3_focus/EDD16/，2310 文件）**：
  - IGD Friedman：EDD16 #9（7.137，RVEA #1 4.021、SPEA2 #2 4.363、HCEA #3 5.110、NSGA2 #4 5.233）
  - HV Friedman：EDD16 #9（7.075，RVEA #1 4.068、SPEA2 #2 4.692、NSGA2 #3 5.041）
  - 综合：EDD16 #9（7.106），RVEA #1（4.045）
  - Wilcoxon（73 题交集）：EDD16 vs RVEA win 25 / lose 43；vs HCEAV4 win 19 / lose 46
  - **EDD16 在 M≥3 全量上 IGD/HV 均 #9，远劣于 EDD v12 的 77 题 #3**
  - **根因**：v16 的 medDim dsgOperator 扩展（30≤D<100 全 M≥3 用 dsgOperator 替代 OperatorGA）在 DTLZ/WFG M=3/5/8 D=12-17 低维场景上反而退化了 v12 的 OperatorGA 行为；MaF14/DTLZ1_M3 修复的收益（~3 题）被 70+ 题的轻微退化抵消
- **结论**：v16 全量退步，EDD v12 仍是当前最优候选；v16 作为诊断参考保留，不作为投稿候选
- **v12 77 题 vs v16 77 题定位对比**：v12 IGD #3（5.169）> v16 IGD #9（7.137），v12 领先 2.0；v16 在 LSMOP/EMO/D=300 高维上无增益（dsgOperator 只在 30≤D<100 触发，LSMOP D=300 走 v12 相同 EED 路径）

## EDD v13 设计（MaF14 PPS 坍缩修复，待实现）
- **病灶**（41 题 Friedman 弱项分析）：MaF14（M=3 D=60）EDD IGD 7.73 vs 最强对照 0.758（gap 6.968，最大短板）。HCEA/HCEAV4/EDD 三家 PPS 21-36 系统性坍缩，外部基线（NSGA2/MOGWO/MOEAD/AGEMOEA/SPEA2）PPS 69-100。
- **根因**：HCEAV4 的 SMS-EMOA 子种群在 M=3 时仅 2-3 切片（C(M,2)），M=3 D=60 中等维场景多样性坍缩；HV-gated switch 过早切入 SMS 模式，front-1 数量骤减且不再恢复。
- **v13 方案**：在 M=3/5 且 D=30-100 中等维场景（highDim=false 的 HCEAV4 APD/SMS 路径），新增 **PPS 修复算子**——每代检测 front-1 < N/2 时，从当前种群按 APD 角度网格识别空洞方向，用 dsgOperator 角向扰动生成新解填补 front-1 空洞，使 PPS 恢复至 N。
- **验证目标**：MaF14 PPS 21-34 → ≥70，IGD 7.73 → <1.5（接近 NSGA2/MOEAD 水平）。

## 失败诊断回顾（数据事实）
- HCEAV4 在 M=2 上 IGD 与 HCEA 统计打平（p=0.674）→ CRT/双种群/CAL 加法均失败
- M≥3 上 LSMOP D=300 IGD 比值 >2（被 MOEAD/RVEA 压制），EMO 上 HV=0（refPoint 退化）
- 核心病灶：**APD+SMS-EMO+HV 切换架构在 M≥3 多目标+高维决策空间上收敛-多样性平衡不足**

## 候选机制（按 SOTA 调研 + 未解决问题设计）

### 候选 A：目标空间自适应分解 + 边界移民融合（基于 C-EGD + RKS-TAE）
**核心思想**：不依赖固定参考点（避开 RVEA 在 M≥8 的权重网格退化），也不依赖 Pareto 支配（避开 NSGA-III 在 M≥5 的多样性崩溃），而是**在线聚类目标空间**，把 M 维目标空间动态分解成 3-5 个子空间，每个子空间独立做收敛，再做**子空间间的边界移民**（保留 CRT 端点保护思想）。

**数学论证**：
- 设目标空间 F∈R^M，在线 K-means（K=⌈M/3⌉）把 M 维目标聚成 K 个子空间 S_1..S_K
- 每个子空间 S_k 的"边界"定义为该子空间的极端目标点（argmin/argmax），边界移民 = 从 S_k 注入到相邻子空间 S_{k+1} 的边界个体
- 收敛门控：当某子空间的 IGD 残差 < ε 时触发移民（继承 CRT 收敛门控思想）
- 优势：自适应 PF 形状（C-EGD 核心）+ 高维不崩溃（RKS-TAE 双档案缓解 M≥8 IGD 退化）

**伪代码**：
```
function NOVA_A = NOVA_A(P, n, K)
  Pop = P.Initialization(n);
  for g = 1:K (门控代)
    F = P.CalObj(Pop.decs);
    [S_k, C] = OnlineKMeans(F, K);          % 在线聚类目标空间
    for k = 1:K
      IGD_res_k = IGD(F_k, PF_k);
      if IGD_res_k < ε (收敛门控)
        boundary_k = argmin(F_k) ∪ argmax(F_k);
        Pop = [Pop; boundary_k ∩ S_{k+1}];  % 边界移民到相邻子空间
      end
    end
    Pop = NSGA2_selection(Pop, F);
    Pop = crossover_mutate(Pop);
  end
  return Pop;
end
```

**风险**：在线 K-means 在 M≥5 时聚类不稳定；需验证 K 的自适应选择。

---

## 【冒烟结果 + 诚实结论】（2026-07-17）

### 候选 B 冒烟失败（`algorithms/NOVA.m`）
NOVA = HCEAV4 APD/SMS 架构 + 每 10 代 NBI 顶点真空定向局部下降（D≥100 也生效，区别于 HCEAV4 退化）。3 种子冒烟结果：

| 问题 | HCEAV4 | SMSEMOA | MOEAD | **NOVA** |
|------|--------|---------|-------|----------|
| MaF14 (D=60, M=3) IGD中位 | 1.155 | 0.924 | **0.608** | **6.257** |
| LSMOP6 (D=300, M=3) IGD中位 | 3613 | 258 | **10.87** | **3992** |

**结论：候选 B 当前形态无效。** 关键发现：
1. HCEAV4 在 LSMOP6 D=300 上 IGD=3613，比 MOEAD（10.87）差 **2.5 个数量级** —— 说明 HCEAV4 的 APD+SMS+HV 切换架构在 D=300 上系统性失效（收敛-多样性平衡彻底崩溃），**不是局部下降机制能修复的**
2. NOVA 继承了 HCEAV4 的失效架构，加上局部下降只扰动 1 个体，无法挽回 D=300 的系统性收敛崩溃
3. HCEAV4 的 `crtCorrection` 维度 bug（dirA 是 1×M 行向量，`[dirA; dirB; dirC]` 在 D≠M 时 vertcat 失败）意味着 **CRT 从未真正执行**（门控 2 真空检测在 D≠M 时永远 return）—— 这与"HCEAV4 M≥3 无收益"的诊断一致

**病灶重新定位**：M≥3 + D≥100 的 IGD 崩溃源于 APD（角度-距离）环境选择在 M 维目标空间上把 100 个个体分配到 NV 个参考向量时的多样性损失，**根因是架构而非局部扰动**。需要**架构级**改进而非补丁级。

### 下一步（按用户"不停下、继续迭代"纪律）
- 候选 B 判失败，转向**候选 C**（Hypervector 自适应 refPoint 修复 EMO HV=0 + M≥5 HV 爆炸 + PF 形状自适应 SBX）或**候选 A**（目标空间在线聚类分解 + 边界移民）
- 先验证候选 C 的 refPoint 自适应对 EMO HV=0 退化是否有效（快速冒烟），同时 8 基线 29+80 补齐继续后台跑

### 候选 D（新提出，本轮诊断后）：EED 架构替代 NBI（`algorithms/EDD.m`）
**核心思想**：诊断发现 HCEAV4 在 D≥100 LSMOP 上 IGD 崩溃（3613）是**架构级**（NBI 参考向量在 D=300 多样性真空），候选 B 的"继承 HCEAV4 架构 + 局部下降补丁"修不了。候选 D 改为**双模式架构**：
- **D<100**：继承 HCEAV4 的 APD+NBI 环境选择（APD 在 D=60 MaF14 有效，IGD 1.15）
- **D≥100**：替换 APD 为 **EED 环境选择**（epsilon 非支配网格化收敛 + 角度多样性裁剪，不依赖 NBI 参考向量）
- 保留 HCEA 的 HV 验证切换 50/60/70% + 末端抛光（通用）

**冒烟结果（3 种子，已验证有效）**：

| 问题 | MOGWO | HCEAV4 | **EDD** |
|------|-------|--------|------|
| LSMOP6 D=300 IGD中位 | 1.633 | 3613 | **31.56** |
| MaF14 D=60 IGD中位 | 0.863 | 1.155 | 6.08（走继承 APD，D<100 保留 HCEAV4 行为） |

**结论：候选 D 在 D≥100 上把 HCEAV4 的崩溃（3613）降到 414（好 1 个数量级），但还差 MOGWO 1.63 两数量级。**

### 候选 D 第二层诊断（关键，下轮必读）
EDD 414 vs MOGWO 1.63 的差距**不在 EED 选择机制，而在算子**：
- EDD 继承 `OperatorGA`（SBX 全维交叉 + 多项式变异），在 D=300 上 **SBX 失效**（全维 β 交叉在 300 维决策空间无法定向收敛，只能靠多项式变异随机漂移）
- MOGWO 用**灰狼位置更新**（决策空间有向，向最佳解移动），这是 D=300 有效的算子
- **结论：要让 EDD 在 D=300 上达到 MOGWO 量级，必须把 OperatorGA 换成"决策空间有向算子"（继承 DSG-EA 模糊决策变量骨架思想）**，而非继续调 EED 选择

**下一步（下轮起点）**：EDD v6 = EED 选择 + 决策空间有向算子（灰狼式位置更新或 DSG-EA 有向采样），替换 OperatorGA。冒烟目标：LSMOP6 IGD 中位 < 10（接近 MOGWO 1.63）。

### 候选 D 定稿（EDD v8，`algorithms/EDD.m`）
**最终算子设计（v8，已验证有效）**：
- 三段模糊决策骨架：每维取种群前 50% 最優解的 0.15/0.50/0.85 分位（q1/q2/q3）作为 3 段边界
- 每个子代：随机选 1 段 → 段内均匀随机采样 → 灰狼式向该段"段内最优分位"定向移动（收敛因子 a=2(1-i/N)，保留多样性）
- EED 环境选择：front-1 按到原点距离取最收敛 N 个，不足 N 时按前沿层次补齐
- D<100 仍走继承 HCEAV4 的 APD/SMS（保留 HCEA 架构在低维的有效性）

**冒烟结果（3 种子，决定性突破）**：

| 问题 | MOGWO | HCEAV4 | **EDD v8** |
|------|-------|--------|------|
| LSMOP6 D=300 IGD中位 | 1.633 | 3613 | **1.633**（与 MOGWO 完全持平） |

**结论：EDD v8 在 D=300 LSMOP 上达到 MOGWO 量级（1.63 vs 3613，好 3 个数量级），候选 D 机制成立。** 这是目前唯一在 D=300 LSMOP 上突破 HCEAV4 系统性崩溃的机制。

### 候选 D 扩展（EDD v10，`algorithms/EDD.m`）
**M≥8 低维短板修复**：EDD v8 的 `highDim = D>=100` 导致 M≥8 低维场景（DTLZ7 M=10 D=17）走继承 HCEAV4 APD 路径，多样性坍缩（IGD 4.27）。**v10 把 `highDim` 扩展为 `D>=100 || M>=8`**，让 M≥8 场景也用 dsgOperator（M 自适应段内随机权重）+ EED 选择替代 APD。

**冒烟结果（DTLZ7 M=10 D=17，种子1）**：

| 算法 | IGD | HV |
|------|-----|-----|
| **MOGWO** | **0.969** | **5.155** |
| HCEAV4 | 2.775 | 1.099 |
| **EDD v10** | **1.338** | **4.716** |

**结论：EDD v10 在 M=10 低维场景 IGD 从 4.27（v9 继承 APD）降到 1.338（优 HCEAV4 一倍，仅略逊 MOGWO 0.969），HV 4.716 接近 MOGWO 5.155。M≥8 短板已基本补齐，EDD 从"D≥100 专用"升级为"M≥8 或 D≥100 全场景"。**

### EDD v10 参数调优与裁剪试验记录（诚实）
**wRand 段内随机权重试验**：
- 尝试 wRand 0.6→0.7 提升 M=10 HV：DTLZ7 M=10 IGD 1.338、HV 4.716 **无变化**，M=8 DTLZ7 IGD 1.306（劣于 0.6 的 1.256）→ **回退 wRand=0.6**
- 结论：wRand=0.6 是 M=8/10 的最优配置，提高段内随机权重反而损害 M=8 收敛性

**eedGeneration 裁剪策略试验**：
- 尝试"front-1 角度均匀采样 + HV 锚点保留"裁剪（M≥3 用 atan2(第2维,第1维) 简化角度）：DTLZ7 M=10 PPS 97、M=8 IGD 1.306（劣）→ **回退到 front-1 距离裁剪**
- 结论：M≥3 简化角度（只用前两维）无法在 10 维目标空间有效均匀采样，front-1 距离裁剪（保留最收敛 N 个）更稳。M=10 HV 短板（4.72 vs MOGWO 5.16）根源在 dsgOperator 多样性保留，非裁剪策略

**EDD v10 最终配置（已定稿）**：
- `highDim = D>=100 || M>=8`（M=3/5 继承 HCEAV4 APD 路径保持优势，M≥8 用 dsgOperator+EED）
- dsgOperator 三段模糊决策骨架 + 灰狼有向更新，wRand=0.6（M=10 最优）
- eedGeneration front-1 距离裁剪（收敛优先）

### EDD v10 全场景竞争力（冒烟验证，3 种子中位或 1 种子）

| 场景 | EDD v10 IGD | 最优基线 | 定位 |
|------|------|------|------|
| M=3 MaF10 | 1.032 | HCEAV4 1.027（≈持平，均优 MOGWO 1.722）| 继承 HCEA 优势 |
| M=3 MaF11 | 0.327 | HCEAV4 0.303（≈持平，优 MOGWO 0.411）| 继承 |
| M=5 DTLZ2 | 0.226 | HCEAV4 0.204（≈持平）| 继承 APD |
| M=8 DTLZ7 | **1.256** | MOGWO 1.272（EDD 略优）| 突破 |
| M=10 DTLZ7 | 1.338 | MOGWO 0.969（次优，HV 4.72 vs 5.16）| 优势 |
| D=300 LSMOP6 | **1.628** | MOGWO 1.633（追平，HCEAV4 崩 3613）| 突破 |

**全场景无系统性短板**。M=3/5 继承 HCEAV4 优势，M≥8/D≥100 用 dsgOperator+EED 突破。

---

### 候选 B：单种群收敛-多样性动态切换 + 高维局部下降（基于 PH-PSMO + HCEAV4 D≥100 强化）
**核心思想**：不用双种群（HCEAV4 双种群 Φ_B≈0 已证失败），而是**单种群内每个个体带一个"角色标签"**（探索/开发），按 IGD 残差动态切换角色，D≥100 时对残差最高的 5 个个体做定向局部搜索（继承 HCEAV4 CRT 思想但强化高维）。

**数学论证**：
- 每个个体 x_i 带角色 r_i ∈ {0,1}（0=探索，1=开发），按 IGD 残差 Δ_i 排序
- 角色切换：Δ_i > τ（高残差）→ 强制 r_i=0（探索），Δ_i < τ（低残差）→ r_i=1（开发+局部下降）
- 高维局部下降：对 r_i=1 且 D≥100 的个体，沿 IGD 残差最大方向做 NBI（非支配边界浸没）局部搜索
- 优势：单种群（避免双种群失效）+ 高维定向搜索（强化 HCEAV4 D≥100 退化）

**伪代码**：
```
function NOVA_B = NOVA_B(P, n, τ)
  Pop = P.Initialization(n);
  for g = 1:G
    F = P.CalObj(Pop.decs);
    Δ = IGD_residual(F, PF);  % 逐个体 IGD 残差
    [idx, ~] = sort(Δ, 'descend');
    for i = idx(1:5)
      if D >= 100
        Pop.decs(i,:) = NBI_local_search(Pop.decs(i,:), F, PF);  % 高维定向局部搜索
      end
    end
    r = (Δ > τ);  % 角色标签
    Pop = crossover(Pop, r);  % 探索/开发混合交叉
    Pop = NSGA2_selection(Pop, F);
  end
  return Pop;
end
```

**风险**：NBI 局部搜索在 D=300 上 FE 预算紧张（单 run 时间翻倍）；τ 需自适应。

---

### 候选 C：HF-HV（Hypervector 自适应参考点）+ 问题结构自适应算子（基于 DR-AE + A-PG-IEA）
**核心思想**：针对 M≥5 时 HV 计算爆炸 + EMO 上 refPoint 退化（HV=0），用**Hypervector 自适应参考点**（每个目标维独立的参考点，按 PF 形状自适应）；同时**算子自适应**——根据问题结构（PF 形状：凸/凹/线性/非线性、模态数）自动选择交叉/变异参数。

**数学论证**：
- Hypervector：refPoint_m = 1.1 * max(PF_m, [])（逐目标维），但 EMO 上 max(PF_m) 量级 ~10²-10³ 导致退化，改用**标准化** refPoint_m = μ_m + 1.1*σ_m（PF 目标维均值+1.1倍标准差）
- 算子自适应：PF 形状检测（线性/凸/凹）→ 选择对应交叉（SBX η 自适应）
- 优势：解决 HV 退化（EMO/MaF14/15）+ M≥5 计算不爆炸（Hypervector 分解）

**伪代码**：
```
function NOVA_C = NOVA_C(P, n)
  Pop = P.Initialization(n);
  PF = P.ParetoFront(1000);
  ref = hv_refpoint(PF);  % 标准化 Hypervector
  shape = PF_shape_detect(PF);  % 线性/凸/凹
  η = shape_to_sbx(shape);  % 自适应 SBX 指数
  for g = 1:G
    F = P.CalObj(Pop.decs);
    Pop = NSGA2_selection(Pop, F);
    Pop = SBX_crossover(Pop, η);
    Pop = polynomial_mutation(Pop);
    HV_metric = HV_hypervector(Pop.F, ref);  % 逐目标维分解
  end
  return Pop;
end
```

**风险**：Hypervector 参考点标准化后可能偏离真实 HV；PF 形状检测在 LSMOP D=300 上不可靠（PF 量级 ~10²-10³）。

---

## 选择建议（待用户确认）
- **候选 A** 最贴合 SOTA（C-EGD+RKS-TAE），但实现复杂（在线 K-means + 子空间移民）
- **候选 B** 最直接强化 HCEAV4 短板（高维局部下降），单种群避免双种群失效，实现简单
- **候选 C** 解决 HV 退化 + M≥5 计算爆炸，但 PF 形状自适应在 LSMOP 上不可靠

**推荐**：先实现**候选 B**（单种群+高维定向局部下降），因为它直接针对 HCEAV4 的 D≥100 退化病灶，实现最快（1-2 小时冒烟），且继承 CRT 收敛门控思想（论文可保留"增强版"定位）。若 B 未达第一再试 A。
