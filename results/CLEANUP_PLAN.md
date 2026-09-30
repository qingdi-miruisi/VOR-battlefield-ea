# CLEANUP_PLAN — 删除清单

生成时间：2026-09-30（备份已确认完成，`results/BACKUP_DONE.md`）

## 必须保留（不删）

| 类别 | 文件/目录 | 理由 |
|---|---|---|
| 最终论文 | `paper_en/VOR_paper_AppliedSoftComputing_final.pdf`、`paper_en/VOR_cover_letter.pdf` | 投稿主文件 |
| 论文源码 | `paper_en/*.tex`、`paper_cn/*.tex` | 可复现 |
| 最终算法 | `algorithms/VOR_v3.m` | 第三轮最终代码 |
| v2 消融对照 | `algorithms/VOR.m` | 不可删 |
| 论文对比基线 | `algorithms/EDD.m`、`algorithms/NSGA2.m`、`algorithms/RVEA.m`、`algorithms/MOEAD.m` | 不可删 |
| 最新结果 | `results/ssv_bench_round3/`、`results/sota_2026_round3/` | 最新轮次 |
| 设计文档 | `results/ssv_design.md` | 需保留 |
| .mat 结果 | `results/largescale_extended/**/*.mat`（906 个） | 不可删 |
| 项目文件 | `PROGRESS.md`、`.gitignore`、`README.md`、`LICENSE` | 仓库元数据 |
| 已 push 文件 | 以 `git ls-files` 输出为准 | 已备份 |

## 可以删除

| 目标 | 说明 |
|---|---|
| `_platemo_official/` | PlatEMO 官方源码 + zip（已纳入 git，备份后冗余） |
| `results/ssv_smoke/` | 冒烟测试（结论已入 ssv_design.md §9） |
| `results/ssv_bench/` | 第 2 轮结果（已被 round3 取代） |
| `results/ssv_smoke_bak/` | 冒烟备份 |
| `results/ssv_bench_bak/` | 第 2 轮备份 |
| `results/ssv_bench_round3_bak/` | 第 3 轮备份（与 ssv_bench_round3 重复） |
| `results/sota_2026/`、`results/sota_2026_ext/` | 旧轮次中间日志 |
| `results/step*.txt`（step17-step28） | 中间调试日志 |
| LaTeX 中间产物 | `paper_en/*.aux`、`*.log`、`*.out`、`*.spl`、`*.blg`、`*.bbl`（旧版） |
| 重复旧 PDF/图表 | `paper/`、`papers/` 下非最终版 PDF |

## 不确定（不删，留用户确认）

| 目标 | 说明 |
|---|---|
| `algorithms_original/` | 可能是 v1 原始代码存档，不确定是否仍需要 |
| `results/ablation/`、`results/ablation_abl/` | 消融实验结果，不确定是否用于论文 |
| `results/main*/`、`results/merged_v4/`、`results/new_algo*/` | 早期轮次结果，不确定 |
| `results/largascale_edd_v*/`、`results/largescale_final/` | EDD 历史版本结果 |
| `results/cf_*/`、`results/diag_*/`、`results/m3_focus/`、`results/m5_prescreen/` | 诊断/筛选结果 |

## 删除前提交

```
git add -A
git commit -m "cleanup: remove obsolete temp files and old round logs"
```

## 删除后

```
git push origin main
```
