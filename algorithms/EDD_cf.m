classdef EDD_cf < EDD
    % EDD_cf - 约束战场版 EDD：继承 EDD v12 全部机制，仅扩展门控
    % 门控：highDim = (D>=100) || (M>=10) || (D>=10 && hasCon)
    % hasCon = CalCon 返回 [N x C] 且 C>0（约束题）
    % 其他机制（EED/DSG/HV 抛光/约束处理）与 EDD v12 完全一致
    methods
        function obj = EDD_cf(popSize, maxGen, seed)
            obj@EDD(popSize, maxGen, seed);
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            % 约束检测
            hasCon = false;
            try
                X0 = Problem.Initialization(1).decs;
                c0 = Problem.CalCon(X0);
                if ~isempty(c0) && size(c0,2) > 0, hasCon = true; end
            catch
                hasCon = false;
            end
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N); totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            % ★ 门控扩展：约束题 D>=10 强制 EED
            highDim = (D >= 100) || (M >= 10) || (D >= 10 && hasCon);
            for gen = 1:G
                if strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G))
                    ref = max(Pop.objs,[],1)*1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                end
                if highDim
                    Pop = obj.eedGeneration(Problem, Pop, N, M, obj.epsGrid);
                elseif strcmp(obj.mechanism,'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                end
                totalFE = totalFE + N;
                polishFrom = round(0.9*G);
                if gen >= polishFrom && mod(gen-polishFrom+1,5)==1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'V', obj.V, 'mechanism', obj.mechanism, 'switchGen', obj.switchGen, ...
                            'highDim', highDim, 'hasCon', hasCon, 'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end
    end
end
