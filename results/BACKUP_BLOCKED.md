# BACKUP BLOCKED — 清理后增量 push 失败

生成时间：2026-09-30

## 状态

第一次备份 push 已成功（commit `48d6e2d2b` 已推送到远程，包含全部 3888 个文件 + 906 个 .mat）。

清理操作（删除 `_platemo_official/`、`results/ssv_smoke/`、`results/ssv_bench/`、`results/ssv_*_bak/`、LaTeX 中间产物）已 commit 到本地（`b900c027e`），但推送清理后增量到远程失败：

```
fatal: unable to access 'https://github.com/qingdi-miruisi/VOR-battlefield-ea.git/':
Failed to connect to github.com:443 after 21095 ms: Could not connect to server
```

3 次重试（含重新配置 token）均失败。

## 影响

- **核心备份已完成**：远程 `main` 指向 `48d6e2d2b`，包含全部关键成果（VOR_v3.m、ssv_bench_round3、sota_2026_round3、906 个 .mat、论文 PDF/tex）。
- **本地领先远程 1 个 commit**（`b900c027e cleanup: remove obsolete temp files and old round logs`，含 4 个 paper_cn LaTeX 中间产物的删除记录 + CLEANUP_PLAN.md/BACKUP_DONE.md）。
- 删除操作已纳入本地 git，可恢复。

## 恢复方法（网络恢复后）

```
git remote set-url origin https://qingdi-miruisi:<TOKEN>@github.com/qingdi-miruisi/VOR-battlefield-ea.git
git push origin main
git remote set-url origin https://github.com/qingdi-miruisi/VOR-battlefield-ea.git
```

## 残留未删项（文件锁）

- `results/ssv_smoke/log.txt`、`results/ssv_bench/log.txt`：被某进程独占锁定，del/PowerShell 均无法删除。需用户重启 MATLAB 会话或检查占用进程后手动删除。
