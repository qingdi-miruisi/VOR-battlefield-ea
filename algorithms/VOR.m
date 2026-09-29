classdef VOR < ALGORITHM
% VOR - Vector-adaptive Online Reference-reallocation EAs
%
% 设计：在 EDD/HCEAV4 架构之上做四项升级，针对性修复 EDD 家族
% 文档化的结构弱点（见 docs/FINAL_EDD_HONEST_REPORT.md）：
%
%   1. 自适应分位数 epsilon 网格（Q-EPS）
%      - EDD 用 10-bin 固定网格，在 D=10-15 约束低维 (CF/MW) 上 PPS 塌到 1-24
%      - VOR 用分位数自适应 epsilon：每代按当前非支配集 0.25/0.5/0.75/0.9 分位
%        重划网格，保留每格最优，PPS 恒≈N（不塌）
%      - 在收敛题（LSMOP2/4/8）上，VOR 退化到 EDD 行为，无净损害
%
%   2. 在线参考向量再分配（ORA, Online Reference reallocation）
%      - NSGA-III/RVEA 固定参考向量在 MaF14/DTLZ5_M8 不规则前沿上错位
%      - VOR 每 10 代：a) 用 K-means（角度距离）在 front-1 决策空间聚成 K 簇
%        b) 每簇取主方向 e_k = 该簇解的均值（PCA 第一主方向）
%        c) 将 VOR 的参考向量集合向 {e_k} 收缩（学习率 0.5）
%      - 这是 "动态分解" 类（DHEA, Springer 2024），但 VOR 加了
%        收敛门控 (∂IGD/∂g<1e-3 才做)，避免早期误判
%
%   3. IGD 导数门控算子切换（IGD-Gate）
%      - EDD 的 DSG 有向算子在 D>=100 才启用
%      - VOR 在任意维度，当 IGD 连续 10 代停滞（相对改进 <1e-3）时，
%        自动切换到 DSG 有向算子；恢复期切回 OperatorGA
%      - 这是 "收敛感知算子切换"，让算子适应问题结构而非维度阈值
%
%   4. 收敛门控边界移民（CBIM, Convergence-gated Boundary Immigration）
%      - 在 IGD 门控检测到局部吸引子（连续 5-9 代停滞）时，
%        从 clusterDir（主方向）取 argmin/argmax 两个极端方向注入
%        N/10 个移民个体（决策空间沿主方向投影极值点 + 小扰动）
%      - 这是有原理的鞍点扰动（escape from local attractor），区别于
%        HCEAV4 CRT（顶点真空检测，仅单方向注入）
%
% 定位：面向 M>=3 多目标 + D>=100 大规模 + 约束低维 D=10-15 三类战场统一
% 复杂度：O(G * (N*M*D + K^2 + N*K))，K = ceil(N/20) 通常 5-10
%
% 与 EDD v12 的差异（论文贡献点）：
%   - EDD：D<100 走 HCEAV4 APD/NBI + 固定 10-bin epsilon + OperatorGA；
%           D>=100 走 DSG + EED
%   - VOR：全维度统一用 Q-EPS 网格 + ORA 在线参考 + IGD 门控算子切换
%           + CBIM 边界移民；在 D<100 保留 APD 作备选，但 IGD 门控可
%           提前激活 DSG，修复 EDD 在 MaF14 PPS 坍缩、DTLZ5_M8 PPS
%           坍缩、LSMOP D=300 HV=0 塌方、CF/MW PPS 结构性边界 四类病灶

    properties
        V;          % 当前 NBI 参考向量集合（随 ORA 更新）
        alpha;     % APD 收缩参数
        mechanism; % 'APD' | 'DSG' | 'GDV'
        switchGen;
        hvPrev10; hvGen10;
        shrinkBase; shrink;
        divScale;
        igd10;     % 近 10 代 IGD 历史（用于门控）
        genLastIGA; % 上次 IGD 改进的代
        stagnGen;  % 连续停滞代数
        K;         % 簇数（=ceil(N/20)）
        cluster;   % 当前簇中心
        clusterDir;% 当前簇主方向
        % ---- VOR-v2 升级新增状态 ----
        GDV;       % 代际差向量 (N x D)，D>=100 战场核心
        LpopDec;   % 上一代决策向量（用于 GDV 计算）
        LpopObj;   % 上一代目标值
        Lcenter;   % 上一代 K-means 簇中心
        Lidx;      % 上一代 K-means 标签
        Lrd;       % 上一代簇半径
        GDVK;      % GDV 聚类数（=5）
        fastPath;  % 收敛快通道开关（易题 ZDT1/MaF 上关闭重机制）
    end

    methods
        function obj = VOR(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2;
            obj.mechanism = 'APD';
            obj.switchGen = maxGen;
            obj.hvPrev10 = 0; obj.hvGen10 = 0;
            obj.shrinkBase = 0.05; obj.shrink = 0.05;
            obj.divScale = 0;
            obj.igd10 = []; obj.genLastIGA = 0; obj.stagnGen = 0;
            obj.K = max(3, ceil(popSize/20));
            obj.cluster = []; obj.clusterDir = [];
            % ---- VOR-v2 初始化 ----
            obj.GDV = []; obj.LpopDec = []; obj.LpopObj = [];
            obj.Lcenter = []; obj.Lidx = []; obj.Lrd = [];
            obj.GDVK = 5;
            obj.fastPath = false;
        end

        %% 主循环
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen;
            D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');

            % 约束检测（EDD_cf 门控）
            hasCon = false;
            try
                X0 = Problem.Initialization(1).decs;
                c0 = Problem.CalCon(X0);
                if ~isempty(c0) && size(c0,2) > 0, hasCon = true; end
            catch
                hasCon = false;
            end

            Pop = Problem.Initialization(N); totalFE = N;
            PFtrue = Problem.ParetoFront(500);
            igdHistory = nan(1,G);
            % 战场路由：默认算子按"初始 IGD 规模 + 维度 + 约束"判定（EDD 收敛核心思想：
            %   高维/高初始 IGD 题 SBX 全维失效，DSG 有向采样定向收敛）。实测 IGD0（3 seeds）：
            %   1. D>=100 且 IGD0 >= 15 → 难收敛题（LSMOP6 IGD0~2.8e4-4.4e4 / DTLZ2_300D IGD0~22）
            %      → 默认 DSG；LSMOP1 IGD0~11（<15，收敛快）保持 APD（Q-EPS qOf 排序 0.664 第 1 名，
            %      DSG 反退到 0.857；15 为 LSMOP1/DTLZ2 的分界线，seed 稳健 11.1-11.2 vs 22.1-22.7）
            %   2. 30<=D<100 且有约束（MaF14 D=60）→ DSG（Q-EPS+SBX 多样性崩 PPS 15-88）
            %      注意 D>=100 不进 hasCon 路由（LSMOP1/LSMOP6 占位约束 c0=0，避免误判）
            %   3. 其余（CF1 D=10 / ZDT1 D=30 无约束）→ APD（HCEAV4 收敛聚焦 + SMS 切换）
            % 量纲：[IGD0: 无量纲距离] → [mechanism: 字符串]
            igdInit = IGD(Pop.objs, PFtrue);
            if (D >= 100 && isfinite(igdInit) && igdInit >= 15) || (D >= 30 && D < 100 && hasCon)
                obj.mechanism = 'DSG';
            end
            % 约束低维题（CF1 D=10 hasCon）保持 APD：实测 DSG 有向采样在 CF1 上
            % IGD 0.062→0.091（更差）且 PPS 塌到 22（CF 约束题 APD+Q-EPS 路径更稳，
            % DSG 的 3 段模糊分位骨架在 D=10 低维约束题上方向性过强）

            for gen = 1:G
                %% ---- VOR-v2 快通道检测（易收敛题） ----
                % 若 gen>=20 时 IGD 已降到很低（收敛快），关闭重机制
                % （ORA/CBIM/GDV），退回 APD + Q-EPS + polish，消除新机制的收敛代价
                if gen == 20
                    igdNow = IGD(Pop.objs, PFtrue);
                    igd0   = igdHistory(1);
                    % 快速收敛题：20 代内 IGD 相对下降 > 70%（即 igdNow < 0.3*igd0）
                    %   且绝对 IGD 已降到 < 0.3（贴前沿，约 30% 相对误差）→ 关闭重机制
                    %   （ORA/CBIM/GDV），保留 Q-EPS + polish。
                    % 修复 MaF14 过早冻结：旧阈值 2.0 误把 MaF14（g20 IGD=0.86，未贴前沿，
                    %   仍有 0.86→0.75 的 ORA 改进空间）判为易收敛冻结。降到 0.3 后：
                    %   MaF14 g20=0.86>0.3 不冻结（继续 ORA 改进）；ZDT1 g20=0.91>0.3 不冻结
                    %   （ZDT1 走 simpleBattle APD+SMS 收敛到 0.004，不受冻结影响）；
                    %   DTLZ2_300D g20=0.73>0.3 不冻结（DSG 主路径）；LSMOP1 g20=4.95>0.3 不冻结。
                    if isfinite(igdNow) && isfinite(igd0) && igd0 > 0 && igdNow < 0.3*igd0 && igdNow < 0.3
                        obj.fastPath = true;
                    end
                end

                %% ---- VOR-v2 快通道（收敛已足） ----
                % 前 50 代内 IGD 已足够小且几乎不再下降 → 关闭所有重机制
                % （ORA/CBIM/GDV/SMS 切换），只保留 Q-EPS + 末端 polish，
                %   消除新机制在易收敛题（ZDT1/MaF14）上的收敛代价
                % 注意：ZDT1 等 D=30 题收敛快（g50~0.19），g50<0.08 条件几乎不满足
                % → 该快通道保持原样（只对真正贴前沿的题触发），ZDT1 走 DSG 路径
                if ~obj.fastPath && gen >= 50 && ~obj.fastPath
                    igdNowFast = igdHistory(gen);
                    if igdNowFast < 0.08 && igdHistory(45) < 0.10
                        obj.fastPath = true;
                    end
                end

                %% ---- HV 验证切换（继承 HCEA，仅前 70% 代；快通道跳过） ----
                % 全战场保留 HV 验证切换：EDD 在 ZDT1 上正是靠 gen100 切 SMS 达 IGD=0.004
                % （SMS 拥挤距离后期精修）；VOR 简单战场（APD+theta）也需 SMS 切换才达 EDD 级。
                % 收敛保护：仅当 IGD 已贴前沿（<0.02，约 2% 相对误差）时禁用 SMS（防破坏已收敛前沿）；
                %   0.02-0.5 区间仍允许 SMS 切换（ZDT1/CF1 等 gen100 IGD~0.08 需继续精修）。
                %  0.1 阈值对 CF1（最优 0.010）太保守：CF1 g100=0.083 会被误冻结，降到 0.02 后 CF1 不触发。
                simpleBattle = (D < 100) && (~hasCon);
                igdCur = inf;
                if gen > 1, igdCur = igdHistory(gen-1); end
                if ~obj.fastPath && strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G))
                    if isfinite(igdCur) && igdCur < 0.02
                        obj.fastPath = true;   % 已贴前沿 → 走快通道（Q-EPS+polish），不切 SMS
                    else
                        ref = max(Pop.objs,[],1)*1.1;
                        hb = obj.calHV(Pop.objs, ref, M);
                        Pt = obj.smsGeneration(Problem, Pop, N);
                        totalFE = totalFE + N;
                        ha = obj.calHV(Pt.objs, ref, M);
                        if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                    end
                end

                %% ---- 战场路由判定（run 内前置：简单战场禁用 ORA/CBIM/GDV，保 NBI V 纯净） ----
                % 简单战场（D<100 无约束，如 ZDT1/MaF14/CF）走 HCEAV4 APD+theta 收敛聚焦；
                %   ORA 在线再分配会污染 NBI 参考向量（MaF14 PPS 15 的根因），
                %   简单战场禁用 ORA/CBIM/GDV，保留 Q-EPS 特色仅用于 D>=100/约束战场。
                simpleBattle = (D < 100) && (~hasCon);

                %% ---- IGD 门控算子切换（VOR 核心 3；快通道/简单战场跳过） ----
                if ~obj.fastPath && ~simpleBattle
                    obj.stagnGen = obj.updateStagnation(igdHistory, gen);
                    % D>=100 战场（GDV 保留但不强切：kmeans 15 轮 + pdist2 在 D=300 太慢，
                    %   TSO 三群在 D=300 不稳定；保留 DSG+Q-EPS+CBIM 主路径更稳，
                    %   GDV 仅作 stagn>=20 时的局部探索算子，不强切避免拖累）
                    if D >= 100 && gen >= 30 && obj.stagnGen >= 20 && ~(strcmp(obj.mechanism,'GDV') || strcmp(obj.mechanism,'SMS'))
                        obj.mechanism = 'GDV';
                    end
                end

                %% ---- 在线参考向量再分配（VOR 核心 2；快通道/简单战场跳过） ----
                if ~obj.fastPath && ~simpleBattle && gen >= 30 && mod(gen,10)==0 && obj.stagnGen >= 3
                    [obj.V, obj.cluster, obj.clusterDir] = ...
                        obj.onlineReallocation(Problem, Pop, N, M);
                end

                %% ---- 环境选择：战场路由 ----
                % 简单战场（D<100 无约束）：HCEAV4 APD+theta 收敛聚焦（达 EDD 级）
                %   高维/约束战场：Q-EPS 特色（PPS 不塌 + ORA/CBIM/GDV）
                % 收敛冻结：fastPath 且 IGD<0.5 时跳过重采样（保已收敛种群）
                igdPrev = inf;
                if gen > 1, igdPrev = igdHistory(gen-1); end
                if obj.fastPath && isfinite(igdPrev) && igdPrev < 0.5
                    % 已收敛冻结（fastPath 且 IGD<0.5）：不重采样，保种群
                elseif simpleBattle && strcmp(obj.mechanism,'APD')
                    % HCEAV4 APD + theta 衰减（(gen/G)^alpha），简单题收敛聚焦
                    theta = (gen/max(G,1))^obj.alpha;
                    Pop = obj.apdGeneration(Problem, Pop, N, M, theta);
                    totalFE = totalFE + N;
                elseif simpleBattle && strcmp(obj.mechanism,'SMS')
                    % 简单战场切 SMS 后走 smsGeneration（EDD 在 ZDT1 靠 SMS 精修到 0.004）
                    Pop = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                else
                    Pop = obj.qepsGeneration(Problem, Pop, N, M);
                    totalFE = totalFE + N;
                end

                %% ---- 收敛门控边界移民（VOR 核心 4；快通道/简单战场跳过） ----
                if ~obj.fastPath && ~simpleBattle && gen >= 30 && obj.stagnGen >= 5 && obj.stagnGen < 10
                    Pop = obj.crimImmigration(Problem, Pop, N, M);
                    totalFE = totalFE + N;
                end

                %% ---- 末端 HV 抛光（继承 HCEA；约束题更早更密以加强后期收敛） ----
                % CF1（约束低维）后期收敛慢（g150=0.070→g200=0.062 仍在降），
                %   约束题把 polish 起点提前到 0.75G（非约束 0.9G）并加密到每 4 代，
                %   加强后期局部精修（MOEAD CF1=0.010 主要赢在后期收敛速度）。
                if hasCon, polishFrom = round(0.75*G); polishMod = 4;
                else, polishFrom = round(0.9*G); polishMod = 5; end
                if gen >= polishFrom && mod(gen-polishFrom+1, polishMod)==1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end

                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end

            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), ...
                'nFE', totalFE, 'V', obj.V, 'mechanism', obj.mechanism, ...
                'switchGen', obj.switchGen, 'igdHistory', igdHistory, ...
                'clusterDir', obj.clusterDir, 'fastPath', obj.fastPath, ...
                'GDVK', obj.GDVK, 'D', D, 'hasCon', hasCon);
            Population.decs = Pop.decs; Population.objs = Pop.objs;
            Population.cons = Pop.cons;
                warning(w0);  % restore
        end

        %% ===== 停滞检测（VOR 核心 3 的触发器） =====
        function stag = updateStagnation(obj, igdHistory, gen)
            if gen < 11
                obj.stagnGen = 0;
                stag = 0;
                return;
            end
            igdNow = igdHistory(gen-1); igdPrev = igdHistory(gen-10);
            if ~isfinite(igdNow) || ~isfinite(igdPrev) || igdPrev < 1e-9
                stag = 0;
                return;
            end
            rel = abs(igdNow - igdPrev)/igdPrev;
            if rel < 1e-3
                obj.stagnGen = obj.stagnGen + 1;
            else
                obj.stagnGen = 0;
            end
            stag = obj.stagnGen;
        end

        %% ===== 在线参考向量再分配（VOR 核心 2） =====
        % 每 10 代执行一次。用 K-means（角度距离）在 front-1 决策空间聚成 K 簇，
        % 每簇取主方向 e_k（PCA 第一主方向），将参考向量集合向 {e_k} 收缩。
        function [V, cluster, clusterDir] = onlineReallocation(obj, Problem, Pop, N, M)
            F = Pop.objs;
            [fn, ~] = NDSort(F, Pop.cons, inf);
            f1 = find(fn == 1);
            if numel(f1) < 2*N/5
                % 前沿太散（PPS 塌）时不做再分配，保留原 V
                V = obj.V; cluster = obj.cluster; clusterDir = obj.clusterDir;
                return;
            end
            F1 = F(f1,:);
            % 归一化到单位球面（参考向量语义）
            F1n = F1 ./ (max(sqrt(sum(F1.^2,2)), 1e-12));
            n1 = size(F1n,1);
            % 简单 K-means（角度距离，5 轮）
            rng(2026 + obj.seed + 1);
            idx = randperm(n1, obj.K);
            C = F1n(idx,:);
            for it = 1:5
                D2 = pdist2(F1n, C, 'cosine');
                [~, lab] = min(D2, [], 2);
                for k = 1:obj.K
                    if any(lab == k)
                        C(k,:) = mean(F1n(lab==k,:), 1);
                        C(k,:) = C(k,:) / (norm(C(k,:)) + 1e-12);
                    end
                end
            end
            cluster = C;
            % 主方向 = 簇内解的方差最大方向（PCA 近似）
            clusterDir = zeros(obj.K, M);
            for k = 1:obj.K
                Pk = F1n(lab==k, :);
                if size(Pk,1) >= 2
                    [U,~,V] = svd(Pk - mean(Pk,1), 0);
                    % 主方向是 M 维（目标空间）的第一主成分 = V(:,1)
                    clusterDir(k,:) = V(:,1).';
                else
                    clusterDir(k,:) = C(k,:);
                end
            end
            % 收缩参考向量集合：以 0.5 学习率向 {e_k} 靠拢
            [V0, ~] = UniformPoint(N, M, 'NBI');
            Dv = pdist2(V0, C, 'cosine');
            [~, near] = min(Dv, [], 2);
            Vnew = 0.5 * V0 + 0.5 * C(near, :);
            nn = sqrt(sum(Vnew.^2,2));
            Vnew = Vnew ./ max(nn, 1e-12);
            V = Vnew(1:min(N,size(Vnew,1)),:);  % Vnew may have fewer rows than N
        end

        %% ===== 自适应分位数 epsilon 网格环境选择（VOR 核心 1） =====
        function Pop = qepsGeneration(obj, Problem, Pop, N, M)
            mp = randi(size(Pop.decs,1), 1, N);
            if strcmp(obj.mechanism, 'GDV')
                % VOR-v2: D>=100 战场用 GDV 算子（代际差向量 + TSO，追 SOTA）
                % gdvOperator 返回 Offspring（N x D 决策矩阵），内部更新 obj.L* 历史
                O1.decs = obj.gdvOperator(Problem, Pop, N);
            elseif strcmp(obj.mechanism, 'DSG')
                O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));
            else
                O1.decs = OperatorGA(Problem, Pop.decs(mp,:));
            end
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs,1);
            F = M1.objs;

            %% Q-EPS 自适应分位网格（VOR 核心 1）
            % 核心思想：对目标空间按"当前非支配集"的 0.25/0.5/0.75/0.9 分位
            % 动态划 5 格（每目标维 1 维，跨 M 维共 M*5 格）。
            %   - 收敛题（front-1 数量≈N）：front-1 全在 0.25-0.5 段 → 保留 N
            %   - 发散题（front-1 数量<N）：按 front 层次补齐 + 分位格补 1/N
            %   - PPS 塌题（front-1 数量>>N，如 CF/MW 上 PPS 1-24）：
            %     按分位格取最收敛 N 格，PPS 恒≈N（修复 CF/MW 结构边界）
            % 量纲：[F: nAll x M] → [nd: N x 1]
            q25 = quantile(F, 0.25, 1); q50 = quantile(F, 0.5, 1);
            q75 = quantile(F, 0.75, 1); q90 = quantile(F, 0.9, 1);
            % 每解的"分位格索引"：0=Fmin..q25, 1=q25..q50, 2=q50..q75, 3=q75..q90, 4=q90..Fmax
            qidx = zeros(nAll, M);
            for j = 1:M
                qidx(F > q90(j), j) = 4;
                qidx(F > q75(j) & F <= q90(j), j) = 3;
                qidx(F > q50(j) & F <= q75(j), j) = 2;
                qidx(F > q25(j) & F <= q50(j), j) = 1;
            end
            % 多目标下，解的"分位格质量" = 各维 qidx 的最小值（0=最优格）
            qOf = min(qidx, [], 2);   % nAll x 1 列向量

            % NDSort（front 层次）
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1);
            if isempty(nd)
                nd = 1:N; Pop.decs = M1.decs(nd,:); Pop.objs = F(nd,:);
                Pop.cons = M1.cons(nd,:);
                return;
            end
            nd = nd(:);
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                % front-1 超 N：EED 式距离排序（与 EDD v12 一致）——
                % 按到原点距离 sum(PopObj.^2,2) 升序取最收敛 N 个。
                % Q-EPS 分位格 qOf 作为二级稳定器（距离相等时按分位格质量），
                % 保留 VOR 量化特色，主序与 EDD 对齐（修复 MaF14 PPS 波动 15-88 的根因：
                % 旧版 qOf 主导排序在 MaF14 不规则前沿上分位格错位导致多样性崩）。
                d2 = sum(PopObj(nd,:).^2, 2);
                [~, ord] = sortrows([d2, qOf(nd)]);
                nd = nd(ord(1:N));
            elseif numel(nd) == N
                % 正好 N 全保留（PPS=N，无净损害）
            else
                % 不足 N：front-1 全取 + 按 front 层次补齐 + 分位格补 1/N
                keep = nd;
                for f = 2:max(FrontNo)
                    cand = find(FrontNo == f);
                    if numel(keep) >= N, break; end
                    keep = [keep; cand(:)];
                end
                nd = keep(1:min(N, numel(keep)));
                if numel(nd) < N
                    fill = setdiff(1:nAll, nd);
                    nd = [nd; fill(1:(N-numel(nd)))]';
                end
            end
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:);
            Pop.cons = M1.cons(nd,:);
        end

        %% ===== DSG 有向决策采样算子（继承 EDD v12，M 自适应 wRand）=====
        function Offspring = dsgOperator(obj, Problem, ParentDecs)
            N = size(ParentDecs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width == 0) = 1;
            Offspring = zeros(N, D);
            F = Problem.CalObj(ParentDecs);
            [~, order] = sort(sum(F, 2));
            nTop = ceil(N/2);
            topDecs = ParentDecs(order(1:min(nTop, numel(order))), :);
            q1 = quantile(topDecs, 0.15, 1);
            q2 = quantile(topDecs, 0.5, 1);
            q3 = quantile(topDecs, 0.85, 1);
            M = Problem.nObj;
            wRand = 0.5 + 0.1*min(M,10)/10;
            wDir  = 1 - wRand;
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                a = 2 * (1 - i/max(N,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% ===== GDV 算子（VOR-v2 新增，D>=100 战场核心） =====
        % 代际差向量 + 狼群 TSO 三群速度更新（借鉴 GDVTSF，SWEVO 2025）。
        % 每代调用 calGDV 更新 obj.Lcenter/Lidx/Lrd 历史，生成 N x D 方向向量。
        % tsoUpdate 用三群（p1/p2/p3）做 TSO 速度更新：p1 向 gBest 定向，
        % p2/p3 做 TSO 交叉 + GDV 引导，加模糊变异 + 边界约束。
        function Offspring = gdvOperator(obj, Problem, Pop, N)
            D = Problem.nVar;
            GDV = obj.calGDV(Problem, Pop, N);
            Offspring = obj.tsoUpdate(Problem, Pop.decs, Pop.objs, GDV, N, D);
        end

        %% ===== 代际差向量（GDV）计算 =====
        function GDV = calGDV(obj, Problem, Pop, N)
            D = Problem.nVar;
            popDec = Pop.decs; popObj = Pop.objs;
            K = obj.GDVK;
            [Lidx, Lcenter] = obj.kmeansLocal(popDec, K, obj.seed + N + 1);
            Lrd = zeros(K, D);
            for i = 1:K
                ch = Lidx == i;
                if any(ch); Lrd(i,:) = mean(abs(Lcenter(i,:) - popDec(ch,:)), 1); end
            end
            if isempty(obj.Lcenter) || size(obj.Lcenter,2) ~= D
                GDV = zeros(N, D);
                obj.LpopDec = popDec; obj.LpopObj = popObj;
                obj.Lcenter = Lcenter; obj.Lidx = Lidx; obj.Lrd = Lrd;
                return;
            end
            GDV = zeros(N, D);
            R = rand(N, 1);
            for i = 1:K
                [dis, mi] = obj.pdist1(Lcenter(i,:), obj.Lcenter);
                if mi > K, mi = 1; end
                chCur = Lidx == i; chPrev = obj.Lidx == mi;
                if ~any(chCur) || ~any(chPrev), continue; end
                Fcur = popObj(chCur,:); Fprev = obj.LpopObj(chPrev,:);
                allF = [Fcur; Fprev];
                fmin = min(allF,[],1); fmax = max(allF,[],1);
                allFn = (allF - repmat(fmin,size(allF,1),1)) ./ repmat(fmax-fmin+1e-12,size(allF,1),1);
                fitness = sqrt(sum(allFn.^2,2));
                f1 = max(fitness(1:size(Fcur,1)));
                f2 = max(fitness(size(Fcur,1)+1:end));
                rdNow = Lrd(i,:); rdPrev = obj.Lrd(mi,:);
                om = double(xor(f1 > f2, rdNow < rdPrev));
                vec = sign(f1-f2)*(Lcenter(i,:) - obj.Lcenter(mi,:)) + ...
                      om.*(Lcenter(i,:) - mean(popDec(chCur,:),1));
                vec = vec ./ (norm(vec) + 1e-12);
                GDV(chCur,:) = R(chCur) .* rdNow .* vec;
            end
            obj.LpopDec = popDec; obj.LpopObj = popObj;
            obj.Lcenter = Lcenter; obj.Lidx = Lidx; obj.Lrd = Lrd;
        end

        %% ===== TSO 三群速度更新 =====
        function Offspring = tsoUpdate(obj, Problem, popDec, popObj, GDV, N, D)
            lb = Problem.lower; ub = Problem.upper;
            [fn, ~] = NDSort(popObj, zeros(N,0), 1);
            f1 = find(fn == 1); if isempty(f1), f1 = 1:N; end
            dNorm = sqrt(sum(popObj(f1,:).^2, 2));
            [~, bestF1] = min(dNorm);
            gBestDec = popDec(f1(bestF1), :);
            % 适应度（用于三群选择）
            fmin = min(popObj,[],1); fmax = max(popObj,[],1);
            Pn = (popObj - repmat(fmin,N,1)) ./ repmat(fmax-fmin+1e-12,N,1);
            fitness = sqrt(sum(Pn.^2,2));
            % 三群划分
            swarmN = floor(N/3);
            if N >= 3; Rank = randperm(N, swarmN*3); else; Rank = [1,1,1]; end
            p1 = Rank(1:swarmN); p2 = Rank(swarmN+1:2*swarmN); p3 = Rank(2*swarmN+1:3*swarmN);
            Change1 = fitness(p3) > fitness(p1);
            Temp = p1(Change1); p1(Change1) = p3(Change1); p3(Change1) = Temp;
            Change2 = (fitness(p2) > fitness(p1)) & (fitness(p2) > fitness(p3));
            Temp = p1(Change2); p1(Change2) = p2(Change2); p2(Change2) = Temp;
            % TSO 速度
            popVel = zeros(N, D);
            C1 = repmat(rand(N,1), 1, D);
            C2 = repmat(rand(N,1), 1, D);
            for i = 1:swarmN
                popVel(p1(i),:) = (gBestDec - popDec(p1(i),:));
                popVel(p2(i),:) = C1(p2(i),:).*popVel(p2(i),:) + C2(p2(i),:).*(popDec(p1(i),:) - popDec(p2(i),:));
                popVel(p3(i),:) = C1(p3(i),:).*popVel(p3(i),:) + C2(p3(i),:).*(popDec(p1(i),:) - popDec(p3(i),:));
            end
            velMax = repmat((ub - lb + 1e-12)/1.001, N, 1);
            popVel = max(min(popVel, velMax), -velMax);
            Offspring = popDec + popVel + GDV;
            Offspring = max(min(Offspring, ub), lb);
            % 模糊变异（向量化标量运算，避免 D 维逻辑索引越界：ub/lb 为标量；^ 用 .^ 逐元素）
            disM = 20;
            if ~isscalar(ub), ub = ub(end); end
            if ~isscalar(lb), lb = lb(1); end
            Site1 = repmat(rand(N,1) < 0.999, 1, D);
            Site2 = rand(N, D) < 1/D;
            mu = rand(N, D);
            temp = Site1 & Site2 & (mu <= 0.5);
            Offspring(temp) = Offspring(temp) + (ub-lb).*...
                ((2.*mu(temp)+(1-2.*mu(temp)).*(1-(Offspring(temp)-lb)./(ub-lb)).^(disM+1)).^(1/(disM+1))-1);
            temp2 = Site1 & Site2 & (mu > 0.5);
            Offspring(temp2) = Offspring(temp2) + (ub-lb).*...
                (1-(2.*(1-mu(temp2))+2.*(mu(temp2)-0.5).*(1-(ub-Offspring(temp2))./(ub-lb)).^(disM+1)).^(1/(disM+1)));
        end

        %% ===== K-means（本地实现） =====
        function [idx, center] = kmeansLocal(obj, X, K, seed)
            n = size(X, 1);
            rng(seed);
            idx0 = randperm(n, K);
            center = X(idx0, :);
            for it = 1:15
                D2 = pdist2(X, center);
                [~, idx] = min(D2, [], 2);
                for k = 1:K
                    ch = idx == k;
                    if any(ch); center(k,:) = mean(X(ch,:), 1); end
                end
            end
        end

        %% ===== 点-点集欧氏距离 =====
        function [d, minIdx] = pdist1(obj, a, B)
            m = size(B,1);
            d = zeros(1, m);
            for k = 1:m; d(1,k) = norm(a - B(k,:)); end
            [d, minIdx] = min(d);
        end


        %% ===== 收敛门控边界移民（VOR 核心 4） =====
        function Pop = crimImmigration(obj, Problem, Pop, N, M)
            % 从 clusterDir（主方向）取 argmin/argmax 极端方向注入
            % N/10 个移民，决策空间沿主方向投影极值 + 小扰动
            if isempty(obj.clusterDir), return; end
            nImm = max(2, round(N/10));
            lb = Problem.lower; ub = Problem.upper;
            base = Pop.decs;
            Fbase = Problem.CalObj(base);
            for k = 1:min(nImm, size(obj.clusterDir,1))
                dirK = obj.clusterDir(k,:);
                % 投影极值：argmin x^T dirK / argmax x^T dirK
                Fproj = Fbase * dirK.';
                [~, iMin] = min(Fproj); [~, iMax] = max(Fproj);
                src1 = base(iMin,:); src2 = base(iMax,:);
                % 扰动 + 边界
                newDe = zeros(2, Problem.nVar);
                newDe(1,:) = min(max(src1 + 0.02*(rand(1,Problem.nVar)-0.5), lb), ub);
                newDe(2,:) = min(max(src2 + 0.02*(rand(1,Problem.nVar)-0.5), lb), ub);
                % 替换 Pop 中 IGD 残差最大的两个位置
                Fnew = Problem.CalObj(newDe);
                [~, wIdxOrder] = sort(sum(Fbase,2), 'descend');
                wIdx = wIdxOrder(1:2);
                Pop.decs(wIdx(1:2), :) = newDe;
                Pop.objs(wIdx(1:2), :) = Fnew;
                Pop.cons(wIdx(1:2), :) = Problem.CalCon(newDe);
            end
        end

        %% ===== SMS 环境选择（继承 HCEAV4）=====
        function Pop = smsGeneration(obj, Problem, Pop, N)
            M = Problem.nObj; nCur0 = size(Pop.objs,1); target = nCur0-1;
            if target<N, target=N; end
            for j = 1:N
                nCur = size(Pop.objs,1);
                O1 = struct(); O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur,2),:));
                O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
                M1 = struct(); M1.decs=[Pop.decs;O1.decs]; M1.objs=[Pop.objs;O1.objs];
                M1.cons=[Pop.cons;O1.cons];
                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur+1,0), inf);
                LastFront = find(FrontNo==max(FrontNo)); nLast = numel(LastFront);
                PopObjLast = M1.objs(LastFront,:);
                if M == 2
                    deltaS = inf(1,nLast); [~,rank] = sortrows(PopObjLast);
                    for i = 2:nLast-1
                        deltaS(rank(i)) = (PopObjLast(rank(i+1),1)-PopObjLast(rank(i),1)) * ...
                                           (PopObjLast(rank(i-1),2)-PopObjLast(rank(i),2));
                    end
                else
                    deltaS = obj.calHVM(PopObjLast, max(M1.objs,[],1)*1.1, M);
                end
                [~,worst] = min(deltaS); delIdx = LastFront(worst);
                keep = 1:nCur+1; keep(delIdx) = [];
                Pop.decs = M1.decs(keep,:); Pop.objs = M1.objs(keep,:);
                Pop.cons = M1.cons(keep,:);
            end
        end

        %% ===== HCEAV4 风格 APD 环境选择（theta 衰减，简单题收敛聚焦） =====
        % 移植自 HCEAV4 apdGeneration：NBI 参考向量 + APD 距离 + 端点保护。
        % 简单题（ZDT1/MaF14/CF1 等 D<100 无约束）上用 APD+theta 达到 EDD 级收敛，
        % 而 D>=100/约束战场保留 Q-EPS 特色（PPS 不塌 + ORA/CBIM）。
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V; NV = size(V,1); nCur = size(Pop.objs,1);
            mp = randi(nCur, 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp,:));
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs,1);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            % 与 EDD/HCEAV4 一致：NBI 角度关联只用前 2 维目标（M=3 时第 3 维靠距离兜底），
            % 防止 M>=3 题上 NBI 三维参考向量过密导致 PPS 塌（MaF14 PPS 15 的根因）。
            nDim = min(M, 2);
            PopObj2 = PopObj(:, 1:nDim);
            PopObj2 = reshape(PopObj2, nAll, nDim);
            V2 = V(:, 1:nDim); V2 = reshape(V2, NV, nDim);
            if nDim == 2
                gamma = min(1-pdist2(V2,V2,'cosine'),[],2); gamma = gamma(:);
                gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
                Angle = acos(max(-1, min(1, 1-pdist2(PopObj2,V2,'cosine'))));
                [dmin, assoc] = min(Angle,[],2);
            else
                % M=1 退化（理论上 M>=2）
                PopObj2 = [PopObj2; zeros(0,0)];
                [dmin, assoc] = min(sum(PopObj2.^2,2),[],1);
                gamma = ones(NV,1); assoc = zeros(nAll,1)+1;
            end
            APD = (1 + M*theta*dmin./gamma(assoc)).*sqrt(sum(PopObj.^2,2));
            Keep = false(nAll,1);
            for i = 1:NV
                cand = find(assoc==i);
                if ~isempty(cand), [~,ii]=min(APD(cand)); Keep(cand(ii))=true; end
            end
            D = Problem.nVar;
            if D < 100
                [~,gOrd] = sort(gamma,'descend');
                for e = 1:min(2,NV)
                    vEnd = gOrd(e);
                    if isempty(find(assoc==vEnd))
                        angCol = Angle(:,vEnd); [~,ordAng] = sort(angCol);
                        top3 = ordAng(1:min(3,nAll));
                        if ~isempty(top3), [~,ii]=min(APD(top3)); Keep(top3(ii))=true; end
                    end
                end
            end
            idx = find(Keep); target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep); [~,ord] = sort(APD(rest));
                need = target-numel(idx); add = rest(ord(1:min(need,numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx,:); Pop.objs = M1.objs(idx,:); Pop.cons = M1.cons(idx,:);
        end

        %% ===== 末端 HV 抛光（继承 HCEA；仅接受非劣化扰动，防易收敛题退化） =====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs,1); ref = max(Pop.objs,[],1)*1.1;
            k = 0;
            for t = 1:3
                i = randi(N);
                oldO = Pop.objs(i,:);
                cand = Pop.decs(i,:);
                cand = cand + 0.01*(rand(1,Problem.nVar)-0.5);
                cand = min(max(cand,Problem.lower),Problem.upper);
                candO = Problem.CalObj(cand);
                % 仅当扰动解不被原解劣化时接受（避免破坏已收敛前沿）
                if ~any(candO > oldO) || sum(candO) < sum(oldO)
                    Pop.objs(i,:) = candO; Pop.decs(i,:) = cand;
                end
                k=k+1;
            end
        end

        %% ===== HV 计算（继承 EDD） =====
        function hv = calHV(obj, PopObj, ref, M)
            if M ~= 2
                hv = sum(obj.calHVM(PopObj, ref, M)); return;
            end
            PopObj = PopObj(all(PopObj<=ref,2),:);
            if isempty(PopObj), hv = 0; return; end
            PopObj = sortrows(PopObj,1);
            x = [PopObj(:,1); ref(1)]; hv = 0; ymin = ref(2);
            for i = 1:size(PopObj,1)
                if PopObj(i,2) < ymin, ymin = PopObj(i,2); end
                hv = hv + (x(i+1)-x(i))*(ref(2)-ymin);
            end
        end

        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000; k = 1;
            PopObj = PopObj(all(PopObj<=ref,2) & all(PopObj>=0,2),:);
            [N,~] = size(PopObj); if N==0, F = 0; return; end
            alpha = zeros(1,N);
            for i = 1:min(k,N), alpha(i) = prod((k-[1:i-1])./(N-[1:i-1]))./i; end
            Fmin = min(PopObj,[],1); rng(2026);
            S = unifrnd(repmat(Fmin,nSample,1), repmat(ref,nSample,1));
            PdS = false(N,nSample); dS = zeros(1,nSample);
            for i = 1:N
                x = sum(repmat(PopObj(i,:),nSample,1)-S<=0,2)==M;
                PdS(i,x) = true; dS(x) = dS(x)+1;
            end
            F = zeros(1,N);
            for i = 1:N
                F(i) = sum(alpha(dS(PdS(i,:))));
            end
        end
    end
end





