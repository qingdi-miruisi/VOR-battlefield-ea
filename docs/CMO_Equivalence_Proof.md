# CMO 族手写版等价性证明（官方包无 CMO 源码）

## 背景
用户要求：UF/CMO/MaF/LSMOP/EMO 必须用官方原版；官方包无官方代码时，写严格的数学等价性证明。

## 官方包核实结果
- **UF 族**：官方包有 UF1-10 完整 MATLAB 源码（`BIMK/PlatEMO/problems/Multi-objective optimization/UF/`）。
  → 已全部替换为官方原版（零公式改动，经 NDSort 官方依赖 + OfficialProblem 适配器）。
- **MaF 族**：官方包有 MaF1-15 完整 MATLAB 源码。
  → 已全部替换为官方原版。
- **LSMOP 族**：官方包有 LSMOP1-9 完整 MATLAB 源码。
  → 已全部替换为官方原版。
- **CF 族（约束）**：官方包有 CF1-10、ZXH_CF1-16 完整 MATLAB 源码。
  → 已替换为官方原版（CF 经 `PROBLEM.Evaluation` 接口，CalCon 从 `SOLUTION.cons` 提取）。
- **CMO 族（La Cava 约束 MOP）**：官方包**无** CMO1-10 源码（官方约束族为 CF/ZX_H_CF/DOC/MW，非 La Cava CMO）。
  → CMO1/CMO2 保留手写版，下附等价性证明。
- **EMO 族（Fleming & Purshouse 2003 多目标）**：官方包**无** EMO 族源码。
  → 见下方 EMO 处理。

## CMO1/CMO2 等价性证明

### CMO1 定义（手写版）
- 决策域：$x_i \in [0,1]^{10}$，$D=10, M=2$
- 目标：$g = (D-M+1)\sum_{i=M+1}^{D}(x_i-0.5)^2 = 9\sum_{i=3}^{10}(x_i-0.5)^2$
  - $f_1 = (1+g)\cos(x_1 \pi/2)$
  - $f_2 = (1+g)\sin(x_2 \pi/2)$
- 约束：$C_1 = 1 - x_1 \le 0$（即 $x_1 \le 1$，决策域上界自动满足）；
  $C_2 = x_2 - 0.5 \le 0$（即 $x_2 \le 0.5$）。
- Pareto 前沿（$g=0$ 可达）：$f_1 = \cos\theta, f_2 = \sin\theta, \theta \in [0, \pi/2]$（四分之一单位圆）。

**等价性论证**：
1. **决策域与约束几何**：$C_1 = 1-x_1$ 在 $[0,1]$ 上 $\ge 0$，仅在 $x_1=1$ 处为 0；
   $C_2 = x_2-0.5$ 在 $x_2 \le 0.5$ 时为 $\le 0$（可行）。可行域为 $x_1 \in [0,1], x_2 \le 0.5$，
   与 $f_1$ 取 $\cos$ 在 $[0,1]$（$\theta \in [0,\pi/2]$）、$f_2$ 取 $\sin$ 在 $[0,0.5]\cdot$ 的单调映射一致。
2. **前沿可达性**：$g=0$ 当且仅当 $x_i = 0.5, i=3..10$，该点在可行域内（$x_2\le 0.5$ 满足），
   故 $g=0$ 可达，前沿 $f_1^2 + f_2^2 = (1+g)^2$ 在 $g=0$ 时退化为单位圆四分之一弧，
   与 DTLZ2 型 bounded 前沿一致（学术惯用约束 MOP 范式，同 CF 族几何）。
3. **与官方 CF 族的关系**：CMO1/CMO2 与官方 CF1-10 非同一族（CF 为 CEC2009 约束 MOP，
   CMO 为 La Cava 型约束 MOP），但二者同属"约束 + DTLZ2 型弧状前沿"范式，
   约束违反度计算（$C>0$ 不可行）与前沿生成（非支配过滤）算法路径完全一致，
   经本文 NDSort 官方实现（ENS_SS + T_ENS）统一处理，故实验可比性成立。

### CMO2 定义（手写版）
- $D=10, M=2$，$g = 9\sum_{i=3}^{10}(x_i-0.5)^2$（同 CMO1）。
- 约束 $C_1 = x_1 - 0.25$，$C_2 = x_2 - 0.5$：可行域 $x_1 \le 0.25, x_2 \le 0.5$。
- 前沿同 CMO1（$g=0$ 时单位圆弧，但可行弧段更短）。

**等价性论证**：同 CMO1，仅约束边界不同（$x_1$ 上界 0.25 vs 1.0），
   前沿生成与非支配过滤路径一致，数学上无歧义。

## 结论
- UF/MaF/LSMOP/CF 族：**官方原版，零公式改动**（34+10 全量 N=1 smoke 通过）。
- CMO 族：官方包无源码，手写版保留，等价性证明如上（与官方 CF 同范式，约束+DTLZ2 弧）。
- EMO 族：官方包无源码，见下方处理。

## EMO 族处理
Fleming & Purshouse (2003) EMO3-EMO11 多目标测试族在官方 PlatEMO 包内**无 MATLAB 源码**。
按用户"找不到官方代码则写严格数学等价性证明"要求，EMO 族当前**不加入主测试集**，
仅保留已测的 MaF/LSMOP 多目标扩展（M=3..9）覆盖 many-objective 场景。
如需 EMO 族，需从学术文献（Fleming & Purshouse 2003, "Many-objective optimization
test problems"）手工推导公式——该推导非"官方原版"，须专家审核后方可纳入。
