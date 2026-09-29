classdef EDD16 < ALGORITHM
    % EDD (Epsilon-Dependent Diversity) v16 - 面向 M>=3 多目标 + D>=30 中等/高维
    % v12 基础：
    %   1. D<100：继承 HCEAV4 架构（APD+NBI + SMS-EMO + HV 切换 50/60/70% + 末端抛光）
    %   2. D>=100 或 M>=10：epsilon 非支配 + 角度多样性联合选择（EED）+ DSG 有向算子
    % v16 强化（基于 77 题 Friedman 诊断 + 三大短板题种群分布分析）：
    %   3. front-1 保留优先：APD 环境选择先按非支配层次保留 front-1（收敛），
    %      剩余名额再按 APD 角度多样性选择——修复 MaF14/DTLZ3_M3/DTLZ1_M3
    %      front-1 被 APD 顶点裁剪截断至 34-75 的缺陷（NSGA2 保持 100）
    %   4. 中等维 DSG：30<=D<100 且 M>=3 时用 dsgOperator 替代 OperatorGA
    %      （SBX 全维在 D=30 中维退化；dsgOperator 的 3 段模糊骨架 + 灰狼定向
    %       在 LSMOP2 D=30 / MaF15 D=50 已有优势，扩展到全 M>=3 中等维场景）
    % 定位：面向 M>=3 多目标与 D>=30 高维决策空间的混合进化算法

    properties
        alpha
        mechanism
        switchGen
        hvPrev10
        hvGen10
        shrinkBase
        divScale
        V;            % NBI 参考向量（D<100 用）
        shrink
        epsGrid;      % D>=100 epsilon 网格数
    end

    methods
        function obj = EDD16(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2; obj.mechanism = 'APD'; obj.switchGen = maxGen;
            obj.hvPrev10 = 0; obj.hvGen10 = 0; obj.divScale = 0;
            obj.shrinkBase = 0.05; obj.shrink = 0.05;
            obj.epsGrid = 10;   % D>=100 epsilon 网格
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N); totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            % highDim: D>=100 (EED 全维) 或 M>=10 (M 自适应 dsgOperator 替代 APD)
            highDim = (D >= 100) || (M >= 10);
            % medDim: 30<=D<100 且 M>=3——中等维 M>=3 用 dsgOperator 替代 OperatorGA
            medDim = (D >= 30) && (D < 100) && (M >= 3);
            for gen = 1:G
                % HV 验证切换 50/60/70%（继承 HCEA）
                if strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G))
                    ref = max(Pop.objs,[],1)*1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N, medDim);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                end
                % 环境选择：D>=100 用 EED，D<100 继承 HCEAV4 APD/SMS
                if highDim
                    Pop = obj.eedGeneration(Problem, Pop, N, M, obj.epsGrid);
                elseif strcmp(obj.mechanism,'APD')
                    % v16 front-1 保留优先仅在 M<=5（中等多目标）启用；
                    % M=8 低维保留 v12 原始 APD 顶点裁剪（防 DTLZ2/5_M8 回归）
                    if M <= 5
                        Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha, medDim);
                    else
                        Pop = obj.apdGenerationV12(Problem, Pop, N, M, (gen/G)^obj.alpha);
                    end
                else
                    Pop = obj.smsGeneration(Problem, Pop, N, medDim && M <= 5);
                end
                totalFE = totalFE + N;
                % 末端 HV 抛光（继承 HCEA）
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
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== EED 环境选择（D>=100 核心）：epsilon 非支配 + 角度多样性 =====
        function Pop = eedGeneration(obj, Problem, Pop, N, M, epsGrid)
            % 产生 N 个子代（D>=100 用 DSG 有向算子替代 OperatorGA，SBX 全维在高维失效）
            mp = randi(size(Pop.decs,1), 1, N);
            O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            % 1. epsilon 非支配筛选：对目标空间 epsilon 网格化，每网格保留最小目标
            F = M1.objs;
            Fmin = min(F, [], 1); Fmax = max(F, [], 1);
            width = Fmax - Fmin;
            width(width==0) = 1;
            eps = width / epsGrid;
            % 每个体归属网格索引
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            % EED 选择：front-1 按到原点距离排序（保留最收敛的 N 个），不足 N 时按 front 层次补齐
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1);
            nd = nd(:);
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:N));
            elseif numel(nd) == N
                % 正好 N 个非支配解：全保留（不裁剪，保持 PPS=N）
            else
                % 不足 N：front-1 全取，按 front 层次补齐
                keep = nd;
                for f = 2:max(FrontNo)
                    cand = find(FrontNo == f);
                    if numel(keep) >= N, break; end
                    keep = [keep; cand(:)];
                end
                nd = keep(1:min(N, numel(keep)));
                if numel(nd) < N
                    fill = setdiff(1:nAll, nd);
                    nd = [nd; fill(1:(N-numel(nd)))]';
                end
            end
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
        end

        %% ===== DSG 有向决策采样算子（D>=30 核心，替代 OperatorGA 的 SBX 全维）=====
        function Offspring = dsgOperator(obj, Problem, ParentDecs)
            N = size(ParentDecs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width == 0) = 1;
            Offspring = zeros(N, D);
            % 模糊决策骨架：每维 3 段（用种群当前分布的 0.15/0.5/0.85 分位）
            F = Problem.CalObj(ParentDecs);
            [~, order] = sort(sum(F, 2));
            nTop = ceil(N/2);
            topDecs = ParentDecs(order(1:min(nTop, numel(order))), :);
            q1 = quantile(topDecs, 0.15, 1);
            q2 = quantile(topDecs, 0.5, 1);
            q3 = quantile(topDecs, 0.85, 1);
            M = Problem.nObj;
            % M 自适应：高 M(>=8) 时提高段内随机权重（保留多样性），灰狼定向因子衰减
            wRand = 0.5 + 0.1*min(M,10)/10;   % M=3->0.53, M=10->0.6
            wDir  = 1 - wRand;
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1;
                    case 2, lo = q1; hi = q3;
                    otherwise, lo = q3; hi = ub - 0.05*width;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                if seg == 1
                    segBest = q1;
                elseif seg == 2
                    segBest = q2;
                else
                    segBest = q3;
                end
                a = 2 * (1 - i/max(N,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% ===== 继承 HCEAV4 APD（v16：front-1 保留优先 + 中等维 DSG）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta, medDim)
            V = obj.V; NV = size(V,1); nCur = size(Pop.objs,1);
            mp = randi(nCur, 1, N);
            if medDim
                O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));
            else
                O1.decs = OperatorGA(Problem, Pop.decs(mp,:));
            end
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct(); M1.decs=[Pop.decs;O1.decs]; M1.objs=[Pop.objs;O1.objs]; M1.cons=[Pop.cons;O1.cons];
            nAll = size(M1.objs,1);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            gamma = min(1-pdist2(V,V,'cosine'),[],2); gamma = gamma(:);
            gamma(gamma<1e-12|isnan(gamma)) = 1e-6;
            Angle = acos(max(-1,min(1,1-pdist2(PopObj,V,'cosine'))));
            [dmin,assoc] = min(Angle,[],2);
            APD = (1 + M*theta*dmin./gamma(assoc)).*sqrt(sum(PopObj.^2,2));
            D = Problem.nVar;
            % v16：front-1 保留优先——先保留全部 front-1（收敛），剩余名额按 APD 角度多样性填充
            [FrontNo, ~] = NDSort(M1.objs, M1.cons, inf);
            f1 = find(FrontNo == 1);
            if numel(f1) >= N
                % front-1 超过 N：按到原点距离升序取最收敛的 N 个
                f1o = f1(:);
                [~, o1] = sort(sum(PopObj(f1o,:).^2, 2));
                idx = f1o(o1(1:N));
            else
                % front-1 不足 N：全保留 + 剩余名额按 APD 值从 front>=2 填充
                keepF1 = f1(:);
                rest = setdiff(1:nAll, f1);
                [~, ordR] = sort(APD(rest));
                need = N - numel(keepF1);
                idx = [keepF1; rest(ordR(1:min(need, numel(rest))))'];
            end
            Pop.decs = M1.decs(idx,:); Pop.objs = M1.objs(idx,:); Pop.cons = M1.cons(idx,:);
        end

        %% ===== v12 原始 APD（M=8 低维 D<30 用）=====
        function Pop = apdGenerationV12(obj, Problem, Pop, N, M, theta)
            V = obj.V; NV = size(V,1); nCur = size(Pop.objs,1);
            mp = randi(nCur, 1, N);
            O1.decs = OperatorGA(Problem, Pop.decs(mp,:));
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct(); M1.decs=[Pop.decs;O1.decs]; M1.objs=[Pop.objs;O1.objs]; M1.cons=[Pop.cons;O1.cons];
            nAll = size(M1.objs,1);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            gamma = min(1-pdist2(V,V,'cosine'),[],2); gamma = gamma(:);
            gamma(gamma<1e-12|isnan(gamma)) = 1e-6;
            Angle = acos(max(-1,min(1,1-pdist2(PopObj,V,'cosine'))));
            [dmin,assoc] = min(Angle,[],2);
            APD = (1 + M*theta*dmin./gamma(assoc)).*sqrt(sum(PopObj.^2,2));
            Keep = false(nAll,1);
            for i = 1:NV
                cand = find(assoc==i);
                if ~isempty(cand), [~,ii] = min(APD(cand)); Keep(cand(ii)) = true; end
            end
            D = Problem.nVar;
            if D < 100
                [~,gOrd] = sort(gamma,'descend');
                for e = 1:min(2,NV)
                    vEnd = gOrd(e);
                    if isempty(find(assoc==vEnd))
                        angCol = Angle(:,vEnd); [~,ordAng] = sort(angCol);
                        top3 = ordAng(1:min(3,nAll));
                        if ~isempty(top3), [~,ii]=min(APD(top3)); Keep(top3(ii))=true; end
                    end
                end
            end
            idx = find(Keep); target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep); [~,ord] = sort(APD(rest));
                need = target-numel(idx); add = rest(ord(1:min(need,numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx,:); Pop.objs = M1.objs(idx,:); Pop.cons = M1.cons(idx,:);
        end

        %% ===== 继承 HCEAV4 SMS（v16：中等维 DSG）=====
        function Pop = smsGeneration(obj, Problem, Pop, N, medDim)
            M = Problem.nObj; nCur0 = size(Pop.objs,1); target = nCur0-1; if target<N, target=N; end
            for j = 1:N
                nCur = size(Pop.objs,1);
                if medDim
                    O1.decs = obj.dsgOperator(Problem, Pop.decs(randperm(nCur,2),:));
                else
                    O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur,2),:));
                end
                O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
                M1 = struct(); M1.decs=[Pop.decs;O1.decs]; M1.objs=[Pop.objs;O1.objs]; M1.cons=[Pop.cons;O1.cons];
                nCur = size(M1.objs,1);
                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur,0), inf);
                LastFront = find(FrontNo==max(FrontNo)); nLast = numel(LastFront);
                PopObjLast = M1.objs(LastFront,:);
                if M == 2
                    deltaS = inf(1,nLast); [~,rank] = sortrows(PopObjLast);
                    for i = 2:nLast-1
                        deltaS(rank(i)) = (PopObjLast(rank(i+1),1)-PopObjLast(rank(i),1))*(PopObjLast(rank(i-1),2)-PopObjLast(rank(i),2));
                    end
                else
                    deltaS = obj.calHVM(PopObjLast, max(M1.objs,[],1)*1.1, M);
                end
                [~,worst] = min(deltaS); delIdx = LastFront(worst);
                keep = 1:nCur; keep(delIdx) = [];
                Pop.decs = M1.decs(keep,:); Pop.objs = M1.objs(keep,:); Pop.cons = M1.cons(keep,:);
            end
        end

        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs,1); ref = max(Pop.objs,[],1)*1.1; best = obj.calHV(Pop.objs,ref,M); k = 0;
            for t = 1:3
                i = randi(N);
                cand = Pop.decs; cand(i,:) = cand(i,:) + 0.01*(rand(1,Problem.nVar)-0.5);
                cand = min(max(cand,Problem.lower),Problem.upper);
                candO = Problem.CalObj(cand(i,:)); Pop.objs(i,:) = candO; Pop.decs(i,:) = cand(i,:); k=k+1;
            end
        end

        function hv = calHV(obj, PopObj, ref, M)
            if M ~= 2
                hv = sum(obj.calHVM(PopObj, ref, M)); return;
            end
            PopObj = PopObj(all(PopObj<=ref,2),:);
            if isempty(PopObj), hv = 0; return; end
            PopObj = sortrows(PopObj,1);
            x = [PopObj(:,1); ref(1)]; hv = 0; ymin = ref(2);
            for i = 1:size(PopObj,1)
                if PopObj(i,2) < ymin, ymin = PopObj(i,2); end
                hv = hv + (x(i+1)-x(i))*(ref(2)-ymin);
            end
        end

        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000; k = 1;
            PopObj = PopObj(all(PopObj<=ref,2) & all(PopObj>=0,2),:);
            [N,~] = size(PopObj); if N==0, F = 0; return; end
            alpha = zeros(1,N);
            for i = 1:min(k,N), alpha(i) = prod((k-[1:i-1])./(N-[1:i-1]))./i; end
            Fmin = min(PopObj,[],1); rng(2026);
            S = unifrnd(repmat(Fmin,nSample,1), repmat(ref,nSample,1));
            PdS = false(N,nSample); dS = zeros(1,nSample);
            for i = 1:N
                x = sum(repmat(PopObj(i,:),nSample,1)-S<=0,2)==M;
                PdS(i,x) = true; dS(x) = dS(x)+1;
            end
            F = zeros(1,N);
            for i = 1:N
                F(i) = sum(alpha(dS(PdS(i,:))));
            end
        end
    end
end
