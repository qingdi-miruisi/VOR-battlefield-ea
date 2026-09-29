classdef EDDV6 < ALGORITHM
    % EDD v6 - 双种群 + EED 网格坐标隐空间开发（换战场 M>=5 高维多目标）
    %
    % 核心创新（区别于 2026 SOTA）：
    %   FDSEA 用频率域 12 参数、GDVTSF 用 kmeans K=5 聚类中心、MOEA-IB 用变量分组权重
    %   做低维参数化基底。EDD v6 用 **EED epsilon 网格的非空格代表点**做隐空间基底——
    %   这是 EDD 贡献1（EED 目标空间 epsilon 网格）的自然延伸，原创。
    %
    % 架构（双种群）：
    %   子种群 A（Na=50）：EED 网格坐标隐空间开发（★ 新增原创机制）
    %     - A 在 K_rep 维网格坐标空间 θ 开发（K_rep = EED 非空格数，动态 20-50）
    %     - θ 经 f(θ)=Σθ_k·x_k^dec/Σθ_k 解码回 D 维决策变量（代表点决策向量加权组合）
    %     - θ 子代：增强1 = 80% SBX+多项式变异 + 20% 单代表点主导（防坍缩）
    %     - 增强2 = reps 每 10 代用当前 Pop.objs 重建 EED 网格刷新（EED 动态提供搜索基底）
    %   子种群 B（Nb=50）：DSG 决策空间探索（保留 v5 强化版a：三段分位骨架 + 变异率自适应
    %     EED 空格数，B 的开发算子）
    %   EED epsilon 网格共享：A 侧维护 reps（搜索基底），B 侧 EED 网格选择维护多样性
    %   跨域交换（每 10 代，零 FE 复用目标值）：A 最优5→B 替换 B 最劣5；B 最优5→A 替换 A 最劣5
    %   末端 polish-HV（继承 v12，FE 计入）
    %
    % FE 预算：初始化 N=100 + 每代 100（A 产 50 θ 解码 + B 产 50 DSG）× 200 代
    %           + polish ≈ 20115-20121（与旧 EDD 同量级；f(θ) 解码零 FE）
    %
    % 消融开关 ablation（load-bearing 验证）：
    %   'full'          - 完整架构
    %   'no-GridCoord'  - A 改决策空间随机采样（去 θ 网格坐标映射）→ 测 θ 机制（IGD）
    %   'no-DSG'        - B 改 SBX 双父交叉（去 DSG 分位骨架探索）→ 测 DSG（HV）
    %   'no-Xchg'       - 去跨域交换（A/B 独立后 EED 选择合并）→ 测交换贡献
    %
    % 红线：不照搬 FDSEA 频率域/kmeans/权重分组作为主路径；EED 网格坐标是 EDD 自己的机制。
    % 公平性：N=100 G=200 不变；PF 口径由问题包装器决定（MaF14/15 M>=5 用 UniformPoint(500)
    %          采样 PF，DTLZ2_300 M=5/8 用解析球面），refPoint=1.1*max(PF)，种子 1:30。

    properties
        ablation;   % 'full' | 'no-GridCoord' | 'no-DSG' | 'no-Xchg'
        epsGrid;    % EED epsilon 网格数（K=10）
    end

    methods
        function obj = EDDV6(popSize, maxGen, seed, ablation)
            obj@ALGORITHM(popSize, maxGen, seed);
            if nargin >= 4 && ~isempty(ablation), obj.ablation = ablation; else obj.ablation = 'full'; end
            obj.epsGrid = 10;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            Na = ceil(N/2); Nb = N - Na;                 % A=50, B=50
            highDim = (D >= 50) || (M >= 5);
            if ~highDim
                error('EDDV6 is designed for M>=5 or D>=50.');
            end

            % ---- 初始化（FE=N）----
            Pop = Problem.Initialization(N);
            totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            nX = min(5, min(Na, Nb));                   % 交换规模（用户指定 5）

            % ---- EED 网格 reps（增强2：初始建一次，每 10 代刷新）----
            reps = obj.eedGridReps(Pop.decs, Pop.objs, M, obj.epsGrid);   % K_rep×D 非空格代表点决策向量
            Krep = size(reps,1);
            % A 的 θ 表示：one-hot 锚定（每个 A 解锚定一个不同 reps，θ 维数=Krep）
            % 用 f(θ) 解码成 A 当前决策向量，使 A 初始 = reps 的凸组合（不同 A 解对应不同 reps）
            A_theta = zeros(Na, Krep);
            anchor = mod(0:Na-1, Krep) + 1;
            if Na > Krep
                anchor = anchor + Krep;            % Na > Krep 时重复锚定
            end
            for i = 1:Na
                a = min(anchor(i), Krep);
                A_theta(i, a) = 1.0;              % one-hot
                % 加小扰动让 θ 不完全稀疏（防 SBX 后维度坍缩）
                A_theta(i, :) = A_theta(i, :) + 0.05*rand(1, Krep);
                A_theta(i, :) = A_theta(i, :) / sum(A_theta(i,:));   % 归一化
            end
            igdA_init = IGD(Pop.objs(1:Na,:), PFtrue);
            igdB_init = IGD(Pop.objs(Na+1:N,:), PFtrue);

            for g = 1:G
                %% ===== 子代生成（FE=N）=====
                A = Pop.decs(1:Na,:); fA = Pop.objs(1:Na,:); cA = Pop.cons(1:Na,:);
                B = Pop.decs(Na+1:N,:); fB = Pop.objs(Na+1:N,:); cB = Pop.cons(Na+1:N,:);

                % ---- A 半：EED 网格坐标隐空间开发（no-GridCoord 消融时改决策空间随机采样）----
                if strcmp(obj.ablation, 'no-GridCoord')
                    O_A = rand(Na, D) .* (Problem.upper - Problem.lower) + Problem.lower;
                else
                    % 增强1：20% 单代表点主导（跳跃）+ 80% SBX+多项式变异（标准 θ 开发）
                    nJump = round(0.2*Na);
                    A_theta_off = A_theta;              % 复制（标准开发父代）
                    % 80%：SBX + 多项式变异（θ 空间）
                    nStd = Na - nJump;
                    A_theta_off(1:nStd,:) = obj.sbxPoly_theta(A_theta, Krep, nStd);
                    % 20%：单代表点主导——随机选一个非空格 k*，θ_k*=1，其余=0.1
                    for j = 1:nJump
                        kstar = randi(Krep);
                        th = 0.1*ones(1, Krep);
                        th(kstar) = 1.0;
                        A_theta_off(nStd+j, :) = th;
                    end
                    % f(θ) 解码：x = Σθ_k·x_k^dec/Σθ_k（代表点决策向量加权组合）
                    O_A = obj.f_theta(A_theta_off, reps, D);
                end

                % ---- B 半：DSG 三段分位骨架探索 + 变异率自适应 EED 空格（保留 v5 强化版a）----
                if strcmp(obj.ablation, 'no-DSG')
                    O_B = obj.sbxOperator(Problem, B);
                else
                    O_B = obj.exploreB(Problem, B, fB, cB, obj.epsGrid, Na, Nb);
                end
                O = [O_A; O_B];                          % N×D
                Os.decs = O;
                Os.objs = Problem.CalObj(Os.decs);
                Os.cons = Problem.CalCon(Os.decs);
                totalFE = totalFE + N;

                %% ===== EED 共享选择（FE=0）：[A; B; A_off; B_off] 200 个体 → N ----
                Pool.decs = [A; B; Os.decs];
                Pool.objs = [fA; fB; Os.objs];
                Pool.cons = [cA; cB; Os.cons];
                Pop = obj.eedSelect(Problem, Pool, N, M, obj.epsGrid);

                % ---- A 的 θ 重锚定：每个 A 解按它对新 reps 的最近邻重新投影（保持 θ 与 reps 同步）----
                if ~strcmp(obj.ablation, 'no-GridCoord')
                    A_new = Pop.decs(1:Na,:);
                    A_theta = obj.reanchor(A_new, reps);
                end

                % ---- 增强2：reps 每 10 代刷新（EED 动态提供搜索基底）----
                if mod(g, 10) == 0
                    reps = obj.eedGridReps(Pop.decs, Pop.objs, M, obj.epsGrid);
                    Krep_new = size(reps,1);
                    if Krep_new ~= Krep
                        Krep = Krep_new;
                        % θ 维度对齐：A 的 θ 按新 reps 重新投影（one-hot 锚定 + 小扰动）
                        if ~strcmp(obj.ablation, 'no-GridCoord')
                            A_theta = obj.reanchor(Pop.decs(1:Na,:), reps);
                        end
                    end
                end

                % ---- 每 10 代跨域交换（FE=0，复用目标值）----
                if ~strcmp(obj.ablation, 'no-Xchg') && mod(g, 10) == 0
                    Pop = obj.crossExchange(Pop, Na, Nb, nX);
                end

                %% ===== 末端 polish-HV（继承 v12：0.9G 起每 5 代 3 次 1% 扰动，FE 计入）=====
                polishFrom = round(0.9*G);
                if g >= polishFrom && mod(g-polishFrom+1, 5) == 1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                igdHistory(g) = IGD(Pop.objs, PFtrue);
            end

            igdA_fin = IGD(Pop.objs(1:Na,:), PFtrue);
            igdB_fin = IGD(Pop.objs(Na+1:N,:), PFtrue);
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            if isempty(nd), nd = 1:N; end
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'ablation', obj.ablation, 'PPS_A', Na, 'PPS_B', Nb, ...
                            'igdA_init', igdA_init, 'igdB_init', igdB_init, ...
                            'igdA_fin', igdA_fin, 'igdB_fin', igdB_fin, 'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== EED 网格代表点（K 个非空格代表点：每格离原点最近的解，返回决策向量）=====
        function reps = eedGridReps(obj, decs, F, M, epsGrid)
            nAll = size(F,1);
            Fmin = min(F,[],1); Fmax = max(F,[],1);
            width = Fmax - Fmin; width(width==0) = 1;
            eps = width / epsGrid;
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            [gU, gI] = unique(gridIdx, 'rows');
            PopObj = F - repmat(Fmin, nAll, 1);
            repsIdx = zeros(numel(gU),1);
            for gu = 1:numel(gU)
                inG = find(gI == gu);
                if ~isempty(inG)
                    [~, ii] = min(sum(PopObj(inG,:).^2, 2));
                    repsIdx(gu) = inG(ii);
                end
            end
            repsIdx = repsIdx(repsIdx>0);    % 仅保留有效代表点（去掉未填格的 0）
            if isempty(repsIdx), repsIdx = 1; end   % 兜底：至少 1 个代表点
            reps = decs(repsIdx,:);   % K_rep×D 非空格代表点决策向量
        end

        %% ===== A 的 θ 子代：SBX + 多项式变异（θ 空间，增强1 的 80% 标准部分）=====
        function P_off = sbxPoly_theta(obj, P, Krep, nStd)
            Np = size(P,1);
            I1 = randi(Np, nStd, 1)';      % nStd 个父1
            I2 = randi(Np, nStd, 1)';      % nStd 个父2
            I2(I2==I1) = I2(I2==I1) + 1; I2(I2>Np) = I2(I2>Np) - Np;   % 确保双父不同
            P1 = P(I1, :); P2 = P(I2, :);
            disC = 20;
            beta = zeros(nStd, Krep); mu = rand(nStd, Krep);
            beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
            beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
            beta = beta .* (-1).^randi([0,1], nStd, Krep);
            beta(rand(nStd,Krep)<0.5) = 1;
            O1 = [(P1+P2)/2 + beta.*(P1-P2)/2;
                  (P1+P2)/2 - beta.*(P1-P2)/2];
            % 多项式变异
            disM = 20; proM = 1;
            Lower = zeros(2*nStd, Krep); Upper = ones(2*nStd, Krep);
            O1 = min(max(O1, Lower), Upper);
            Site = rand(2*nStd, Krep) < proM/Krep;
            mu2 = rand(2*nStd, Krep);
            temp = Site & (mu2<=0.5);
            O1(temp) = O1(temp) + (Upper(temp)-Lower(temp)).*((2.*mu2(temp) + (1-2.*mu2(temp)).*...
                (1-(O1(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)) - 1);
            temp = Site & (mu2>0.5);
            O1(temp) = O1(temp) + (Upper(temp)-Lower(temp)).*(1-(2.*(1-mu2(temp)) + 2.*(mu2(temp)-0.5).*...
                (1-(Upper(temp)-O1(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
            P_off = O1(1:nStd,:);
        end

        %% ===== f(θ) 解码：代表点决策向量加权组合（EED 网格坐标 → D 维决策）=====
        function x = f_theta(obj, theta, reps, D)
            % reps：K_rep×D 非空格代表点决策向量；theta：N×K_rep 权重
            % 每个解 x_i = Σ_k θ_ik · x_k^dec / Σ_k θ_ik（归一化加权，Σθ=0 时退化为均匀）
            N = size(theta,1);
            x = zeros(N, D);
            for i = 1:N
                wsum = sum(theta(i,:));
                if wsum < 1e-9
                    w = ones(1, size(reps,1)) / size(reps,1);   % 均匀退化
                else
                    w = theta(i,:) / wsum;                       % 1×K 归一化权重
                end
                x(i,:) = reps' * w';   % D×1 加权组合（Σ_k w_k · reps(k,:)）
            end
        end

        %% ===== B 半强化版(a)：DSG 三段分位骨架探索 + 变异率自适应 EED 空格（保留 v5）=====
        function O = exploreB(obj, Problem, B, fB, cB, epsGrid, Na, Nb)
            N = size(B,1); D = Problem.nVar; M = Problem.nObj;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;
            F = fB;
            [FrontNo, ~] = NDSort(F, cB, inf);
            f1 = find(FrontNo==1);
            if numel(f1) < 5, f1 = 1:N; end
            q1 = quantile(B(f1,:), 0.15, 1);
            q2 = quantile(B(f1,:), 0.5, 1);
            q3 = quantile(B(f1,:), 0.85, 1);
            Fmin = min(F,[],1); Fmax = max(F,[],1); w = Fmax-Fmin; w(w==0)=1;
            e = w / epsGrid;
            gridIdx = zeros(N, M);
            for i = 1:N
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / e(j)));
                end
            end
            nOcc = size(unique(gridIdx, 'rows'), 1);
            nCell = epsGrid^M;
            nEmpty = max(nCell - nOcc, 0);
            ratio = nEmpty / max(nCell, 1);
            mutScale = 0.1 + 0.9 * min(max(ratio,0),1);
            wRand = 0.5 + 0.1*min(M,10)/10;
            wDir  = 1 - wRand;
            O = zeros(Nb, D);
            for i = 1:Nb
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                a = 2 * (1 - i/max(Nb,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = cand + mutScale * 0.1 * (rand(1,D)-0.5) .* width;
                O(i,:) = min(max(cand, lb), ub);
            end
        end

        %% ===== θ 重锚定：A 解按对新 reps 的最近邻投影到 θ 空间 =====
        function A_theta = reanchor(obj, A_decs, reps)
            Na = size(A_decs,1); Krep = size(reps,1); D = size(A_decs,2);
            A_theta = zeros(Na, Krep);
            for i = 1:Na
                % 每个 A 解找最近的 reps（欧氏距离），该 reps 权重最大
                d2 = sum((reps - A_decs(i,:)).^2, 2);   % K_rep×1
                [~, kstar] = min(d2);
                A_theta(i, kstar) = 1.0;
                % 其余 reps 权重按距离衰减（近 → 大权重，远 → 小权重）
                w = 1 ./ (d2 + 1e-9);
                w = w / sum(w);
                A_theta(i, :) = 0.8 * A_theta(i, :) + 0.2 * w';   % 80% 锚定 + 20% 距离衰减
            end
        end

        %% ===== SBX 双父交叉（no-DSG 消融用：B 改 SBX）=====
        function Offspring = sbxOperator(obj, Problem, ParentDecs)
            N = size(ParentDecs,1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            Offspring = zeros(N, D);
            P1 = randi(N,1,N); P2 = randi(N,1,N);
            P2(P2==P1) = P2(P2==P1) + 1; P2(P2>N) = P2(P2>N) - N;
            X1 = ParentDecs(P1,:); X2 = ParentDecs(P2,:);
            mu = rand(N,D);
            mLE = (mu<=0.5); mGT = (mu>0.5);
            base = 2*mu; base(mGT) = 2-2*mu(mGT);
            expn = ones(N,D)/15; expn(mGT) = -1/15;
            beta = base .^ expn;
            beta = beta .* (-1).^randi([0,1], N, D);
            beta(rand(N,D)<0.5) = 1;
            Offspring = (X1+X2)/2 + beta.*(X1-X2)/2;
            Offspring = min(max(Offspring, lb), ub);
        end

        %% ===== EED 共享选择（epsilon 网格 + front 层次，200 池 → N）=====
        function Pop = eedSelect(obj, Problem, Pool, N, M, epsGrid)
            nAll = size(Pool.objs,1); F = Pool.objs;
            Fmin = min(F,[],1); Fmax = max(F,[],1);
            width = Fmax - Fmin; width(width==0) = 1;
            eps = width / epsGrid;
            PopObj = F - repmat(Fmin, nAll, 1);
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            [gU, gI] = unique(gridIdx, 'rows');
            nd = false(nAll,1);
            for gu = 1:numel(gU)
                inG = find(gI == gu);
                if ~isempty(inG)
                    [~, ii] = min(sum(PopObj(inG,:).^2, 2));
                    nd(inG(ii)) = true;
                end
            end
            kidx = find(nd);
            if numel(kidx) > N
                [~, ordG] = sort(sum(PopObj(kidx,:).^2, 2));
                kidx = kidx(ordG(1:N));
            end
            if numel(kidx) < N
                [FrontNo, ~] = NDSort(F, Pool.cons, inf);
                rest = setdiff(1:nAll, kidx); rest = rest(:);
                if ~isempty(rest)
                    [~, ordF] = sort(FrontNo(rest));
                    take = min(N-numel(kidx), numel(rest));
                    kidx = [kidx; rest(ordF(1:take))];
                end
            end
            if numel(kidx) > N, kidx = kidx(1:N); end
            kidx = kidx(:);
            Pop.decs = Pool.decs(kidx,:); Pop.objs = Pool.objs(kidx,:); Pop.cons = Pool.cons(kidx,:);
        end

        %% ===== 跨域交换（A 最优5→B 最劣5；B 最优5→A 最劣5；零 FE 复用目标值）=====
        function Pop = crossExchange(obj, Pop, Na, Nb, nX)
            N = Na + Nb;
            fA = Pop.objs(1:Na,:); fB = Pop.objs(Na+1:N,:);
            [dA, ordA] = sort(sum(fA.^2, 2));           % 升序：最优在前
            [dB, ordBw] = sort(sum(fB.^2, 2), 'descend');  % 降序：最差在前
            % A→B：A 最优 nX 解 → 替换 B 最劣 nX 解
            B_worst_abs = (Na+1) + ordBw(1:nX);
            Pop.decs(B_worst_abs, :) = Pop.decs(ordA(1:nX), :);
            Pop.objs(B_worst_abs, :) = fA(ordA(1:nX), :);
            Pop.cons(B_worst_abs, :) = Pop.cons(ordA(1:nX), :);
            % B→A：B 最优 nX 解 → 替换 A 最劣 nX 解
            A_worst = ordA(end-nX+1:end);
            B_best = Na + ordBw(end-nX+1:end);
            Pop.decs(A_worst, :) = Pop.decs(B_best, :);
            Pop.objs(A_worst, :) = Pop.objs(B_best, :);
            Pop.cons(A_worst, :) = Pop.cons(B_best, :);
        end

        %% ===== 末端 polish-HV（继承 v12：1% 决策空间扰动 ×3，FE 计入）=====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs,1); ref = max(Pop.objs,[],1)*1.1;
            best = obj.calHV(Pop.objs, ref, M); k = 0;
            for t = 1:3
                i = randi(N);
                cand = Pop.decs; cand(i,:) = cand(i,:) + 0.01*(rand(1,Problem.nVar)-0.5);
                cand = min(max(cand,Problem.lower),Problem.upper);
                candO = Problem.CalObj(cand(i,:));
                Pop.objs(i,:) = candO; Pop.decs(i,:) = cand(i,:);
                Pop.cons(i,:) = Problem.CalCon(cand(i,:));
                k = k+1;
            end
        end

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
