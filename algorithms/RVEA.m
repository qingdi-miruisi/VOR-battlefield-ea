classdef RVEA < ALGORITHM
% RVEA - 参考向量引导进化算法（忠实 PlatEMO RVEA，Cheng et al. 2016）
% 参考：R. Cheng, Y. Jin, M. Olhofer, B. Sendhoff. IEEE TEVC, 2016, 20(5): 773-791.

    properties
        V0;
        V;
        alpha;
        fr;
    end

    methods
        function obj = RVEA(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2;
            obj.fr = 0.1;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;
            M = Problem.nObj;

            [obj.V0, nRef] = UniformPoint(N, M, 'NBI');
            obj.V = obj.V0;

            Population = Problem.Initialization(nRef);

            totalFE = obj.maxGen * nRef;
            for gen = 1 : obj.maxGen
                MatingPool = randi(size(Population.decs, 1), 1, N);
                Offspring  = obj.crossoverMutation(Problem, Population.decs(MatingPool, :));
                Merged.decs = [Population.decs; Offspring.decs];
                Merged.objs = [Population.objs; Offspring.objs];
                Merged.cons = [Population.cons; Offspring.cons];

                % 计算 theta = (FE/maxFE)^alpha
                FE = gen * N;
                theta = (min(FE, totalFE) / totalFE)^obj.alpha;
                Population = obj.environmentalSelection(Merged, obj.V, theta, M);

                % 参考向量自适应
                if ~mod(ceil(FE / nRef), max(1, ceil(obj.fr * totalFE / nRef)))
                    obj.V(1:nRef,:) = obj.V0 .* ...
                        repmat(max(Population.objs,[],1)-min(Population.objs,[],1), nRef, 1);
                end
            end

            [fn, ~] = NDSort(Population.objs, zeros(size(Population,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'RefVectors', obj.V, ...
                            'nFE',  nRef + obj.maxGen * nRef);
            Population.FrontNo = fn(nd);
        end

        function Population = environmentalSelection(obj, Pop, V, theta, M)
            % 忠实 PlatEMO RVEA/EnvironmentalSelection.m
            PopObj = Pop.objs;
            N = size(PopObj, 1);
            NV = size(V, 1);

            %% 平移种群
            PopObj = PopObj - repmat(min(PopObj, [], 1), N, 1);

            %% 计算约束违反度
            CV = sum(max(0, Pop.cons), 2);

            %% 计算参考向量间最小角度
            cosine = 1 - pdist2(V, V, 'cosine');
            cosine(logical(eye(NV))) = 0;
            gamma = min(acos(cosine), [], 2);

            %% 关联每个解到参考向量
            Angle = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));
            [~, associate] = min(Angle, [], 2);

            %% 每个参考向量选 1 个解
            Next = zeros(1, NV);
            for i = 1:NV
                current1 = find(associate == i & CV == 0);
                current2 = find(associate == i & CV ~= 0);
                if ~isempty(current1)
                    % APD = (1 + M*theta*Angle/gamma) * sqrt(sum(PopObj^2,2))
                    APD = (1 + M * theta * Angle(current1, i) / gamma(i)) .* ...
                          sqrt(sum(PopObj(current1, :).^2, 2));
                    [~, best] = min(APD);
                    Next(i) = current1(best);
                elseif ~isempty(current2)
                    [~, best] = min(CV(current2));
                    Next(i) = current2(best);
                end
            end
            % 严格 PlatEMO 原版：Population = Population(Next(Next~=0))，无补齐逻辑
            Population.decs = Pop.decs(Next(Next~=0), :);
            Population.objs = Pop.objs(Next(Next~=0), :);
            Population.cons = Pop.cons(Next(Next~=0), :);
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGA（忠实 PlatEMO）
            Offspring.decs = OperatorGA(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
