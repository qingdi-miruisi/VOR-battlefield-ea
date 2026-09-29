classdef NSGA3 < ALGORITHM
% NSGA3 - 基于参考点的非支配排序遗传算法 III（忠实 PlatEMO NSGA-III，Deb & Jain 2014）
% 参考：K. Deb, H. Jain. IEEE TEVC, 2014, 18(4): 577-601.

    properties
        refPoints;
        nRef;
    end

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            N = obj.popSize;
            M = Problem.nObj;

            [obj.refPoints, obj.nRef] = UniformPoint(N, M, 'NBI');

            Population = Problem.Initialization(obj.nRef);
            Zmin = min(Population.objs, [], 1);

            for gen = 1 : obj.maxGen
                % 忠实 PlatEMO：锦标赛选择，适应度 = 违反约束数之和
                MatingPool = TournamentSelection(2, obj.nRef, sum(max(0, Population.cons), 2));
                Offspring  = obj.crossoverMutation(Problem, Population.decs(MatingPool, :));
                % 忠实 PlatEMO：Zmin 只更新可行解
                Zmin = min([Zmin; Offspring.objs(sum(max(0, Offspring.cons), 2) == 0, :)], [], 1);
                Merged.decs = [Population.decs; Offspring.decs];
                Merged.objs = [Population.objs; Offspring.objs];
                Merged.cons = [Population.cons; Offspring.cons];
                Population = obj.lastSelection(Merged, obj.refPoints, Zmin);
            end

            [fn, ~] = NDSort(Population.objs, zeros(size(Population,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Population.decs(nd,:), ...
                            'F',    Population.objs(nd,:), ...
                            'RefPoints', obj.refPoints, ...
                            'nFE',  obj.nRef + obj.maxGen * obj.nRef);
            Population.FrontNo = fn(nd);
        end

        function Population = lastSelection(obj, Pop, Z, Zmin)
            % 忠实 PlatEMO NSGA-III/EnvironmentalSelection.m
            PopObj = Pop.objs;
            [Ntot, M] = size(PopObj);
            N = obj.popSize;
            NZ = size(Z,1);

            %% 非支配排序
            [fn, MaxFNo] = NDSort(PopObj, Pop.cons, N);
            Next = fn < MaxFNo;

            %% 最后前沿小生境选择
            Last = find(fn == MaxFNo);
            if ~isempty(Last)
                nKeep = N - sum(Next);
                if nKeep > 0
                    % 归一化（忠实 PlatEMO）
                    PopObjN = PopObj - repmat(Zmin, Ntot, 1);
                    % 检测极值点
                    Extreme = zeros(1, M);
                    w = zeros(1, M) + 1e-6 + eye(M);
                    for i = 1:M
                        [val, Extreme(i)] = min(max(PopObjN ./ repmat(w(i,:), Ntot, 1), [], 2));
                    end
                    % 超平面截距
                    Hyperplane = PopObjN(Extreme,:) \ ones(M, 1);
                    a = 1 ./ Hyperplane;
                    if any(isnan(a)) || any(isinf(a)) || any(a <= 0)
                        a = max(PopObjN, [], 1)';
                    end
                    PopObjN = PopObjN ./ repmat(a', Ntot, 1);

                    %% 关联参考点（余弦距离）
                    Cosine   = 1 - pdist2(PopObjN, Z, 'cosine');
                    Distance = repmat(sqrt(sum(PopObjN.^2, 2)), 1, NZ) .* sqrt(max(0, 1 - Cosine.^2));
                    [d, pi] = min(Distance', [], 1);

                    %% 非最后前沿各参考点的关联数
                    rho = hist(pi(1:Ntot-numel(Last)), 1:NZ);

                    %% 逐个选取
                    Choose = false(1, numel(Last));
                    Zchoose = true(1, NZ);
                    while sum(Choose) < nKeep
                        Temp = find(Zchoose);
                        if isempty(Temp)
                            break;
                        end
                        Jmin = find(rho(Temp) == min(rho(Temp)));
                        j = Temp(Jmin(randi(numel(Jmin))));
                        I = find(~Choose & pi(Ntot-numel(Last)+1:end) == j);
                        if ~isempty(I)
                            if rho(j) == 0
                                [~, s] = min(d(Ntot-numel(Last)+I));
                            else
                                s = randi(numel(I));
                            end
                            Choose(I(s)) = true;
                            rho(j) = rho(j) + 1;
                        else
                            Zchoose(j) = false;
                        end
                    end
                    Next(Last(Choose)) = true;
                end
            end

            Population.decs = Pop.decs(Next, :);
            Population.objs = Pop.objs(Next, :);
            Population.cons = Pop.cons(Next, :);
        end

        function Offspring = crossoverMutation(obj, Problem, ParentDecs)
            % 使用 OperatorGA（忠实 PlatEMO）
            Offspring.decs = OperatorGA(Problem, ParentDecs);
            Offspring.objs = Problem.F(Offspring.decs);
            Offspring.cons = Problem.Cons(Offspring.decs);
        end
    end
end
