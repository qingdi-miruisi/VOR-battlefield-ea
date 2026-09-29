classdef SPEA2 < ALGORITHM
% SPEA2 - 强度帕累托进化算法 2（忠实 PlatEMO SPEA2，Zitzler, Laumanns, Thiele 2001）
% 参考：E. Zitzler, M. Laumanns, L. Thiele. EMO 2001, 95-100.

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;

            Population = Problem.Initialization(N);
            Fitness = obj.calFitness(Population.objs);

            for gen = 1 : obj.maxGen
                MatingPool = TournamentSelection(2, N, Fitness);
                Offspring  = obj.crossoverMutation(Problem, Population.decs(MatingPool, :));
                Merged.decs = [Population.decs; Offspring.decs];
                Merged.objs = [Population.objs; Offspring.objs];
                Merged.cons = [Population.cons; Offspring.cons];
                [Merged, Fitness] = obj.environmentalSelection(Merged, N);
                Population = Merged;
            end

            [fn, ~] = NDSort(Population.objs, Population.cons, 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'nFE',  N + obj.maxGen * N);
            Population.FrontNo = fn(nd);
        end

        function Fitness = calFitness(obj, PopObj)
            % 忠实 PlatEMO SPEA2/CalFitness.m
            N = size(PopObj, 1);

            %% 支配关系检测
            Dominate = false(N);
            for i = 1:N-1
                for j = i+1:N
                    k = any(PopObj(i,:) < PopObj(j,:)) - any(PopObj(i,:) > PopObj(j,:));
                    if k == 1
                        Dominate(i, j) = true;
                    elseif k == -1
                        Dominate(j, i) = true;
                    end
                end
            end

            %% 计算 S(i)
            S = sum(Dominate, 2);

            %% 计算 R(i)
            R = zeros(1, N);
            for i = 1:N
                R(i) = sum(S(Dominate(:, i)));
            end

            %% 计算 D(i)（忠实 PlatEMO：D = 1./(Distance(:,floor(sqrt(N)))+2)）
            Distance = pdist2(PopObj, PopObj);
            Distance(logical(eye(N))) = inf;
            Distance = sort(Distance, 2);
            D = 1 ./ (Distance(:, floor(sqrt(N))) + 2);

            Fitness = R + D';
        end

        function [Population, Fitness] = environmentalSelection(obj, Pop, N)
            % 忠实 PlatEMO SPEA2/EnvironmentalSelection.m
            Fitness = obj.calFitness(Pop.objs);
            Next = Fitness < 1;
            if sum(Next) < N
                [~, Rank] = sort(Fitness);
                Next2 = false(1, numel(Fitness));
                Next2(Rank(1:min(N, numel(Rank)))) = true;
                Next = Next2;
            elseif sum(Next) > N
                Del = truncationByPop(Pop.objs(Next,:), sum(Next) - N);
                Temp = find(Next);
                Next(Temp(Del)) = false;
            end
            Population.decs = Pop.decs(Next, :);
            Population.objs = Pop.objs(Next, :);
            Population.cons = Pop.cons(Next, :);
            Fitness = Fitness(Next);
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGA（忠实 PlatEMO）
            Offspring.decs = OperatorGA(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
