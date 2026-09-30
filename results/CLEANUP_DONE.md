# CLEANUP_DONE — 安全清理结果

生成时间：2026-09-30

## 备份确认

- 远程 `main` → `48d6e2d2b`（3888 files, 含 906 个 .mat、VOR_v3.m、ssv_bench_round3、sota_2026_round3、论文 PDF/tex）✅
- 清理增量 commit `b900c027e` 已纳入本地 git（可恢复）
- 增量 push 因 GitHub 网络超时未成功（见 `results/BACKUP_BLOCKED.md`，核心备份已完成）

## 删除清单（已删除）

| 目标 | 状态 |
|---|---|
| `_platemo_official/`（PlatEMO 官方源码 + platemo_v420.zip） | ✅ 已删 |
| `results/ssv_smoke_bak/` | ✅ 已删 |
| `results/ssv_bench_bak/` | ✅ 已删 |
| `results/ssv_bench_round3_bak/` | ✅ 已删 |
| `paper_en/*.aux/*.log/*.out/*.spl/*.blg`（38 个 LaTeX 中间产物） | ✅ 已删 |
| `paper_cn/*.aux/*.log/*.out`（4 个 LaTeX 中间产物） | ✅ 已删 |
| `results/ssv_smoke/log.txt` | ❌ 文件锁，未删 |
| `results/ssv_bench/log.txt` | ❌ 文件锁，未删 |

## 保留清单（未动）

- `paper_en/` 最终 PDF + .tex 源
- `algorithms/VOR_v3.m`、`algorithms/VOR.m`、`EDD.m`、`NSGA2.m`、`RVEA.m`、`MOEAD.m`
- `results/ssv_bench_round3/`、`results/sota_2026_round3/`、`results/ssv_design.md`
- `results/largescale_extended/**/*.mat`（906 个）
- `PROGRESS.md`、`.gitignore`、`README.md`、`LICENSE`

## 不确定项（未删，留用户确认）

- `results/ssv_smoke/`、`results/ssv_bench/`（目录因 log.txt 文件锁未删，内容仍可 git 恢复）
- `results/ablation/`、`results/main*/`、`results/largascale_edd_v*/`、`results/cf_*/`、`results/diag_*/`

## 释放空间

删除约 42 个 LaTeX 中间产物 + `_platemo_official/`（PlatEMO 全量源码）+ 3 个 `_bak` 目录。估算释放数百 MB（`_platemo_official` 含 zip 为主）。
