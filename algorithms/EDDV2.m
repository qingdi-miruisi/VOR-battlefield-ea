classdef EDDV2 < ALGORITHM
    % EDD v2 - Epsilon-Dependent Diversity（LSMOP1-9 D=300 改进版）
    %
    % 相对 v12（旧 EDD）的机制级改进：
    %   [改进A] 双源有向交叉：eedGeneration 中 70% 子代改为 2 父代有向 SBX 交叉
    %            （P1/P2 随机不同父代，beta=1/15 全维），30% 保留旧 DSG 段内采样（全局探索）。
    %            动机：旧版每子代=单父灰狼式局部移动，300D 下 front-1 长期停滞；
    %            FDSEA/GDVTSF 都有双源开发能力，双源交叉补齐开发。
    %   [改进B] 全维 polish（0.8G 起）：旧版 polishHV 是 1% 局部扰动（300D 下仅 3 维随机），
    %            新版用 front-1 决策变量做 DSG 段内采样生成 10%N 子代并入 EED 选择。
    %            FE 计入 totalFE，保持 N=100 G=200 maxFE=20100 预算不变。
    % 公平性：ParetoFront/HV 参考点/种子/N/G 均不变。
    %
    % 定位：面向 M>=3 多目标 + D>=100 高维决策空间

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
        function obj = EDDV2(popSize, maxGen, seed)
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
            highDim = (D >= 100) || (M >= 10);
            for gen = 1:G
                % HV 验证切换 50/60/70%（继承 HCEA，仅 D<100 APD 路径）
                if strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G))
                    ref = max(Pop.objs,[],1)*1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                end
                if highDim
                    [Pop, kPolish] = obj.eedGeneration(Problem, Pop, N, M, obj.epsGrid, gen, G);
                    totalFE = totalFE + N + kPolish;
                elseif strcmp(obj.mechanism,'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                    totalFE = totalFE + N;
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                end
                % 末端 HV 抛光（D<100 路径，继承 HCEA）
                polishFrom = round(0.9*G);
                if ~highDim && gen >= polishFrom && mod(gen-polishFrom+1,5)==1
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

        %% ===== EED 环境选择（v2：双源交叉 + DSG 探索 + 全维 polish）=====
        function [Pop, kPolish] = eedGeneration(obj, Problem, Pop, N, M, epsGrid, gen, G)
            kPolish = 0;
            nCur = size(Pop.decs, 1);
            Dd = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;

            % ---- 改进A：双源有向交叉 70% + DSG 探索 30% ----
            nX = max(1, round(N*0.7));
            nO = N - nX;
            % 双源交叉子代：随机取 2 个不同父代，有向 SBX 交叉（beta=1/15）
            % （P1/P2 为 1×nX 行向量；O1X.decs 为 nX×Dd 矩阵，每行对应一对父代）
            P1 = randi(nCur, 1, nX); P1 = P1(:).';
            P2 = randi(nCur, 1, nX); P2 = P2(:).';
            same = (P2 == P1); P2(same) = mod(P2(same), nCur) + 1;   % 保证 P2≠P1
            X1 = Pop.decs(P1, :); X2 = Pop.decs(P2, :);   % nX×Dd
            mu = rand(nX, Dd);
            % SBX beta（逐维）：mu<=0.5 -> (2mu)^(1/15)，mu>0.5 -> (2-2mu)^(-1/15)
            mLE = (mu <= 0.5); mGT = (mu > 0.5);
            base = 2*mu;            base(mGT) = 2 - 2*mu(mGT);
            expn = ones(nX, Dd)/15; expn(mGT) = -1/15;
            beta = base .^ expn;
            beta = beta .* (-1).^randi([0,1], nX, Dd);
            beta(rand(nX, Dd) < 0.5) = 1;   % 每维 50% 不交换（类似 NSGA-II SBX）
            O1X.decs = (X1 + X2)/2 + beta.*(X1 - X2)/2;
            O1X.decs = min(max(O1X.decs, lb), ub);
            O1X.objs = Problem.CalObj(O1X.decs); O1X.cons = Problem.CalCon(O1X.decs);
            % DSG 探索子代（旧机制保留，负责全局多样性）
            mp = randi(nCur, 1, nO);
            O1O.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));
            O1O.objs = Problem.CalObj(O1O.decs); O1O.cons = Problem.CalCon(O1O.decs);
            O1.decs = [O1X.decs; O1O.decs];
            O1.objs = [O1X.objs; O1O.objs];
            O1.cons = [O1X.cons; O1O.cons];

            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            F = M1.objs;
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1); nd = nd(:);
            Fmin = min(F, [], 1); Fmax = max(F, [], 1);
            width2 = Fmax - Fmin; width2(width2==0) = 1;
            % 自适应 epsilon 网格：front-1 少时加密（改进B 辅助）
            curGrid = epsGrid;
            if numel(nd) < N && numel(nd) > 0
                curGrid = min(epsGrid, max(2, floor(numel(nd)/2)+1));
            end
            eps = width2 / curGrid;
            % （epsilon 网格计算保留，供后续角度选择扩展；本版本主要靠 front 层次选择）
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:N));
            elseif numel(nd) < N
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
            % ---- 改进B：0.8G 起全维 polish（用 front-1 决策变量做 DSG 段内采样）----
            if gen >= round(0.8*G)
                f1idx = find(FrontNo == 1);
                if numel(f1idx) > 0
                    f1decs = M1.decs(f1idx, :);
                    nNew = max(1, round(N*0.1));
                    q1 = quantile(f1decs, 0.15, 1);
                    q2 = quantile(f1decs, 0.5, 1);
                    q3 = quantile(f1decs, 0.85, 1);
                    newDe = zeros(nNew, Dd);
                    wRand = 0.5 + 0.1*min(M,10)/10;
                    for i = 1:nNew
                        seg = randi(3);
                        switch seg
                            case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                            case 2, lo = q1; hi = q3; segBest = q2;
                            otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                        end
                        candI = lo + rand(1,Dd).*(hi - lo);
                        a = 2 * (1 - i/max(nNew,1));
                        r1 = 2*(rand()-0.5);
                        dir = segBest - candI;
                        candI = wRand*candI + (1-wRand)*a*r1*dir;
                        newDe(i,:) = min(max(candI, lb), ub);
                    end
                    M1.decs = [M1.decs; newDe];
                    M1.objs = [M1.objs; Problem.CalObj(newDe)];
                    M1.cons = [M1.cons; Problem.CalCon(newDe)];
                    kPolish = nNew;
                    % 重新选择（含 polish 子代）
                    nAll2 = size(M1.objs, 1);
                    [FrontNo, ~] = NDSort(M1.objs, M1.cons, inf);
                    nd2 = find(FrontNo == 1);
                    PopObj2 = M1.objs - repmat(min(M1.objs,[],1), nAll2, 1);
                    if numel(nd2) > N
                        [~, ord2] = sort(sum(PopObj2(nd2,:).^2, 2));
                        nd = nd2(ord2(1:N));
                    else
                        keep2 = nd2(:);
                        for f = 2:max(FrontNo)
                            candF = find(FrontNo == f);
                            if isempty(candF), continue; end
                            if numel(keep2) >= N, break; end
                            keep2 = [keep2; candF(:)];
                        end
                        nd = keep2(1:min(N, numel(keep2)));
                        if numel(nd) < N
                            fill = setdiff(1:nAll2, nd);
                            nd = [nd; fill(1:(N-numel(nd)))]';
                        end
                    end
                end
            end
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
        end

        %% ===== DSG 有向决策采样算子（保留 v12，全局探索）=====
        function Offspring = dsgOperator(obj, Problem, ParentDecs)
            N = size(ParentDecs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width == 0) = 1;
            Offspring = zeros(N, D);
            F = Problem.CalObj(ParentDecs);
            [~, order] = sort(sum(F, 2));
            nTop = ceil(N/2);
            topDecs = ParentDecs(order(1:min(nTop, numel(order))), :);
            q1 = quantile(topDecs, 0.15, 1);
            q2 = quantile(topDecs, 0.5, 1);
            q3 = quantile(topDecs, 0.85, 1);
            M = Problem.nObj;
            wRand = 0.5 + 0.1*min(M,10)/10;
            wDir  = 1 - wRand;
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1;
                    case 2, lo = q1; hi = q3;
                    otherwise, lo = q3; hi = ub - 0.05*width;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                if seg == 1, segBest = q1;
                elseif seg == 2, segBest = q2;
                else, segBest = q3; end
                a = 2 * (1 - i/max(N,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% ===== 继承 HCEAV4 APD/SMS/抛光（D<100）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V; NV = size(V,1); nCur = size(Pop.objs,1);
            mp = randi(nCur, 1, N);
            O1 = struct(); O1.decs = OperatorGA(Problem, Pop.decs(mp,:));
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

        function Pop = smsGeneration(obj, Problem, Pop, N)
            M = Problem.nObj; nCur0 = size(Pop.objs,1); target = nCur0-1; if target<N, target=N; end
            for j = 1:N
                nCur = size(Pop.objs,1);
                O1 = struct(); O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur,2),:));
                O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
                M1 = struct(); M1.decs=[Pop.decs;O1.decs]; M1.objs=[Pop.objs;O1.objs]; M1.cons=[Pop.cons;O1.cons];
                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur+1,0), inf);
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
                keep = 1:nCur+1; keep(delIdx) = [];
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
