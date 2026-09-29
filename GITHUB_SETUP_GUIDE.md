# GitHub 仓库操作指南（VOR-battlefield-ea）

> 目标：把"代码可用性声明"从占位变成真仓库，让审稿人/编辑点开链接能一键复现。
> 全程约 20 分钟。

---

## 第 0 步：先做匿名镜像还是直接 GitHub？

投稿 **Applied Soft Computing** 时推荐用 **匿名仓库**（`anonymous.4open.science`），理由：
1. 审稿期间论文匿名（作者不可公开），GitHub 公开仓库会暴露作者身份；
2. 编辑系统要求 "anonymized mirror maintained for the review period"——4open.science 就是为这个场景设计的；
3. 接收后再切到 GitHub 公开仓库即可。

- **审稿阶段 URL**：`https://anonymous.4open.science/r/VOR-battlefield-ea`（匿名 handle，4open 自动分配）
- **接收后 URL**：`https://github.com/你的账号/VOR-battlefield-ea`

---

## 第 1 步：本地建仓库结构（已在 D:\ 下做完一半）

当前 `D:\harness工作\中国科学：数学(总)\算法\algorithm\` 已有内容：

```
algorithm/
├── algorithms/
│   ├── VOR.m                  # 核心算法（~740 行）
│   ├── EDD.m / NSGA2.m / RVEA.m / MOEAD.m   # 基准（若分散在别处，集中到这里）
│   └── ...
├── experiments/
│   ├── run_vor2_bench_30.m   # 30-seed 批量跑
│   ├── stat_30.m             # Friedman + Wilcoxon
│   ├── aggregate_vor2_30.m   # 均值±std 汇总
│   └── make_figs_en.m        # 3 张矢量图
├── results/
│   ├── vor2_bench/*.mat      # 900 个结果文件（s1–s30 × 5 algo × 6 题）
│   ├── stat_results_30.txt
│   ├── agg30_stats.txt
│   └── figs/out/*.pdf        # fig1/fig2/fig3
└── paper_en/
    ├── main.tex
    └── cover_letter/cover_letter.tex
```

**需要你确认**：基准算法（NSGA2/RVEA/MOEAD/EDD）的 .m 文件具体在哪个目录？若不在 `algorithms/`，我把它们 copy 过去，凑齐"README 说的一键复现"。

---

## 第 2 步：写 README.md（一键复现脚本）

我帮你生成 `README.md`，内容如下（生成后你过目）：

```markdown
# VOR: Battlefield-Adaptive EA for Large-Scale & Constrained MOP

Anonymized mirror for the Applied Soft Computing submission
"Battlefield-Adaptive Evolutionary Algorithm with Online
Reference-Reallocation and Quantile ε-Grid Selection...".

## Requirements
- MATLAB R2022a+ (no toolboxes required; core + Optimization optional)

## One-command reproduction
  1. cd experiments
  2. run_vor2_bench_30()    % 6 problems × 5 algorithms × 30 seeds
  3. stat_30()              % Friedman + Wilcoxon → results/stat_results_30.txt
  4. aggregate_vor2_30()    % mean±std table → results/vor2_bench/agg30_stats.txt
  5. make_figs_en()         % 3 vector figures → results/figs/out/

## Result archive
  results/vor2_bench/*.mat  % 900 files, one per (algorithm, problem, seed)
  Each .mat: R (struct: F, igd, hv, pps, el, igdHistory, ...), PF, ref, aName, pName

## Note
  SOTA trio (FDSEA/GDVTSF/MOEA-IB) numbers are cited from public
  papers; the large-scale extended benchmark folder is not included
  in this mirror (anonymization policy).
```

---

## 第 3 步：推到 4open.science（匿名，5 分钟）

1. 浏览器打开 https://4open.science
2. 注册/登录（用你的 GitHub 账号即可）
3. 点 "New project" → 名字填 `VOR-battlefield-ea`
4. 它会给你一个匿名 URL：`https://anonymous.4open.science/r/VOR-battlefield-ea`
5. 本地执行：
   ```bash
   cd "D:\harness工作\中国科学：数学(总)\算法\algorithm"
   git init
   git add .
   git commit -m "VOR 30-seed benchmark + paper source (anonymized mirror)"
   git remote add anon https://anonymous.4open.science/r/VOR-battlefield-ea
   git push anon main
   ```
   - 注意：`results/vor2_bench/` 有 900 个 .mat，可能超过 4open 的单仓库体积限制（默认 1GB 一般够）。若超限，我把 .mat 打包成单个 zip 再推（并在 README 里写明 unzip）。
6. 把匿名 URL 回填到正文 `Code availability` 段的 `YOUR-ANON-REPO` 占位。

---

## 第 4 步（接收后）：切 GitHub 公开

- 注册 GitHub 仓库 `你的账号/VOR-battlefield-ea`，把同一份代码 push 上去
- 正文 URL 改成 `https://github.com/你的账号/VOR-battlefield-ea`
- 4open 镜像保留 6 个月（编辑要求"review period"）

---

## 我需要你提供的 3 个信息

| # | 信息 | 用途 |
|---|---|---|
| 1 | 基准算法 .m 文件位置（NSGA2/RVEA/MOEAD/EDD 在哪） | 凑齐一键复现 |
| 2 | 你是否已有 GitHub 账号？账号名 | 第 4 步切公开仓库 |
| 3 | 是否同意用 4open.science 做审稿期匿名镜像？ | 决定推哪个 remote |

你给我这 3 个信息后，我把 README 生成、.mat 打包（如需要）、git 初始化 + commit + 远端配置全部做完，你只需在浏览器里点 4open.science 的 "New project"（git push 那一步我可以用本机命令代跑，前提是 git 已装且有 GitHub token——若没装 git 我改用图形化 4open web 上传方式，你拖拽文件夹即可）。

---

## 当前已完成的修改（本轮）

- [x] Wilcoxon 表：MaF14 整列改 "tied/excluded"，DTLZ2/LSMOP6 改 "n.s."，新增 r_rb 效应量列 + 相对 gap 列 + 脚注（DTLZ2 EDD 反超、LSMOP6 三个离群种子）
- [x] fig1 caption：删 DTLZ2（EDD 0.738 最低），加 MaF14 并列说明
- [x] Abstract (i)：EDD PPS "8–97" → "24–27"（30-seed 值）
- [x] §3.2 routing rationale：0.694→0.706、0.062→0.063、0.736→0.749 等 10-seed 值全部换成 30-seed
- [x] fig2 caption：EDD PPS 97/99.4 → 99/99
- [x] Table 5 ablation caption："10-seed" → "single-seed diagnostic, seed 1"
- [x] 新增 "PPS selling point"：VOR 是唯一 3 个 D=300 题 PPS≥88 的算法
- [x] 正文 + cover letter：仓库 URL 改成醒目的 `YOUR-ANON-REPO` 占位（你一眼看到该填哪）
- [x] cover letter：加日期占位 + 3 个推荐审稿人占位
- [x] 重新编译：**0 错误、0 Overfull、23 页**（`VOR_paper_AppliedSoftComputing_final.pdf`）
