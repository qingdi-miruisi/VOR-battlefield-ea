classdef NSGA2 < ALGORITHM
% NSGA2 - 非支配排序遗传算法 II（忠实 PlatEMO NSGA-II，参考 Deb 2002）
% 参考：K. Deb, A. Pratap, S. Agarwal, T. Meyarivan. IEEE TEVC, 2002, 6(2): 182-197.

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;

            %% 初始化
            Population = Problem.Initialization(N);
            [Population, FrontNo, CrowdDis] = obj.environmentalSelection(Population, N);

            %% 主优化循环
            for gen = 1 : obj.maxGen
                MatingPool = TournamentSelection(2, N, FrontNo, -CrowdDis);
                Offspring  = obj.crossoverMutation(Problem, Population.decs(MatingPool, :));
                Merged.decs = [Population.decs; Offspring.decs];
                Merged.objs = [Population.objs; Offspring.objs];
                Merged.cons = [Population.cons; Offspring.cons];
                [Merged, FrontNo, CrowdDis] = obj.environmentalSelection(Merged, N);
                Population = Merged;
            end

            %% 提取最终非支配前沿
            nd = find(FrontNo == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'nFE',  N + obj.maxGen * N);
            Population.FrontNo = FrontNo(nd);
        end

        function [Population, FrontNo, CrowdDis] = environmentalSelection(obj, Population, N)
            % NSGA-II 环境选择（忠实 PlatEMO NSGA-II/EnvironmentalSelection.m）
            [FrontNo, MaxFNo] = NDSort(Population.objs, Population.cons, N);
            CrowdDis = CrowdingDistance(Population.objs, FrontNo);

            Next = FrontNo < MaxFNo;   % 保留所有非最后前沿
            Last = find(FrontNo == MaxFNo);
            if ~isempty(Last)
                [~, Rank] = sort(CrowdDis(Last), 'descend');
                nKeep = N - sum(Next);
                if nKeep > 0
                    Next(Last(Rank(1:nKeep))) = true;
                end
            end

            Population.decs = Population.decs(Next, :);
            Population.objs = Population.objs(Next, :);
            Population.cons = Population.cons(Next, :);
            FrontNo  = FrontNo(Next);
            CrowdDis = CrowdDis(Next);
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGA（每代 N 个子代，忠实 PlatEMO）
            Offspring.decs = OperatorGA(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
