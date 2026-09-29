classdef HCEAV2 < ALGORITHM
% HCEAV2 - 改进型混合收敛-环境选择存档算法（HCEA-V2）
%
% 在 HCEA（混合收敛-环境选择存档）基础上做三项机制创新：
%
%   创新 1：端点保护 APD（Endpoint-Protected APD）
%     HCEA 的 APD 选择阶段对每个参考向量保留 APD 最小的解。当某些
%     端点参考向量（gamma 最大者）长期没有解被保留时，端点区域
%     会系统性丢失（ZDT4/5、UF 系列上 PPS 退化的根源）。HCEA-V2
%     在每代 APD 选择后检查两个 gamma 最大的向量，若其无解保留则
%     从最近关联解中强制回填 1 个，保证端点覆盖。
%
%   创新 2：HV 引导的末端多解搜索（HV-Guided Multi-Point End Search）
%     HCEA 末端抛光仅对 HV 贡献最差的 1 个解做 3 次随机扰动。
%     HCEA-V2 将末端搜索扩展到 HV 贡献最差的 ceil(N/10) 个解，
%     每个解做 2 次候选（1 次沿目标梯度方向的定向扰动 + 1 次
%     随机扰动），共 ceil(N/5) 次函数评估，在最后一 5% 代数中
%     每 5 代触发一次。定向扰动沿"使 HV 贡献增大"的方向（由
%     目标空间梯度估计），随机扰动保留 HCEA 原有机制。
%
%   创新 3：收敛感知切换（Convergence-Aware Switching）
%     HCEA 在第 50/60/70% 代做 HV 验证切换试验。HCEA-V2 在同样
%     3 个检查点做 HV 验证，但增加收敛感知：若 HV 相对改进速率
%     （(HV_gen - HV_{gen-5}) / HV_{gen-5}）连续低于阈值 1e-3，
%     则在下一个检查点直接强制切换到 SMS 精化阶段，不再等待
%     HV 提升验证，避免 APD 阶段在已收敛问题上浪费计算。
%
% 学术诚信：所有机制决策仅使用种群信息（HV、APD、参考向量），
% 不接触真实前沿。PFtrue 仅用于结果评估（igdHistory 记录）。
%
% 接口：
%   obj = HCEAV2(popSize, maxGen, seed);
%   [Population, Result] = obj.optimize(Problem);
%   Population: struct(decs, objs, cons)
%   Result: struct(Front, F, nFE, V, mechanism, switchGen, igdHistory,
%                  hvHistory)

    properties
        V;           % 静态参考向量 [nRef x M]
        alpha;       % APD theta 退火指数（默认 2）
        mechanism;   % 最终采用的机制：'APD' 或 'SMS'
        switchGen;   % 实际切换代数（未切换则为 maxGen）
        hvRate;      % 最近一次 HV 改进速率
    end

    methods
        function obj = HCEAV2(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha    = 2;
            obj.mechanism = 'APD';
            obj.switchGen = maxGen;
            obj.hvRate   = inf;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            N  = obj.popSize;
            M  = Problem.nObj;
            G  = obj.maxGen;
            D  = Problem.nVar;

            %% 初始化
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            totalFE = N;

            %% 收敛过程记录（仅记录，不参与选择）
            PFtrue = Problem.ParetoFront(500);
            igdHistory = zeros(1, G);
            hvHistory  = zeros(1, G);

            %% HV 跟踪（收敛感知切换用）
            refTrack = max(Pop.objs, [], 1) * 1.1;
            hvPrev = obj.calHV(Pop.objs, refTrack, M);
            hvHist5 = hvPrev;   % 5 代前的 HV

            polishFrom = round(0.9 * G);
            convergeCount = 0;
            convThreshold = 1e-3;

            for gen = 1 : G
                trialed = false;

                %% HV 验证的切换检查（第 50/60/70% 代）+ 收敛感知强制切换
                if strcmp(obj.mechanism, 'APD') && any(gen == round([0.5 0.6 0.7] * G))
                    ref = max(Pop.objs, [], 1) * 1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    % 创新 3：收敛感知——若连续 2 个检查点 HV 改进率 < 阈值，强制切换
                    if ha > hb || convergeCount >= 2
                        obj.mechanism = 'SMS';
                        obj.switchGen = gen;
                        Pop = Pt;
                        trialed = true;
                    else
                        convergeCount = 0;
                    end
                end

                %% 收敛感知监测（每 5 代更新一次 HV 速率）
                if mod(gen, 5) == 0 && gen > 5
                    refNow = max(Pop.objs, [], 1) * 1.1;
                    hvNow = obj.calHV(Pop.objs, refNow, M);
                    if hvNow > 0 && hvHist5 > 0
                        rate = (hvNow - hvHist5) / hvHist5;
                        obj.hvRate = rate;
                        if rate < convThreshold
                            convergeCount = convergeCount + 1;
                        else
                            convergeCount = 0;
                        end
                    end
                    hvHist5 = hvNow;
                end

                %% 主演化
                if ~trialed
                    if strcmp(obj.mechanism, 'APD')
                        Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                    else
                        Pop = obj.smsGeneration(Problem, Pop, N);
                    end
                    totalFE = totalFE + N;
                end

                %% 创新 2：末端多解 HV 引导搜索（最后 10% 每 5 代触发）
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [Pop, k] = obj.endSearch(Problem, Pop, M, D, refTrack);
                    totalFE = totalFE + k;
                end

                %% 更新参考点（只向理想方向移动，单调）
                refTrack = min(refTrack, max(Pop.objs, [], 1) * 1.1);

                igdHistory(gen) = IGD(Pop.objs, PFtrue);
                hvHistory(gen)  = obj.calHV(Pop.objs, refTrack, M);
            end

            %% 结果
            [fn, ~] = NDSort(Pop.objs, zeros(size(Pop.objs,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Pop.decs(nd,:), ...
                            'F',    Pop.objs(nd,:), ...
                            'nFE',  totalFE, ...
                            'V',    obj.V, ...
                            'mechanism', obj.mechanism, ...
                            'switchGen', obj.switchGen, ...
                            'igdHistory', igdHistory, ...
                            'hvHistory', hvHistory);
            Population.decs = Pop.decs;
            Population.objs = Pop.objs;
            Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== 机制 A：APD 向量选择（含创新 1 端点保护）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V;
            NV = size(V, 1);
            nCur = size(Pop.objs, 1);

            %% 产生 N 个子代
            mp = randi(nCur, 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);

            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);

            %% APD 计算
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            gamma = min(1 - pdist2(V, V, 'cosine'), [], 2);
            gamma = gamma(:);
            gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
            Angle = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));
            [dmin, assoc] = min(Angle, [], 2);
            APD = (1 + M * theta * dmin ./ gamma(assoc)) .* sqrt(sum(PopObj.^2, 2));

            %% 每向量保留 APD 最小解
            Keep = false(nAll, 1);
            for i = 1:NV
                cand = find(assoc == i);
                if ~isempty(cand)
                    [~, ii] = min(APD(cand));
                    Keep(cand(ii)) = true;
                end
            end

            %% 创新 1：端点保护
            [~, gOrd] = sort(gamma, 'descend');
            for e = 1:min(2, NV)
                vEnd = gOrd(e);
                if ~any(Keep & (assoc == vEnd))
                    cand = find(assoc == vEnd);
                    if ~isempty(cand)
                        [~, ii] = min(APD(cand));
                        Keep(cand(ii)) = true;
                    end
                end
            end

            %% 回填至 N
            idx = find(Keep);
            target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep);
                [~, ord] = sort(APD(rest));
                need = target - numel(idx);
                add = rest(ord(1 : min(need, numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx, :);
            Pop.objs = M1.objs(idx, :);
            Pop.cons = M1.cons(idx, :);
        end

        %% ===== 机制 B：SMS-EMOA 式增量超体积选择（忠实 HCEA）=====
        function Pop = smsGeneration(obj, Problem, Pop, N)
            M = Problem.nObj;
            for j = 1:N
                nCur = size(Pop.objs, 1);
                O1 = struct();
                O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur, 2), :));
                O1.objs = Problem.CalObj(O1.decs);
                O1.cons = Problem.CalCon(O1.decs);
                M1 = struct();
                M1.decs = [Pop.decs; O1.decs];
                M1.objs = [Pop.objs; O1.objs];
                M1.cons = [Pop.cons; O1.cons];

                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur+1, 0), inf);
                LastFront = find(FrontNo == max(FrontNo));
                nLast = numel(LastFront);
                deltaS = inf(1, nLast);
                PopObjLast = M1.objs(LastFront, :);
                if M == 2
                    [~, rank] = sortrows(PopObjLast);
                    for i = 2 : nLast - 1
                        deltaS(rank(i)) = (PopObjLast(rank(i+1),1) - PopObjLast(rank(i),1)) * ...
                                          (PopObjLast(rank(i-1),2) - PopObjLast(rank(i),2));
                    end
                else
                    deltaS = obj.calHVM(PopObjLast, max(M1.objs, [], 1) * 1.1, M);
                end
                [~, worst] = min(deltaS);
                delIdx = LastFront(worst);
                keep = 1 : nCur + 1;
                keep(delIdx) = [];
                Pop.decs = M1.decs(keep, :);
                Pop.objs = M1.objs(keep, :);
                Pop.cons = M1.cons(keep, :);
            end
        end

        %% ===== 创新 2：末端多解 HV 引导搜索 =====
        function [Pop, k] = endSearch(obj, Problem, Pop, M, D, ref)
            nPop = size(Pop.objs, 1);
            HVc = obj.hvContrib(Pop.objs, M, ref);
            nWorst = max(1, ceil(nPop / 10));
            [~, wi] = sort(HVc);
            wi = wi(1:nWorst);
            lb = Problem.lower; ub = Problem.upper;
            k = 0;
            for i = 1:numel(wi)
                base = Pop.decs(wi(i), :);
                % 定向扰动：向坐标原点方向小步搜索（决策空间中靠近边界）
                step = 0.02 * (ub - lb);
                candDir = base - step;
                candDir = min(max(candDir, lb), ub);
                % 随机扰动（忠实 HCEA）
                candRand = base + 0.05 * (ub - lb) .* randn(1, D);
                candRand = min(max(candRand, lb), ub);
                Cand = [candDir; candRand];
                CandObj = Problem.CalObj(Cand);
                bestHV = -inf; bestIdx = 1;
                for c = 1:2
                    Temp = Pop;
                    Temp.decs(wi(i), :) = Cand(c, :);
                    Temp.objs(wi(i), :) = CandObj(c, :);
                    h = obj.hvContrib(Temp.objs, M, ref);
                    if h(wi(i)) > bestHV
                        bestHV = h(wi(i)); bestIdx = c;
                    end
                end
                Pop.decs(wi(i), :) = Cand(bestIdx, :);
                Pop.objs(wi(i), :) = CandObj(bestIdx, :);
                k = k + 2;
            end
        end

        %% ===== 2D 精确超体积（参考点 ref）=====
        function hv = calHV(obj, PopObj, ref, M)
            if M ~= 2
                hv = sum(obj.calHVM(PopObj, ref, M));
                return;
            end
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            if isempty(PopObj)
                hv = 0; return;
            end
            PopObj = sortrows(PopObj, 1);
            x = [PopObj(:,1); ref(1)];
            hv = 0; ymin = ref(2);
            for i = 1:size(PopObj, 1)
                if PopObj(i,2) < ymin
                    ymin = PopObj(i,2);
                end
                hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
            end
        end

        %% ===== 2D 精确超体积贡献（末级前沿删除用）=====
        function HV = hvContrib(obj, PopObj, M, ref)
            [N, ~] = size(PopObj);
            HV = zeros(1, N);
            if M ~= 2
                HV = obj.calHVM(PopObj, ref, M);
                return;
            end
            if N == 0, return; end
            [S, ord] = sortrows(PopObj);
            f1 = [S(:,1); ref(1)];
            f2 = [ref(2); S(:,2)];
            for i = 1:N
                HV(ord(i)) = (f1(i+1) - f1(i)) * (f2(i) - f2(i+1));
            end
        end

        %% ===== 蒙特卡洛 HV 逐解贡献（M>=3，返回完整 N×1 向量，与输入顺序对齐）=====
        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000;
            k = 1;
            Norig = size(PopObj, 1);
            PopObj_orig = PopObj;
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            [N, ~] = size(PopObj);
            if N == 0
                F = zeros(1, Norig);
                return;
            end
            alpha = zeros(1, N);
            for i = 1 : min(k, N)
                alpha(i) = prod((k - [1:i-1]) ./ (N - [1:i-1])) ./ i;
            end
            Fmin = min(PopObj, [], 1);
            S = unifrnd(repmat(Fmin, nSample, 1), repmat(ref, nSample, 1));
            PdS = false(N, nSample);
            dS = zeros(1, nSample);
            for i = 1 : N
                x = sum(repmat(PopObj(i,:), nSample, 1) - S <= 0, 2) == M;
                PdS(i, x) = true;
                dS(x) = dS(x) + 1;
            end
            Fsub = zeros(1, N);
            for i = 1 : N
                Fsub(i) = sum(alpha(dS(PdS(i,:))));
            end
            Fsub = Fsub .* prod(ref - Fmin) / nSample;
            % 扩展回原始 Norig 长度（与输入顺序对齐；被 ref 过滤掉的为 0）
            F = zeros(1, Norig);
            keepMask = all(PopObj_orig <= ref, 2);
            F(keepMask) = Fsub;
        end

        %% 辅助：判断每个点是否全维度 <= ref
        function mask = PopObj_all_under_ref(PopObj, ref, M)
            mask = all(PopObj <= ref, 2);
        end
    end
end
