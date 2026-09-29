# IGD/HV 分歧研究（docs/results/metric_disagreement）

> 数据：raw_data.mat（5 问题 × 9 算法 × 30 种子 × {IGD, HV}）；汇总：summary.xlsx
> 日期：2026-09-17



## 统计检验（2026-09-17，基于 30 种子均值、5 问题为区组）

### Friedman 全局检验
- IGD：χ² = 28.0533，df = 8，p = 4.64e-4（算法间差异显著）
- HV：χ² = 36.3200，df = 8，p = 1.53e-5（算法间差异显著）
- Friedman 平均秩（1=最优）：
  - IGD：SMSEMOA 2.2 / SPEA2 2.4 / HCEA 2.8 / NSGA2 4.0 / AGEMOEA 5.8 / MOEAD 6.0 / RVEA 6.2 / NSGA3 6.6 / MOGWO 9.0
  - HV：SMSEMOA 1.2 / HCEA 1.8 / SPEA2 3.0 / NSGA2 4.2 / AGEMOEA 5.8 / NSGA3 6.4 / MOEAD 6.6 / RVEA 7.0 / MOGWO 9.0

### 两两 Wilcoxon 秩和检验（HCEA vs 其余 8 算法）
每对在每个问题上独立检验 30 种子（ranksum，双侧），5 个 p 值经 Fisher 合并：
- IGD：HCEA 对 NSGA2/NSGA3/MOEAD/SPEA2/SMSEMOA/RVEA/AGEMOEA/MOGWO 合并 p 均 < 1e-300（***）。但逐问题看存在不显著点：vs SPEA2 在 ZDT2 p=0.186；vs SMSEMOA 在 ZDT3 p=0.068、DTLZ2 p=0.888（不显著）。
- HV：HCEA 对全部 8 算法合并 p 均 < 1e-300（***），逐问题亦全部 3.0e-11 量级（完全分离）。

### Nemenyi 后验 CD（α=0.05，k=9，N=5）
- CD = 3.102 × sqrt(9×10/(6×5)) = **5.3728**
- CD 图：figures/fig4_cd_igd.png、figures/fig4_cd_hv.png
- IGD：HCEA 平均秩 2.80，与除 MOGWO（秩 9.0，差 6.2 > CD）外的全部 7 个算法无显著差异
- HV：HCEA 平均秩 1.80，与除 MOGWO（秩 9.0，差 7.2 > CD）外的全部 7 个算法无显著差异

### 结论
- HCEA 的 IGD 排名（第 3，平均秩 2.8）与 HV 排名（第 2，平均秩 1.8）均有全局显著性支撑（Friedman p<1e-3），且 Wilcoxon 逐问题检验显示 HCEA 显著优于多数算法、仅在个别问题上与 SPEA2/SMSEMOA 无差异；但 Nemenyi CD（5 个区组下 CD=5.37 过大）只能把 HCEA 与 MOGWO 显著分开，与其余 7 个算法无法在 α=0.05 下区分——即「头部集团 vs MOGWO」的两层结构有统计支撑，头部内部的精细排序无统计支撑。
- 相关文件：statistical_tests.xlsx（Friedman_IGD / Friedman_HV / Wilcoxon_IGD / Wilcoxon_HV / Wilcoxon_IGD_detail / CD_data）、statistical_tests.mat、figures/fig4_cd_*.png/.fig、statistical_tests.m
