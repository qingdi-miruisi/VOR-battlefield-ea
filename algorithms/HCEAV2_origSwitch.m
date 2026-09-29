classdef HCEAV2_origSwitch < HCEAV2
% HCEAV2_origSwitch - 消融变体：使用 HCEA 原始 3 检查点切换（创新 3 移除）
% 其余机制（端点保护 APD + 末端多解搜索）与 HCEAV2 完全相同。
% 用于证明收敛感知切换（4 检查点）对晚收敛问题的贡献。

    methods
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            N  = obj.popSize;
            M  = Problem.nObj;
            G  = obj.maxGen;
            D  = Problem.nVar;

            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            totalFE = N;

            PFtrue = Problem.ParetoFront(500);
            igdHistory = zeros(1, G);
            hvHistory  = zeros(1, G);
            ref = max(Pop.objs, [], 1) * 1.1;

            % 收敛感知监测
            hvHist5 = obj.calHV(Pop.objs, ref, M);
            convergeCount = 0;
            convThreshold = 1e-3;

            for gen = 1 : G
                trialed = false;

                % 原始 HCEA 3 检查点（50/60/70%）+ 收敛感知强制切换
                if strcmp(obj.mechanism, 'APD') && any(gen == round([0.5 0.6 0.7] * G))
                    refT = max(Pop.objs, [], 1) * 1.1;
                    hb = obj.calHV(Pop.objs, refT, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, refT, M);
                    if ha > hb || convergeCount >= 2
                        obj.mechanism = 'SMS';
                        obj.switchGen = gen;
                        Pop = Pt;
                        trialed = true;
                    else
                        convergeCount = 0;
                    end
                end

                % 收敛感知监测（每 5 代）
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

                if ~trialed
                    if strcmp(obj.mechanism, 'APD')
                        Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^2);
                    else
                        Pop = obj.smsGeneration(Problem, Pop, N);
                    end
                    totalFE = totalFE + N;
                end

                ref = min(ref, max(Pop.objs, [], 1) * 1.1);

                % 末端多解搜索（与创新 2 相同）
                polishFrom = round(0.9 * G);
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [Pop, k] = obj.endSearch(Problem, Pop, M, D, ref);
                    totalFE = totalFE + k;
                end

                hvHistory(gen) = obj.calHV(Pop.objs, ref, M);
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end

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
    end
end
