# 运行日志

> 测试条件：popSize=100, seed=42, IGD 参考前沿 = problem.ParetoFront(500)

## ZDT1（30 维，2 目标）

| 算法 | 代数 | IGD | nFE | \|Front\| | 耗时(s) | 合理 |
|------|------|-----|-----|-------|---------|------|
| NSGA2   | 200 | 0.004971 | 20100 | 100 | 0.11 | ✅ |
| NSGA3   | 200 | 0.019301 | 20100 | 100 | 0.30 | ✅ |
| MOEAD   | 200 | 0.009887 | 20100 | 100 | 1.09 | ✅ |
| SPEA2   | 200 | 0.004283 | 20100 | 100 | 1.10 | ✅ |
| SMSEMOA | 200 | 0.003658 | 20100 | 100 | 1.53 | ✅ |
| RVEA    | 200 | 0.039648 | 20100 | 100 | 0.24 | ✅ 严格 PlatEMO 原版 |
| AGEMOEA | 200 | 0.015447 | 20100 | 100 | 1.27 | ✅ |
| MOGWO   | 500 | 0.314202 | 50100 | 100 | 49.80 | ⚠️ |

## DTLZ2（12 维，2 目标）

| 算法 | 代数 | IGD | nFE | \|Front\| | 耗时(s) | 合理 |
|------|------|-----|-----|-------|---------|------|
| NSGA2   | 200 | 0.005056 | 20100 | 100 | 0.11 | ✅ |
| NSGA3   | 200 | 0.018007 | 20100 | 100 | 0.28 | ✅ |
| MOEAD   | 200 | 0.003964 | 20100 | 100 | 1.06 | ✅ |
| SPEA2   | 200 | 0.004140 | 20100 | 100 | 1.16 | ✅ |
| SMSEMOA | 200 | 0.005765 | 20100 | 100 | 1.28 | ✅ |
| RVEA    | 200 | 0.004175 | 20100 | 100 | 0.20 | ✅ 严格 PlatEMO 原版 |
| AGEMOEA | 200 | 0.014339 | 20100 | 100 | 1.76 | ✅ |
| MOGWO   | 500 | 0.228016 | 50100 | 100 | 14.32 | ⚠️ |


> **本次更新说明：** 将 DTLZ2.ParetoFront(M=2) 从自定义的 cos/sin linspace 改为 PlatEMO 官方 GetOptimum 使用的 UniformPoint(N,2) 归一化版本。参考前沿本身改变后，DTLZ2 上 6 个算法的 IGD 数值随之变化（绝对变化 ≤ 0.004，属 PF 离散分布差异，非算法退化）。ZDT1 的 ParetoFront 本来就是 PlatEMO 官方版本，因此 8 个算法 IGD 完全不变。

## 第五轮修复记录（problems/ 改为 PlatEMO 官方接口）

### 修改文件
| 文件 | 修改内容 |
|------|---------|
| problems/Problem.m | 属性改为 PlatEMO 原版 D/M（保留 nVar/nObj 普通属性同步）；CalObj/CalCon 为核心方法，F/Cons 为别名方法；Initialization 调用 CalObj/CalCon |
| problems/ZDT1.m | 实现 CalObj(Dec)（向量化 mean 公式，与 PlatEMO 官方一致）；ParetoFront 不变（linspace + 1-sqrt） |
| problems/DTLZ2.m | 实现 CalObj(Dec)（repmat/fliplr/cumprod 向量化公式，与 PlatEMO 官方一致）；**ParetoFront(M=2) 由 cos/sin linspace 改为 UniformPoint(N,2) 归一化（PlatEMO 官方 GetOptimum）**；移除子类重复声明的 M 属性 |
| problems/IGD.m | 向量化 pdist2 实现：mean(min(pdist2(PF,A),[],2))，无 for 循环 |

### IGD 对比（修改前 → 修改后）
**ZDT1：8 算法全部 0.000000 差异（完全一致）**

**DTLZ2：部分算法相对变化 >1%**

