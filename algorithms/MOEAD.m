classdef MOEAD < ALGORITHM
% MOEAD - 基于分解的多目标进化算法（忠实 PlatEMO MOEA-D，Zhang & Li 2007）
% 参考：Q. Zhang, H. Li. IEEE TEVC, 2007, 11(6): 712-731.
% type=1 (PBI)；T = ceil(N/10)；每代每个子问题用前 2 个父代产生 1 个子代

    properties
        weights;
        nRef;
        T;
        B;
        type;
    end

    methods
        function obj = MOEAD(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.type = 1;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;
            M = Problem.M;

            [obj.weights, obj.nRef] = UniformPoint(N, M, 'NBI');
            obj.T = ceil(obj.nRef / 10);
            dist = pdist2(obj.weights, obj.weights);
            [~, Bidx] = sort(dist, 2);
            obj.B = Bidx(:, 1:obj.T);

            Population = Problem.Initialization(obj.nRef);
            Z = min(Population.objs, [], 1);

            for gen = 1 : obj.maxGen
                for i = 1 : obj.nRef
                    % 忠实 PlatEMO：P = B(i, randperm(T))，仅用前 2 个父代产生 1 个子代
                    P = obj.B(i, randperm(obj.T));
                    Offspring = obj.crossoverMutation(Problem, Population.decs(P(1:2), :));
                    % 更新理想点
                    Z = min([Z; Offspring.objs], [], 1);
                    % PBI 聚合（忠实 PlatEMO 向量化公式）
                    T = obj.T;
                    normW = sqrt(sum(obj.weights(P, :).^2, 2));
                    PopObjsP = Population.objs(P, :);
                    diffP = PopObjsP - repmat(Z, T, 1);
                    normP = sqrt(sum(diffP.^2, 2));
                    normO = sqrt(sum((Offspring.objs - Z).^2, 2));
                    normO = max(normO, 1e-14);
                    normP = max(normP, 1e-14);
                    normW = max(normW, 1e-14);
                    CosineP = sum(diffP .* obj.weights(P, :), 2) ./ normW ./ normP;
                    diffO = Offspring.objs - Z;
                    CosineO = sum(repmat(diffO, T, 1) .* obj.weights(P, :), 2) ./ normW ./ normO;
                    g_old = normP .* CosineP + 5 * normP .* sqrt(1 - CosineP.^2);
                    g_new = normO .* CosineO + 5 * normO .* sqrt(1 - CosineO.^2);
                    % 替换所有满足 g_new <= g_old 的邻居（忠实 PlatEMO）
                    mask = g_old >= g_new;
                    if any(mask)
                        idx = P(mask);
                        Population.decs(idx, :) = repmat(Offspring.decs, sum(mask), 1);
                        Population.objs(idx, :) = repmat(Offspring.objs, sum(mask), 1);
                        Population.cons(idx, :) = repmat(Offspring.cons, sum(mask), 1);
                    end
                end
            end

            [fn, ~] = NDSort(Population.objs, zeros(size(Population,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'Weights', obj.weights, ...
                            'nFE',  obj.nRef + obj.maxGen * obj.nRef);
            Population.FrontNo = fn(nd);
        end

function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGAhalf（忠实 PlatEMO：2 个父代 → 1 个子代）
            Offspring.decs = OperatorGAhalf(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
