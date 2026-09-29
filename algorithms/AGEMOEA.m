classdef AGEMOEA < ALGORITHM
% AGEMOEA - 基于自适应几何估计的多目标/超多目标进化算法
% （忠实 PlatEMO AGE-MOEA，原作者 Annibale Panichella 2019）
% 参考：A. Panichella. GECCO 2019, 595-603.

    properties
        p;
        normalization;
    end

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;

            Population = Problem.Initialization(N);
            [Population, FrontNo, CrowdDis] = obj.environmentalSelection(Population, N);

            for gen = 1 : obj.maxGen
                MatingPool = TournamentSelection(2, N, FrontNo, -CrowdDis);
                Offspring  = obj.crossoverMutation(Problem, Population.decs(MatingPool, :));
                Merged.decs = [Population.decs; Offspring.decs];
                Merged.objs = [Population.objs; Offspring.objs];
                Merged.cons = [Population.cons; Offspring.cons];
                [Merged, FrontNo, CrowdDis] = obj.environmentalSelection(Merged, N);
                Population = Merged;
            end

            [fn, ~] = NDSort(Population.objs, zeros(size(Population,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'p',    obj.p, ...
                            'nFE',  N + obj.maxGen * N);
            Population.FrontNo = fn(nd);
        end

        function [Population, FrontNo, CrowdDis] = environmentalSelection(obj, Pop, N)
            % 忠实 PlatEMO AGE-MOEA/EnvironmentalSelection.m
            objs = round(Pop.objs, 6);

            %% 非支配排序（使用 Pop.cons，忠实 PlatEMO）
            [FrontNo, MaxFNo] = NDSort(objs, Pop.cons, N);
            Next = FrontNo < MaxFNo;

            [nInd, ~] = size(objs);
            CrowdDis = zeros(1, nInd);

            %% 计算各前沿的适应度距离
            front1 = objs(FrontNo == 1, :);
            if size(front1, 1) > 1
                IdealPoint = min(front1);
            else
                IdealPoint = front1;
            end

            [CrowdDis(FrontNo == 1), obj.p, obj.normalization] = obj.survivalScore(front1, IdealPoint);

            for i = 2 : MaxFNo
                front = objs(FrontNo == i, :);
                m = size(front, 1);
                front = front ./ repmat(obj.normalization', m, 1);
                CrowdDis(FrontNo == i) = 1 ./ pdist2(front, IdealPoint, 'minkowski', obj.p);
            end

            %% 最后前沿按适应度距离排序
            Last = find(FrontNo == MaxFNo);
            if ~isempty(Last)
                [~, Rank] = sort(CrowdDis(Last), 'descend');
                nKeep = N - sum(Next);
                if nKeep > 0
                    Next(Last(Rank(1:nKeep))) = true;
                end
            end

            Population.decs = Pop.decs(Next, :);
            Population.objs = Pop.objs(Next, :);
            Population.cons = Pop.cons(Next, :);
            FrontNo  = FrontNo(Next);
            CrowdDis = CrowdDis(Next);
        end

        function [CrowdDis, p, normalization] = survivalScore(obj, front, IdealPoint)
            % 生存分数（忠实 PlatEMO AGE-MOEA/SurvivalScore.m）
            [m, n] = size(front);
            CrowdDis = zeros(1, m);
            if m < n
                p = 1;
                normalization = max(front, [], 1)';
                obj.p = p;
                return;
            end

            front = front - IdealPoint;
            Extreme = obj.findCornerSolutions(front);
            [front, normalization] = obj.normalize(front, Extreme);

            CrowdDis(Extreme) = Inf;
            selected = false(1, m);
            selected(Extreme) = true;

            d = obj.point2lineDistance(front, zeros(1, n), ones(1, n));
            d(Extreme) = Inf;
            [~, index] = min(d);
            p = log(n) / log(1 / mean(front(index, :)));
            if isnan(p) || p <= 0.1
                p = 1;
            end
            obj.p = p;

            nn = vecnorm(front, p, 2);
            distances = pdist2(front, front, 'minkowski', p);
            distances = distances ./ repmat(nn, 1, m);

            neighbors = 2;
            remaining = 1:m;
            remaining = remaining(~selected);
            for i = 1:m - sum(selected) - 1
                if isempty(remaining)
                    break;
                end
                maxim = obj.mink(distances(remaining, selected), neighbors, 2);
                if isempty(maxim)
                    break;
                end
                [d, index] = max(sum(maxim, 2));
                best = remaining(index);
                remaining(index) = [];
                selected(best) = true;
                CrowdDis(1, best) = d;
            end
        end

        function indexes = findCornerSolutions(obj, front)
            [m, n] = size(front);
            if m <= n
                indexes = 1:m;
                return;
            end
            W = zeros(n) + 1e-6 + eye(n);
            r = size(W, 1);
            indexes = zeros(1, r);
            for i = 1:r
                [~, index] = min(obj.point2lineDistance(front, zeros(1, n), W(i, :)));
                indexes(i) = index;
            end
        end

        function [front, normalization] = normalize(obj, front, Extreme)
            [m, n] = size(front);
            if (length(Extreme) ~= length(unique(Extreme)))
                normalization = max(front, [], 1)';
                front = front ./ repmat(normalization', m, 1);
                return;
            end
            Hyperplane = front(Extreme, :) \ ones(n, 1);
            if any(isnan(Hyperplane)) || any(isinf(Hyperplane)) || any(Hyperplane < 0)
                normalization = max(front, [], 1)';
            else
                normalization = 1 ./ Hyperplane;
                if any(isnan(normalization)) || any(isinf(normalization))
                    normalization = max(front, [], 1)';
                end
            end
            front = front ./ repmat(normalization', m, 1);
        end

        function d = point2lineDistance(obj, P, A, B)
            d = zeros(size(P, 1), 1);
            for i = 1:size(P, 1)
                pa = P(i, :) - A;
                ba = B - A;
                t = dot(pa, ba) / dot(ba, ba);
                d(i, 1) = norm(pa - t * ba, 2);
            end
        end

        function d = mink(obj, D, k, dim)
            % k 最小和（忠实 PlatEMO AGE-MOEA/mink.m）
            if nargin < 4
                dim = 1;
            end
            [N, M] = size(D);
            d = zeros(1, N);
            if k <= 0
                return;
            end
            for i = 1:N
                S = sort(D(i, :));
                if k >= M
                    d(i) = sum(S);
                else
                    d(i) = sum(S(1:k));
                end
            end
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGA（忠实 PlatEMO）
            Offspring.decs = OperatorGA(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