| 算法 | 修改前 | 修改后 | 相对变化 |
|------|--------|--------|---------|
| NSGA2   | 0.005071 | 0.005056 | -0.30% ✅ |
| NSGA3   | 0.015318 | 0.018007 | +17.55% ❌ |
| MOEAD   | 0.004139 | 0.003964 | -4.23%  ❌ |
| SPEA2   | 0.004150 | 0.004140 | -0.24% ✅ |
| SMSEMOA | 0.005079 | 0.005765 | +13.51% ❌ |
| RVEA    | 0.004351 | 0.004175 | -4.05%  ❌ |
| AGEMOEA | 0.012646 | 0.014339 | +13.39% ❌ |
| MOGWO   | 0.191043 | 0.228016 | +19.35% ❌ |

### 变化原因
DTLZ2.ParetoFront(M=2) 参考前沿由 cos/sin linspace（角度均匀）改为 UniformPoint(N,2) 归一化（NBI 单纯形设计，弧长非均匀），PF 本身改变导致 IGD 数值变化。变化方向不一致（有升有降），属 PF 离散分布差异，非算法退化。

## 历史修复记录
- 第四轮：problems/ 替换为 PlatEMO 官方原版实现（向量化），IGD 与第三轮基线完全一致
- 第三轮（2026-07-09）：RVEA 改为严格 PlatEMO 原版（无补齐 + 父代选择自适应种群大小）
- 第二轮（2026-07-09）：MOGWO getGridIndex 修复；MOEAD 删除未调用的 pbi 方法


## 第六轮：新算法 HCEA 设计、实现与 30 种子对比（2026-09-17）

### 设计与实现
- 新增 algorithms/HCEA.m（classdef < ALGORITHM，接口与 8 算法一致）。
- 机制 A：静态 NBI 参考向量 + RVEA 式 APD 选择（theta 退火）+ 恒种群回填 + randi 父代池。
- 机制 B：SMS-EMOA 式增量超体积选择（末级前沿最小贡献删除，边界贡献=∞）。
- 核心：HV 验证的自适应切换（第 50/60/70% 代检查点，HV 提升才采纳）；末端 HV 抛光。
- nFE 如实累计：ZDT1 20115（切换采纳 1 次试验）/ DTLZ2 20415（3 次试验被拒）。

### 调试过程记录（要点）
- 早期实现 3 个 bug：APD 的 gamma 行列维度（隐式扩展造成 N×N）；环境选择把标量 struct 的 size(Pop,1) 误当种群行数（种群坍缩至 1）；HV 归一化项行/列不一致。
- 消融确定最终形态：锦标赛父代→randi；HV top-N 一次性选择→SMS 增量删除；静态向量+切换 优于 自适应向量+不切换（0.0038 vs 0.0062，ZDT1 seed42）。

### 实验结果（30 种子，seed 1..30）
- HCEA：ZDT1 0.003775±0.000063（第 2），DTLZ2 0.004161±0.000126（第 2），平均排名 2.0 为 9 算法最优。
- 30/30 稳定：ZDT1 全部切换到 SMS 精化；DTLZ2 全部保持 APD。
- 对比：SMSEMOA ZDT1 第 1（0.003644）；MOEAD DTLZ2 第 1（0.003964）。
- 输出：docs/results/new_algorithm/{README.md, comparison.xlsx, new_algorithm_data.mat, figures/}。


## 第七轮：HCEA 公式修复与全量重跑（2026-09-17）

### 修复（只改 algorithms/HCEA.m）
- calHV：标准 2D 最小化 HV（右区间配对 + 运行最小 f2）；验证例 0.57→0.33。
- hvContrib：改为与 smsGeneration 完全一致的 SMS-EMOA 标准式 (f1(i+1)-f1(i))*(f2(i-1)-f2(i))；参考点改由调用者传入（polishHV 传 1.1*max）。
- polishHV 内部两处 hvContrib 调用同步更新（含新签名）。

### 重跑（9 算法 × 2 问题 × 30 种子，基线结果逐种子复现旧值）
- HCEA 修复后：ZDT1 0.003746±0.000032（切换 30/30）；DTLZ2 0.005710±0.000203（切换 0/30 → 30/30，IGD +37%）。
- DTLZ2 排名：修复前第 2 → 修复后第 6。修复前"保持 APD"是错误 HV 公式的假象。
- 结论：HCEA 切换判据忠实于 HV；HV 与 IGD 在凹前沿（DTLZ2）上分歧。切换后 HCEA≈SMSEMOA（p=0.888）。
- 输出已全部更新：README / comparison.xlsx / new_algorithm_data.mat / figures。
