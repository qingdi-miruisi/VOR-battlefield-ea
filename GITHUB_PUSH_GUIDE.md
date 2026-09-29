# ============================================================================
# git 操作清单 — 推 VOR-battlefield-ea 到 GitHub
# 远端: https://github.com/qingdi-miruisi/VOR-battlefield-ea (Public, MIT)
# 本地: D:\harness工作\中国科学：数学(总)\算法\algorithm
# 生成: 2026-07 (投稿 APSC 用)
#
# 使用方法: 在 Windows 上打开 "Git Bash" (或 PowerShell/cmd), 逐段粘贴执行。
#           每段末尾有 [✓ 验证] 命令, 跑完确认输出符合预期再进下一段。
# ============================================================================


# ----------------------------------------------------------------------------
# 第 0 段: 前置检查 (git 已装: git version 2.55.0.windows.3 ✓)
# ----------------------------------------------------------------------------
git --version
# [✓ 验证] 输出 "git version 2.55.0.windows.3" 或更高


# ----------------------------------------------------------------------------
# 第 1 段: 配置 git 身份 (仅本仓库有效, 不影响全局)
#          邮箱用你投稿论文里的通讯作者邮箱; 姓名用拼音
# ----------------------------------------------------------------------------
cd "D:\harness工作\中国科学：数学(总)\算法\algorithm"
git config user.name  "Yuxuan Zhang"
git config user.email "3150644070@qq.com"
# [✓ 验证] 两条都无输出 (git config 设置成功不打印); 用下面命令回读确认:
git config user.name && git config user.email
# 输出应为: Yuxuan Zhang / 3150644070@qq.com


# ----------------------------------------------------------------------------
# 第 2 段: 初始化仓库 (若之前已 init 过, 此段报错 "Reinitialized" 也无所谓, 继续)
# ----------------------------------------------------------------------------
git init
# [✓ 验证] 输出 "Initialized empty Git repository in ..."
#          若已存在 .git, 会提示 "Reinitialized existing Git repository", 正常


# ----------------------------------------------------------------------------
# 第 3 段: 查看将要 add 的文件清单 (先 dry-run, 确认 .gitignore 生效)
#          重点确认: *.mat 结果文件 被包含, 临时文件 被排除
# ----------------------------------------------------------------------------
git add -n algorithms/ experiments/ results/ paper_en/ README.md .gitignore LICENSE
# 说明:
#   - git add -n = "dry run", 只打印不实际暂存
#   - 输出应是几百行 "add 'results/vor2_bench/....mat'" (共 900+ 行)
#   - 不应出现 "add 'xxx.asv'" / "add 'slprj/...'"
#   - LICENSE: GitHub 创建页面已选 MIT, 本地仓库还没有 LICENSE 文件, 见下方处理
# [✓ 验证] 输出行数 > 900, 无 .asv/slprj 行


# ----------------------------------------------------------------------------
# 第 3a 段: 处理 LICENSE
#            GitHub 创建时选 MIT License, 远端已有 LICENSE; 本地没有。
#            方案: 远端为准, 第 5 段 pull --rebase 时自动同步下来。
#            本地不建 LICENSE 文件, 避免和远端冲突。
# ----------------------------------------------------------------------------
echo "(skip: LICENSE will come from remote via pull --rebase)"


# ----------------------------------------------------------------------------
# 第 4 段: 暂存 + 提交
#          注意: 用 git add (不带 -n) 真正暂存; 提交信息一行即可
# ----------------------------------------------------------------------------
git add algorithms/ experiments/ results/ paper_en/ README.md .gitignore
git commit -m "VOR 30-seed benchmark: code + data + paper (APSC submission)"
# [✓ 验证] 输出:
#   "[main (root-commit) xxxxxxx] VOR 30-seed benchmark: ..."
#   " <900+ files changed, xxxxx insertions(+)"
#   若报 "nothing to commit", 说明第 3 段已暂存, 直接 git commit 即可


