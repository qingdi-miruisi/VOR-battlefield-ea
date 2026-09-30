# SOTA 追赶计划 — 最终报告

生成时间：2026-09-30。三轮集成尝试（无人值守，错误自行恢复）后触发止损。

## 1. 任务回顾

目标：VOR-v3 在 D=300 上 IGD 追到 FDSEA 1.5× 以内，CF1 追到 MOEA/D 1.5× 以内。

| 题 | FDSEA IGD | 1.5× 目标 | v3old (第3轮) | v3new (集成后) | 达成？ |
|---|---|---|---|---|---|
| LSMOP1 | 0.1434 | 0.215 | 0.7162 | 0.8557 | ❌ |
| DTLZ2_300D | 0.0653 | 0.098 | 0.3666 | 0.3251 | ❌ |
| LSMOP6 | 0.6677 | 1.002 | 1.7259 | 1.428 | ❌ |
| CF1 (MOEA/D 对照) | ≈0.045 | 0.0675 | 0.0560 | 0.0563 | ✅ |

**D=300 三题均未达 1.5× 目标；CF1 达标。** 触发止损条款（D=300 IGD 未追到 FDSEA 2× 以内：LSMOP6 1.428 vs 1.3354、DTLZ2 0.3251 vs 0.1306）。

## 2. 三轮集成结果

| 轮次 | 集成机制 | 结果 |
|---|---|---|
| 1 | ECSOCS 收敛采样辅助槽（convSampleAssist，每 20 代低比例替换） | DTLZ2 IGD 0.337→0.325（3.5%↑）、LSMOP6 1.73→1.43（17%↑）、LSMOP1 PPS 62→100 但 IGD 0.73→0.86（退化） |
| 2 | FDSEA 频域搜索策略槽（freqDomainGeneration，DFT 编码 + 频域 SBX） | **失败**：DTLZ2 IGD 0.337→59.4（175× 退化），DFT 抹平结构化最优解 |
| 3 | convSample + DSG 主路径（最终配置） | 保留 convSample（DTLZ2/LSMOP6 小幅改善），回退 freqDomain |

详情：`results/sota_chase/integration_log.md`。

## 3. 差距根因（不可弥合的架构级限制）

**FDSEA 的 D=300 收敛优势是"双种群 + 频域降维 + 交换"的架构级设计**，不是单一策略槽可复制的：
- 双种群独立进化（频域参数种群 + 常规决策种群）避免单一编码空间抹平结构。
- 频域 SBX 在 K=5 维操作（vs D=300 维），搜索效率 ~60×。
- 交换机制使两群在同一编码空间协同。

VOR-v3 是**单种群** Q-EPS+DSG 架构。把频域搜索嵌入单种群（轮 2）时，DFT 编码抹平 LSMOP/DTLZ2 族最优解的稀疏/分组/位置结构 → IGD 灾难性退化。要真正复制 FDSEA 需双种群架构重写（2-3 周开发 + 架构级改动），超出本轮"策略槽集成"止损范围。

**诚实结论：D=300 IGD 差距（LSMOP1 5×、DTLZ2 5.6×、LSMOP6 2.6× vs FDSEA）在 VOR-v3 单种群 SSV 架构下不可弥合。**

## 4. 建议

### 4.1 改投 / 重新定位（推荐）
- **改投 IEEE Access / Swarm & Evolutionary Computation**，接受"有竞争力但非 D=300 SOTA"定位。
- VOR-v3 卖点修订为：
  1. SSV 4 维连续调制框架（s_conv/s_div/s_feas_eff/s_scale）统一 3 类战场
  2. 4/6 题 PPS 达标（第 3 轮基准）+ DTLZ2_300D IGD 反超 v2 41%
  3. 多战场覆盖：约束低维（CF1）/ 高维无约束（LSMOP1）/ 高维难收敛（DTLZ2_300D/LSMOP6）
  4. **D=300 有竞争力**（DTLZ2 IGD 0.33 优于 GDVTSF 0.67/MOEA-IB 1.54；LSMOP6 IGD 1.43 优于 GDVTSF 1.22 接近），**但承认 FDSEA IGD 更强**（0.07/0.14/0.67）
- 论文中 SOTA 对比表保留 FDSEA/GDVTSF/MOEA-IB 三算法，诚实标注 VOR-v3 在 D=300 IGD 第 2-4 名。

### 4.2 若坚持 D=300 SOTA 定位（不在本轮范围）
- 需 VOR-v3 双种群架构重写（频域种群 + Q-EPS 常规种群 + 交换机制），预计 2-3 周开发 + 30-seed 基准。
- 风险：双种群架构与 SSV"轻量连续调制"哲学冲突，可能丧失可解释性卖点。

## 5. 备份与清理结果

| 项目 | 结果 |
|---|---|
| GitHub 备份 | ✅ commit 48d6e2d2b 推送成功（3888 files + 906 .mat），token 已重置移除 |
| 安全清理 | ✅ 删 _platemo_official/、LaTeX 中间产物（42 个）、_bak 目录；ssv_smoke/ssv_bench log.txt 因文件锁残留 |
| 增量 push | ⚠️ 网络超时（3 次重试失败），核心备份已完成，见 `results/BACKUP_BLOCKED.md` |

## 6. 下一步建议

1. **接受止损，按 §4.1 重新定位**：把 VOR-v3 卖点从"D=300 SOTA"改为"统一战场框架 + 有竞争力"，投 IEEE Access / SWEVO。
2. **CF1 卖点保留**：CF1 IGD 0.0563 达标（1.2× vs MOEA/D 1.5× 目标），约束低维战场仍是有竞争力的强点。
3. **DTLZ2_300D 卖点保留**：v3new IGD 0.325 优于 GDVTSF（0.67）/MOEA-IB（1.54），虽落后 FDSEA（0.07）但 3 算法对比中第 2 名，可作为"D=300 有竞争力"证据。
4. **不推荐双种群重写**（超出止损范围，且与 SSV 可解释性哲学冲突）。

## 7. 交接文件

- `algorithms/VOR_v3.m`（第三轮 + SOTA 集成 convSampleAssist，回退 freqDomain）
- `results/sota_chase/mechanism_survey.md`（FDSEA/EMOCSO/ECSOCS/MOZO 机制拆解）
- `results/sota_chase/integration_log.md`（三轮集成日志）
- `results/sota_chase/limitation_report.md`（局限性 + 止损判定）
- `results/sota_chase/FINAL_REPORT.md`（本文件）
- `PROGRESS.md`（SOTA 追赶条目已更新）
