classdef SMSEMOA < ALGORITHM
% SMSEMOA - S 度量选择进化多目标优化算法（忠实 PlatEMO SMS-EMOA）
% 参考：M. Emmerich, N. Beume, B. Naujoks. EMO 2005, 62-76.
%       N. Beume, B. Naujoks, M. Emmerich. EJOR 2009, 165-176.
% 每代产生 N 个子代（每个子代由随机 2 个父代产生），删除超体积贡献最小的 1 个

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;

            Population = Problem.Initialization(N);
            FrontNo = NDSort(Population.objs, Population.cons, inf);

            for gen = 1 : obj.maxGen
                for i = 1 : N
                    Offspring = obj.crossoverMutation(Problem, Population.decs(randperm(N, 2), :));
                    Merged.decs = [Population.decs; Offspring.decs];
                    Merged.objs = [Population.objs; Offspring.objs];
                    Merged.cons = [Population.cons; Offspring.cons];
                    [Merged, FrontNo] = obj.reduce(Merged, FrontNo);
                    Population = Merged;
                end
            end

            [fn, ~] = NDSort(Population.objs, zeros(size(Population,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'nFE',  N + obj.maxGen * N);
            Population.FrontNo = fn(nd);
        end

        function [Population, FrontNo] = reduce(obj, Population, FrontNo)
            % 忠实 PlatEMO SMS-EMOA/Reduce.m + UpdateFront.m
            PopObj = Population.objs;
            [Ntot, M] = size(PopObj);

            % 更新前沿编号（新加入的 Offspring 在末尾）
            FrontNo = obj.updateFront(PopObj, FrontNo);
            LastFront = find(FrontNo == max(FrontNo));

            % 超体积贡献
            deltaS = inf(1, numel(LastFront));
            PopObjLast = PopObj(LastFront, :);
            nLast = numel(LastFront);
            refPoint = max(PopObj, [], 1) * 1.1;

            if M == 2
                % 2D 精确（忠实 PlatEMO Reduce.m）
                [~, rank] = sortrows(PopObjLast);
                for i = 2 : nLast - 1
                    deltaS(rank(i)) = (PopObjLast(rank(i+1),1) - PopObjLast(rank(i),1)) * ...
                                      (PopObjLast(rank(i-1),2) - PopObjLast(rank(i),2));
                end
            else
                % M>=3: CalHV 近似
                deltaS = obj.calHV(PopObjLast, refPoint, 1, 1000);
            end

            [~, worst] = min(deltaS);
            delIdx = LastFront(worst);

            % 删除
            FrontNo = obj.updateFront(PopObj, FrontNo, delIdx);
            keep = 1 : Ntot;
            keep(delIdx) = [];
            Population.decs = Population.decs(keep, :);
            Population.objs = PopObj(keep, :);
            Population.cons = Population.cons(keep, :);
        end

        function FrontNo = updateFront(obj, PopObj, FrontNo, delIdx)
            % 忠实 PlatEMO SMS-EMOA/UpdateFront.m
            if nargin < 4 || isempty(delIdx)
                % 添加新解（在末尾）
                [N, M] = size(PopObj);
                FrontNo = [FrontNo, 0];
                Move = false(1, N);
                Move(N) = true;
                CurrentF = 1;
                % 定位新解的前编号
                while true
                    Dominated = false;
                    for i = 1 : N-1
                        if FrontNo(i) == CurrentF
                            m = 1;
                            while m <= M && PopObj(i, m) <= PopObj(end, m)
                                m = m + 1;
                            end
                            Dominated = m > M;
                            if Dominated
                                break;
                            end
                        end
                    end
                    if ~Dominated
                        break;
                    else
                        CurrentF = CurrentF + 1;
                    end
                end
                % 逐前沿移动被支配的解
                while any(Move)
                    NextMove = false(1, N);
                    for i = 1 : N
                        if FrontNo(i) == CurrentF
                            Dominated = false;
                            for j = 1 : N
                                if Move(j)
                                    m = 1;
                                    while m <= M && PopObj(j, m) <= PopObj(i, m)
                                        m = m + 1;
                                    end
                                    Dominated = m > M;
                                    if Dominated
                                        break;
                                    end
                                end
                            end
                            NextMove(i) = Dominated;
                        end
                    end
                    FrontNo(Move) = CurrentF;
                    CurrentF = CurrentF + 1;
                    Move = NextMove;
                end
            else
                % 删除第 delIdx 个解
                [N, M] = size(PopObj);
                Move = false(1, N);
                Move(delIdx) = true;
                CurrentF = FrontNo(delIdx) + 1;
                while any(Move)
                    NextMove = false(1, N);
                    for i = 1 : N
                        if FrontNo(i) == CurrentF
                            Dominated = false;
                            for j = 1 : N
                                if Move(j)
                                    m = 1;
                                    while m <= M && PopObj(j, m) <= PopObj(i, m)
                                        m = m + 1;
                                    end
                                    Dominated = m > M;
                                    if Dominated
                                        break;
                                    end
                                end
                            end
                            NextMove(i) = Dominated;
                        end
                    end
                    for i = 1 : N
                        if NextMove(i)
                            Dominated = false;
                            for j = 1 : N
                                if FrontNo(j) == CurrentF - 1 && ~Move(j)
                                    m = 1;
                                    while m <= M && PopObj(j, m) <= PopObj(i, m)
                                        m = m + 1;
                                    end
                                    Dominated = m > M;
                                    if Dominated
                                        break;
                                    end
                                end
                            end
                            NextMove(i) = ~Dominated;
                        end
                    end
                    FrontNo(Move) = CurrentF - 2;
                    CurrentF = CurrentF + 1;
                    Move = NextMove;
                end
                FrontNo(delIdx) = [];
            end
        end

        function F = calHV(obj, points, bounds, k, nSample)
            % 忠实 PlatEMO CalHV.m（HYPE 采样）
            [N, M] = size(points);
            if M > 2
                alpha = zeros(1, N);
                for i = 1 : min(k, N)
                    alpha(i) = prod((k - [1:i-1]) ./ (N - [1:i-1])) ./ i;
                end
                Fmin = min(points, [], 1);
                S = unifrnd(repmat(Fmin, nSample, 1), repmat(bounds, nSample, 1));
                PdS = false(N, nSample);
                dS = zeros(1, nSample);
                for i = 1 : N
                    x = sum(repmat(points(i,:), nSample, 1) - S <= 0, 2) == M;
                    PdS(i, x) = true;
                    dS(x) = dS(x) + 1;
                end
                F = zeros(1, N);
                for i = 1 : N
                    F(i) = sum(alpha(dS(PdS(i,:))));
                end
                F = F .* prod(bounds - Fmin) / nSample;
            else
                % 2D 精确递归（hypesub）
                pvec = 1 : N;
                alpha = zeros(1, min(k, N));
                for i = 1 : min(k, N)
                    j = 1 : i-1;
                    alpha(i) = prod((k - j) ./ (N - j)) ./ i;
                end
                F = obj.hypesub(N, points, M, bounds, pvec, alpha, min(k, N));
            end
        end

        function h = hypesub(obj, l, A, M, bounds, pvec, alpha, k)
            h = zeros(1, l);
            [S, i] = sortrows(A, M);
            pvec = pvec(i);
            for i = 1 : size(S, 1)
                if i < size(S, 1)
                    extrusion = S(i+1, M) - S(i, M);
                else
                    extrusion = bounds(M) - S(i, M);
                end
                if M == 1
                    if i > k
                        break;
                    end
                    if alpha >= 0
                        h(pvec(1:i)) = h(pvec(1:i)) + extrusion * alpha(i);
                    end
                elseif extrusion > 0
                    h = h + extrusion * obj.hypesub(l, S(1:i,:), M-1, bounds, pvec(1:i), alpha, k);
                end
            end
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            Offspring.decs = OperatorGAhalf(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