# ----------------------------------------------------------------------------
# 第 5 段: 分支改名 + 加远端
# ----------------------------------------------------------------------------
git branch -M main
git remote add origin https://github.com/qingdi-miruisi/VOR-battlefield-ea.git
# [✓ 验证] git remote -v 输出:
#   origin  https://github.com/qingdi-miruisi/VOR-battlefield-ea.git (fetch)
#   origin  https://github.com/qingdi-miruisi/VOR-battlefield-ea.git (push)


# ----------------------------------------------------------------------------
# 第 6 段: 首次推送 (分两种情况)
# ----------------------------------------------------------------------------
# 【情况 A】远端仓库是空的 (创建时没勾 README):
#   直接推:
git push -u origin main

# 【情况 B】远端仓库勾了 "Add README" (远端已有 1 个 commit 的 README.md):
#   直接 push 会被拒 (non-fast-forward), 用下面命令合并远端 README 再推:
#   git pull --rebase origin main
#   git push -u origin main
#   若 rebase 报 "README.md already exists" 冲突:
#     1) git checkout --theirs README.md     (保留远端 README 或本地, 二选一)
#     2) git add README.md
#     3) git rebase --continue
#     4) git push -u origin main
#
# 【情况 C】远端勾了 .gitignore (选了某个模板):
#   本地 .gitignore 可能和远端模板冲突。处理:
#     git pull --rebase origin main
#     # 若冲突: 保留本地 .gitignore (它才是不忽略 *.mat 的正确版):
#     git checkout --ours .gitignore
#     git add .gitignore
#     git rebase --continue
#     git push -u origin main
#
# [✓ 验证] 推送成功后, 浏览器打开
#   https://github.com/qingdi-miruisi/VOR-battlefield-ea
#   应能看到:
#     - README.md 渲染正常
#     - algorithms/ 含 VOR.m (~740 行) + NSGA2/RVEA/MOEAD/EDD + run_*_ls.m
#     - experiments/ 含 run_vor2_bench_30.m / stat_30.m / aggregate_vor2_30.m / make_figs_en.m
#     - results/vor2_bench/ 含 900 个 .mat (页面顶部可能显示 ~90MB)
#     - results/stat_results_30.txt / agg30_stats.txt
#     - results/figs/out/ 含 3 张 fig PDF
#     - paper_en/main.tex + cover_letter/cover_letter.tex
#     - .gitignore / LICENSE (MIT)


# ----------------------------------------------------------------------------
# 第 7 段: 推送后本地再检查 (确认 .mat 没被误忽略)
# ----------------------------------------------------------------------------
git ls-files results/vor2_bench/ | find /c ".mat"
# [✓ 验证] 输出数字应为 900 (即 900 个 .mat 被 git 跟踪)
#          若远端 README 也进来, 再确认:
git log --oneline -5
# 应看到本地 commit (+ 可能远端 README commit)


# ----------------------------------------------------------------------------
# 第 8 段: (可选) 后续增删改再推
# ----------------------------------------------------------------------------
# 改代码后:
#   git add <改动文件>
#   git commit -m "one-line description"
#   git push
#
# 若之后要加入新的 .mat 结果 (比如补跑):
#   git add results/vor2_bench/xxx_sNN.mat
#   git commit -m "add seed NN results for XXX"
#   git push


# ----------------------------------------------------------------------------
# 常见问题速查
# ----------------------------------------------------------------------------
# Q: push 报 "rejected: non-fast-forward"?
# A: 远端有 commit 你没有 -> git pull --rebase origin main 再 push
#    (见第 6 段情况 B/C)
#
# Q: 推送很慢 (900 个 .mat, ~90MB)?
# A: 正常, 单线程上传约 1-3 分钟; 断网可重跑 git push 续传
#
# Q: 想删掉某个误传文件?
#   git rm --cached <path> && git commit -m "remove <path>" && git push
#
# Q: GitHub 提示 "large files" 警告?
# A: 本仓库最大单文件 ~16MB (figs), 总 ~90MB, 远低于 GitHub 单文件 100MB
#    硬限, 不会触发 LFS; 但监控 GitHub 仓库首页若出现 "Large files" 黄条,
#    检查哪个 .mat 超 100MB (本仓库 0 个)
#
# Q: 以后接收后想删 4open 匿名镜像?
# A: 本次没用 4open, 跳过
