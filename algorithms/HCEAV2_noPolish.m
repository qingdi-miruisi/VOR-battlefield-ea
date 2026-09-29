classdef HCEAV2_noPolish < HCEAV2
% HCEAV2_noPolish - 消融变体：关闭末端多解搜索（创新 2 移除）
% 其余机制（端点保护 APD + 收敛感知切换）与 HCEAV2 完全相同。
% 用于证明末端多解搜索对 IGD/HV 的贡献。

    methods
        function [Population, Result] = run(obj, Problem)
            % 复制 HCEAV2.run 但跳过 polishHV 调用
            rng(obj.seed);
            w0 = warning('off', 'all');
            N  = obj.popSize;
            M  = Problem.nObj;
            G  = obj.maxGen;

            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            totalFE = N;

            PFtrue = Problem.ParetoFront(500);
            igdHistory = zeros(1, G);
            hvHistory  = zeros(1, G);
            ref = max(Pop.objs, [], 1) * 1.1;

            for gen = 1 : G
                trialed = false;
                if strcmp(obj.mechanism, 'APD') && any(gen == round([0.5 0.6 0.7] * G))
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb
                        obj.mechanism = 'SMS';
                        obj.switchGen = gen;
                        Pop = Pt;
                        trialed = true;
                    end
                end
                if ~trialed
                    if strcmp(obj.mechanism, 'APD')
                        Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^2);
                    else
                        Pop = obj.smsGeneration(Problem, Pop, N);
                    end
                    totalFE = totalFE + N;
                    ref = min(ref, max(Pop.objs, [], 1) * 1.1);
                end
                hvHistory(gen) = obj.calHV(Pop.objs, ref, M);
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end
            % 无 polishHV（消融）

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
