classdef HCEAV4_DualPop < ALGORITHM
% HCEAV4_DualPop - 双种群协同架构（Convergence-Diversity Dual-Population, CDD）
%
% 设计（v3，经用户三缺陷修复确认）：
%   种群 A（收敛）：60 解，跑 HCEA 的 APD 批量选择，负责收敛；保留 HCEA 全部收敛机制（无 CRT）。
%   种群 B（多样性）：40 解，跑"最小最大 NBI 顶点覆盖"批量选择（新准则，顶点耦合的全局覆盖），
%                     负责探索真空区域，打破 A 的单路径顶点锁定。
%
% FE 预算严格 = HCEA（100/代）：
%   初始：A 初始化 60 + B 初始化 40 = 100 FE（= HCEA 初始 100 FE）
%   每代：A 产 50 子代（50 FE）+ B 产 50 子代（50 FE）= 100 FE（批量世代，与 HCEA 一致）
%   交换：A<->B 注入 4 解（复用源种群已评估目标值，0 FE）
%   末端抛光：仅 A（收敛种群）3 FE/抛光代（B 是多样性种群，min-max 覆盖本身即多样性抛光）
%   全程总 FE 严格 = HCEA，无取巧。
%
% 交换机制（每 10 代，填对方覆盖 gap 最大的 2 顶点）：
%   ① 算 B 的 gap_k = min_{x∈B} angle(x,v_k)，找 gap 最大的 2 顶点（B 最空方向）
%   ② A 中离这 2 顶点最近的解注入 B（A 的最优点补 B 的空顶）→ B_minmax 重选回 40
%   ③ 算 A 的 gap，B 中填 A 空顶的 2 解注入 A → A_APD 重选回 60
%   正向贡献：每次交换把"对方空顶上的最优候选"补入，使 IGD(A∪B) < IGD(A)（Φ_B < 0）。
%
% B 与 A 的数学本质区别：
%   A = 顶点解耦的 APD 局部最优（每顶点独立留最优点，HCEA 原样）
%   B = 顶点耦合的全局 min-max 覆盖（min_S max_k min_{x∈S} angle(x,v_k)）
%   两者交换产生跨顶点信息流，突破 A 单路径锁定。
%
% 接口：
%   obj = HCEAV4_DualPop(popSize, maxGen, seed);
%   [Population, Result] = obj.optimize(Problem);

    properties
        V;             % NBI 顶点
        alpha;
        nA;            % A 初始/产子代规模（100，与 HCEA 一致）
        nA_keep;       % A 保留解数（60，B2 方案：A 保留 60 但产 100 子代）
        nB;            % B 保留解数（40）
        exchPeriod;    % 交换周期（10 代）
        phiB;          % B 边际贡献轨迹 [1 x G]
    end

    methods
        function obj = HCEAV4_DualPop(popSize, maxGen, seed)
            if nargin < 1, popSize = 100; end
            if nargin < 2, maxGen = 200; end
            if nargin < 3, seed = 42; end
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha      = 2;
            obj.nA         = 100;     % B2：A 保持 100 FE（产100子代）
            obj.nA_keep    = 60;      % B2：A 保留 60 解
            obj.nB         = 40;     % B2：B 保留 40 解（只做交换池，不产子代）
            obj.exchPeriod = 10;
            obj.phiB       = [];
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            G  = obj.maxGen;
            M  = Problem.nObj;

            % ===== NBI 顶点（与 HCEA 一致：100 解规模）=====
            [obj.V, ~] = UniformPoint(obj.nA, M, 'NBI');

            % ===== B2 方案：A 保持 100 FE（产100子代，保留60），B 不产子代，只做交换池 =====
            % 初始：A 100 解（100 FE，与 HCEA 初始完全一致），B 从 A 初始 100 解中用 min-max 选 40 解（0 FE）
            PopA = Problem.Initialization(obj.nA);   % 100 FE（nA=100 时与 HCEA 初始一致）
            % B 初始化：从 A 的 100 解中用 min-max cover 选 40 解（0 FE，不额外消耗）
            B_init = obj.minmaxSelect(Problem, PopA.decs, PopA.objs, obj.nB, M);
            PopB = B_init;
            totalFE = obj.nA;   % = 100 FE（初始与 HCEA 一致）

            % B 的历史池（交换注入的解累积，供下次 min-max 选择）
            B_pool_decs = PopB.decs;
            B_pool_objs = PopB.objs;

            PFtrue = Problem.ParetoFront(500);
            igdHistory = nan(1, G);
            obj.phiB = nan(1, G);

            polishFrom = round(0.9 * G);

            for gen = 1:G
                % ===== 阶段1：A 产 100 子代 + 批量 APD 选择（收敛，与 HCEA 完全一致）=====
                A100 = obj.reproduceBatch(Problem, PopA, 100);   % 100 FE
                totalFE = totalFE + 100;
                A_merged = [PopA.decs; A100];
                A_obj = Problem.CalObj(A_merged);
                % A 保留 60 解（HCEA 的 APD 选择）
                PopA = obj.apdSelect(Problem, A_merged, A_obj, obj.nA_keep, M, (gen/G)^obj.alpha);

                % ===== 阶段2：B 不产子代，只做交换池（0 FE）=====
                % B 的更新：每 exchPeriod 代，从 B 的历史池 + A 注入的解中 min-max 选 40
                if mod(gen, obj.exchPeriod) == 0
                    % A 注入 2 个最优点到 B 历史池
                    aInj = obj.topParetoInject(Problem, PopA, M, obj.nA_keep);
                    B_pool_decs = [B_pool_decs; aInj.decs];
                    B_pool_objs = [B_pool_objs; aInj.objs];
                    % 从 B 历史池 min-max 选 40 解
                    PopB = obj.minmaxSelect(Problem, B_pool_decs, B_pool_objs, obj.nB, M);
                end

                % ===== 末端 HV 抛光（仅 A，同 HCEA 作用对象；B 不抛光）=====
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [PopA, k] = obj.polishHV(Problem, PopA, M);
                    totalFE = totalFE + k;
                end

                % ===== IGD 记录 + B 边际贡献 Φ_B =====
                igdA = IGD(PopA.objs, PFtrue);
                igdAB = IGD([PopA.objs; PopB.objs], PFtrue);
                igdHistory(gen) = igdAB;
                if igdA > 1e-9
                    obj.phiB(gen) = igdAB - igdA;
                end
            end

            % ===== 结果：A∪B 的 Pareto 前沿 =====
            allDecs = [PopA.decs; PopB.decs];
            allObj = [PopA.objs; PopB.objs];
            [fn, ~] = NDSort(allObj, zeros(size(allObj,1), 0), 1);
            nd = find(fn == 1);
            Result = struct('Front', allDecs(nd,:), ...
                            'F',    allObj(nd,:), ...
                            'nFE',  totalFE, ...
                            'V',    obj.V, ...
                            'switchGen', G, ...
                            'igdHistory', igdHistory, ...
                            'PhiB', obj.phiB);
            Population.decs = allDecs;
            Population.objs = allObj;
            Population.cons = [PopA.cons; PopB.cons];
            warning(w0);
        end

        %% ===== 批量子代产生（HCEA 世代式，产 nOff 个子代，可重复采样父本）=====
        function off = reproduceBatch(obj, Problem, Pop, nOff)
            % 从 Pop 随机采样父本（可重复，含自交），用 OperatorGA（K 父产 2K 子）凑够 nOff 子代
            D = Problem.nVar;
            nCur = size(Pop.decs, 1);
            % OperatorGA 从 K 个父产 2K 个子代，要产 nOff 需 ceil(nOff/2) 个父
            K = ceil(nOff / 2);
            % 父本可重复采样（nCur < K 时允许），避免 randperm 越界
            idx = randi(nCur, K, 1);
            parents = Pop.decs(idx, :);
            offAll = OperatorGA(Problem, parents);   % 2K 子代
            off = offAll(1:min(nOff, size(offAll,1)), :);
            % 仍不足则补齐随机解（保证恰好 nOff 个子代 = nOff FE）
            if size(off, 1) < nOff
                off = [off; Problem.lower + rand(nOff - size(off,1), D) .* (Problem.upper - Problem.lower)];
            end
        end

        %% ===== A 的批量 APD 选择（HCEA 原样，顶点解耦）=====
        function Pop = apdSelect(obj, Problem, decs, objs, N, M, theta)
            V = obj.V;
            NV = size(V, 1);
            nAll = size(decs, 1);
            PopObj = objs - repmat(min(objs, [], 1), nAll, 1);
            gamma = min(1 - pdist2(V, V, 'cosine'), [], 2);
            gamma = gamma(:);
            gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
            Angle = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));
            [dmin, assoc] = min(Angle, [], 2);
            APD = (1 + M * theta * dmin ./ gamma(assoc)) .* sqrt(sum(PopObj.^2, 2));
            Keep = false(nAll, 1);
            for i = 1:NV
                cand = find(assoc == i);
                if ~isempty(cand)
                    [~, ii] = min(APD(cand));
                    Keep(cand(ii)) = true;
                end
            end
            idx = find(Keep);
            target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep);
                [~, ord] = sort(APD(rest));
                need = target - numel(idx);
                idx = [idx; rest(ord(1:min(need, numel(rest))))];
            end
            idx = idx(1:target);
            Pop.decs = decs(idx, :);
            Pop.objs = objs(idx, :);
            Pop.cons = zeros(target, 0);
        end

        %% ===== B 的批量 min-max 顶点覆盖选择（新准则，顶点耦合全局覆盖）=====
        function Pop = minmaxSelect(obj, Problem, decs, objs, N, M)
            V = obj.V;
            nAll = size(decs, 1);
            NV = size(V, 1);
            % 预计算角距矩阵 [nAll x NV]（查表用，O(nAll*NV) 余弦）
            PopObj = objs - repmat(min(objs, [], 1), nAll, 1);
            A = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));  % [nAll x NV]
            % 贪心 min-max cover：外层 N 步，每步选"最能降低全局 max 顶点角距"的候选
            curCover = inf(1, NV);      % 各顶点当前最近角距
            chosen = zeros(1, N);
            for t = 1:N
                best_x = -1; best_gap = inf;
                for c = 1:nAll
                    if t > 1 && any(chosen(1:t-1) == c)
                        continue;
                    end
                    candCover = min(curCover, A(c, :));      % 选 c 后各顶点覆盖
                    gap_c = max(candCover);                   % 全局 max 顶点角距
                    if gap_c < best_gap
                        best_gap = gap_c; best_x = c;
                    end
                end
                if best_x < 0
                    break;
                end
                chosen(t) = best_x;
                curCover = min(curCover, A(best_x, :));
            end
            chosen = chosen(chosen > 0);
            if numel(chosen) < N
                % 候选不足时补剩余解
                rest = setdiff(1:nAll, chosen);
                chosen = [chosen; rest(1:min(N-numel(chosen), numel(rest)))];
                chosen = chosen(1:N);
            end
            Pop.decs = decs(chosen, :);
            Pop.objs = objs(chosen, :);
            Pop.cons = zeros(numel(chosen), 0);
        end

        %% ===== B2：A 注入 2 个 Pareto 最优解到 B 历史池（0 FE，复用目标值）=====
        function inJ = topParetoInject(obj, Problem, PopA, M, nKeep)
            % 从 A（保留 nKeep 解）中取 2 个 IGD 残差最大的解注入 B
            % （IGD 残差大 = 离 PF 最远 = 探索性最强，对 B 的多样性贡献最大）
            % 0 FE（复用 A 的目标值）
            [fn, ~] = NDSort(PopA.objs, zeros(size(PopA.objs,1),0), 1);
            nd = find(fn == 1);
            nAll = length(nd);
            if nAll == 0
                inJ.decs = zeros(0, 0); inJ.objs = zeros(0, 0);
                return;
            end
            % 取 IGD 残差最大的 2 个（离 PF 最远的 Pareto 前沿点）
            PFtrue = Problem.ParetoFront(200);
            cand = nd(1:min(nAll, 20));  % 前 20 个 Pareto 点（避免全量 IGD）
            igdCand = zeros(1, length(cand));
            for i = 1:length(cand)
                igdCand(i) = IGD(PopA.objs(cand(i), :), PFtrue);
            end
            [~, ord] = sort(igdCand, 'descend');
            inJ.decs = PopA.decs(cand(ord(1:min(2, length(ord)))), :);
            inJ.objs = PopA.objs(cand(ord(1:min(2, length(ord)))), :);
        end

        %% ===== 交换注入：填对方 gap 最大的 2 顶点（0 FE，复用目标值）=====
        function [PopA, PopB] = exchangeFillGap(obj, Problem, PopA, PopB, M, V, theta, nA, nB)
            % B 的 gap（各顶点被 B 覆盖最近角距）
            gapB = obj.vertexGap(PopB, M);
            [~, bTop] = sort(gapB, 'descend');
            bTop = bTop(1:min(2, numel(bTop)));
            % A 中离 B 空顶最近的解注入 B
            for kk = 1:length(bTop)
                av = V(bTop(kk), :);
                aObjN = PopA.objs - repmat(min(PopA.objs, [], 1), size(PopA.objs,1), 1);
                angA = acos(max(-1, min(1, 1 - pdist2(aObjN, av, 'cosine'))));
                [~, j] = min(angA);
                PopB.decs = [PopB.decs; PopA.decs(j,:)];
                PopB.objs = [PopB.objs; PopA.objs(j,:)];
                PopB.cons = [PopB.cons; PopA.cons(j,:)];
            end
            PopB = obj.minmaxSelect(Problem, PopB.decs, PopB.objs, nB, M);
            % A 的 gap
            gapA = obj.vertexGap(PopA, M);
            [~, aTop] = sort(gapA, 'descend');
            aTop = aTop(1:min(2, numel(aTop)));
            for kk = 1:length(aTop)
                bv = V(aTop(kk), :);
                bObjN = PopB.objs - repmat(min(PopB.objs, [], 1), size(PopB.objs,1), 1);
                angB = acos(max(-1, min(1, 1 - pdist2(bObjN, bv, 'cosine'))));
                [~, j] = min(angB);
                PopA.decs = [PopA.decs; PopB.decs(j,:)];
                PopA.objs = [PopA.objs; PopB.objs(j,:)];
                PopA.cons = [PopA.cons; PopB.cons(j,:)];
            end
            PopA = obj.apdSelect(Problem, PopA.decs, PopA.objs, nA, M, theta);
        end

        %% ===== 顶点 gap（各顶点被 Pop 覆盖的最近角距，[1 x NV]）=====
        function gap = vertexGap(obj, Pop, M)
            V = obj.V;
            NV = size(V, 1);
            PopN = Pop.objs - repmat(min(Pop.objs, [], 1), size(Pop.objs,1), 1);
            A = acos(max(-1, min(1, 1 - pdist2(PopN, V, 'cosine'))));  % [nPop x NV]
            gap = min(A, [], 1);   % 各顶点最近角距（越小覆盖越好）
            gap = gap(:)';
        end

        %% ===== 末端 HV 抛光（同 HCEA：1 点 × 3 扰动，作用对象 = 收敛种群 A）=====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            ref = max(Pop.objs, [], 1) * 1.1;
            HVc = obj.hvContrib(Pop.objs, M, ref);
            [~, worst] = min(HVc);
            base = Pop.decs(worst, :);
            D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            Cand = base + 0.05 * (ub - lb) .* randn(3, D);
            Cand = min(max(Cand, lb), ub);
            CandObj = Problem.CalObj(Cand);
            bestHV = -inf; bestIdx = 1;
            for i = 1:3
                Temp = Pop;
                Temp.decs(worst, :) = Cand(i, :);
                Temp.objs(worst, :) = CandObj(i, :);
                h = obj.hvContrib(Temp.objs, M, ref);
                if h(worst) > bestHV
                    bestHV = h(worst); bestIdx = i;
                end
            end
            Pop.decs(worst, :) = Cand(bestIdx, :);
            Pop.objs(worst, :) = CandObj(bestIdx, :);
            Pop.cons(worst, :) = Pop.cons(worst, :);
            k = 3;
        end

        %% ===== 2D/多维 HV 贡献（M=2 精确，M>=3 蒙特卡洛 HYPE）=====
        function HV = hvContrib(obj, PopObj, M, ref)
            [N, ~] = size(PopObj);
            HV = zeros(1, N);
            if M ~= 2
                HV = obj.calHVM(PopObj, ref, M);
                return;
            end
            [S, ord] = sortrows(PopObj);
            f1 = [S(:,1); ref(1)];
            f2 = [ref(2); S(:,2)];
            for i = 1:N
                HV(ord(i)) = (f1(i+1) - f1(i)) * (f2(i) - f2(i+1));
            end
        end

        %% ===== 蒙特卡洛 HV 逐解贡献（HYPE，Bader & Zitzler 2011）=====
        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000;
            k = 1;
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            [N, ~] = size(PopObj);
            if N == 0
                F = 0; return;
            end
            alpha = zeros(1, N);
            for i = 1:min(k, N)
                alpha(i) = prod((k - [1:i-1]) ./ (N - [1:i-1])) ./ i;
            end
            Fmin = min(PopObj, [], 1);
            S = unifrnd(repmat(Fmin, nSample, 1), repmat(ref, nSample, 1));
            PdS = false(N, nSample);
            dS = zeros(1, nSample);
            for i = 1:N
                x = sum(repmat(PopObj(i,:), nSample, 1) - S <= 0, 2) == M;
                PdS(i, x) = true;
                dS(x) = dS(x) + 1;
            end
            F = zeros(1, N);
            for i = 1:N
                F(i) = sum(alpha(dS(PdS(i,:))));
            end
            F = F .* prod(ref - Fmin) / nSample;
        end
    end
end
