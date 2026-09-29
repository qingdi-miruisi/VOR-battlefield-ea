classdef HCEA_D3 < ALGORITHM
% HCEA_D3 - HCEA 消融变体（ablation variant）
% 只改动一处，其余逻辑与 algorithms/HCEA.m 完全一致。
% 改动：切换策略：全程 APD 不切换（无 HV 验证、无机制 B）
%
% 接口与 HCEA 一致：obj = HCEA_D3(popSize, maxGen, seed);
%   [Population, Result] = obj.optimize(Problem);
    properties
        V;         % 静态参考向量 [nRef x M]
        alpha;     % APD theta 退火指数（默认 2，同 RVEA）
        mechanism; % 最终采用的机制：'APD' 或 'SMS'
        switchGen; % 实际切换代数（未切换则为 maxGen）
    end

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            N  = obj.popSize;
            M  = Problem.nObj;
            G  = obj.maxGen;
            obj.alpha = 2;

            %% 初始化
            [obj.V, nRef] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            polishFrom = round(0.9 * G);
            totalFE = N;          % 初始种群评估数
            obj.mechanism = 'APD';
            obj.switchGen = G;

            %% 收敛过程记录（仅记录，不参与选择）
            PFtrue = Problem.ParetoFront(500);
            igdHistory = zeros(1, G);

            for gen = 1 : G
                %% 消融 D3：全程 APD，不切换
                Pop = obj.apdGeneration(Problem, Pop, N, M, (gen / G)^obj.alpha);
                totalFE = totalFE + N;

                %% 末端超体积抛光
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [Pop, k] = obj.polishHV(Pop, Problem);
                    totalFE = totalFE + k;
                end

                igdHistory(gen) = IGD(Pop.objs, PFtrue);
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
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs;
            Population.objs = Pop.objs;
            Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== 机制 A：APD 向量选择（含恒种群回填）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V;
            mp = randi(size(Pop.objs,1), 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            NV = size(V, 1);

            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
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
                add = rest(ord(1 : min(need, numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx, :);
            Pop.objs = M1.objs(idx, :);
            Pop.cons = M1.cons(idx, :);
        end

        %% ===== 机制 B：SMS-EMOA 式增量超体积选择（一代 = N 次并入-删除）=====
        function Pop = smsGeneration(obj, Problem, Pop, N)
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
                [~, rank] = sortrows(PopObjLast);
                for i = 2 : nLast - 1
                    deltaS(rank(i)) = (PopObjLast(rank(i+1),1) - PopObjLast(rank(i),1)) * ...
                                      (PopObjLast(rank(i-1),2) - PopObjLast(rank(i),2));
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

        %% ===== 2D 精确超体积（参考点 ref）=====
        function hv = calHV(obj, PopObj, ref, M)
            % 标准 2D 最小化 HV：按 f1 升序切分区间 [f1(i), f1(i+1)]，
            % 每段高度 = ref(2) - 该段起点的最小 f2（运行最小值）。
            % 验证例：(0.1,0.9),(0.5,0.5),(0.9,0.1), ref=(1,1) -> 0.33
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
            % SMS-EMOA 标准 2D 贡献公式（与 smsGeneration 的 deltaS 完全一致）：
            %   deltaS(i) = (f1(i+1)-f1(i)) * (f2(i-1)-f2(i))
            % 端点用调用者传入的参考点 ref 代替 inf：
            %   首点: (f1(2)-f1(1))*(ref(2)-f1...即 f2(0)=ref(2)
            %   末点: (ref(1)-f1(N))*(f2(N-1)-f2(N))
            [N, ~] = size(PopObj);
            HV = zeros(1, N);
            if M ~= 2
                HV = -sqrt(sum(PopObj.^2, 2));
                return;
            end
            [S, ord] = sortrows(PopObj);
            f1 = [S(:,1); ref(1)];
            f2 = [ref(2); S(:,2)];
            for i = 1:N
                HV(ord(i)) = (f1(i+1) - f1(i)) * (f2(i) - f2(i+1));
            end
        end

        %% ===== 末端 HV 抛光 =====
        function [Pop, k] = polishHV(obj, Pop, Problem)
            M = Problem.nObj;
            ref = max(Pop.objs, [], 1) * 1.1;   % 与切换试验一致的参考点
            HVc = obj.hvContrib(Pop.objs, M, ref);
            [~, worst] = min(HVc);
            base = Pop.decs(worst, :);
            D = size(base, 2);
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
            k = 3;
        end
    end
end
