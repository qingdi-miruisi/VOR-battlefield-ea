classdef EDDV4 < ALGORITHM
    % EDD v4 - Epsilon-Dependent Diversity + FDSEA 低频傅里叶参数化开发
    %
    % 机制（针对诊断：单父 DSG / 双源 SBX / TSO+GDV 在 300D 决策空间硬开发均失败，
    % IGD 第1 的 FDSEA 赢在"12 维频率域参数空间开发 + Cal_Dec 全维映射"）：
    %   [改进D] 低频傅里叶参数化开发（移植 FDSEA Cal_Dec + FRGA 参数空间算子）：
    %      - 种群双表示：决策变量 x∈[0,1]^D + 参数 θ∈[0,1]^(2K+2), K=5 → 12 维
    %      - 每代在 12 维参数空间做 SBX 交叉 + 多项式变异（FRGA 式），
    %        再经 Cal_Dec 映射回 300 维决策变量：
    %          x_j = θ_(2K+2)/2 + Σ_{k=1}^{K} θ_{2k+1}·cos(k·θ_{2K+1}·j + θ_{2k+2})
    %      - 子代经 EED 选择（front-1 + epsilon 网格 + 角度多样性，v12 保留）
    %      - 动机：把 300D 决策空间的"有向开发"投影到 12D 参数空间，
    %        低频余弦基天然适配 LSMOP 类大尺度多目标平滑 front。
    % 保留：EED 环境选择框架、epsilon 网格、NBI 角度多样性、APD/SMS 低维路径、
    %        末端 HV 抛光、HV 验证切换 50/60/70%。
    % 公平性：N=100 G=200 maxFE=20100 不变；ParetoFront(500)/refPoint 不变；
    %          种子 1:30 不变。Cal_Dec 零 FE 成本，参数算子不额外花 FE。
    % 定位：面向 M>=3 多目标 + D>=100 高维决策空间
    %
    % 注：轮次3（方案D），最后一轮机会。若仍不能让 EDD 拿回 Friedman #1，按协议停止。

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
        K;           % FDSEA 频率域保留级数（默认 5 → 2K+2=12 参数）
    end

    methods
        function obj = EDDV4(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2; obj.mechanism = 'APD'; obj.switchGen = maxGen;
            obj.hvPrev10 = 0; obj.hvGen10 = 0; obj.divScale = 0;
            obj.shrinkBase = 0.05; obj.shrink = 0.05;
            obj.epsGrid = 10;   % D>=100 epsilon 网格
            obj.K = 5;          % FDSEA K（2K+2=12 参数）
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            highDim = (D >= 100) || (M >= 10);
            % ---- 初始化 ----
            if highDim
                % 参数化初始化：θ ∈ [0,1]^(2K+2)，经 Cal_Dec 映射决策变量
                Lp = 2*obj.K + 2;
                Pop.para = unifrnd(0, 1, N, Lp);
                Pop.decs = obj.calDec(Pop.para, N, D);
                Pop.objs = Problem.CalObj(Pop.decs);
                Pop.cons = Problem.CalCon(Pop.decs);
            else
                Pop = Problem.Initialization(N);
            end
            totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            for gen = 1:G
                % HV 验证切换 50/60/70%（继承 HCEA，仅 D<100 APD 路径）
                if strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G)) && ~highDim
                    ref = max(Pop.objs,[],1)*1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                end
                if highDim
                    Pop = obj.eedGeneration_v4(Problem, Pop, N, M, obj.epsGrid, obj.K);
                elseif strcmp(obj.mechanism,'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                end
                totalFE = totalFE + N;
                % 末端 HV 抛光（继承 HCEA；highDim 也保留，0.9G 起）
                polishFrom = round(0.9*G);
                if gen >= polishFrom && mod(gen-polishFrom+1,5)==1
                    [Pop, k] = obj.polishHV(Problem, Pop, M, highDim, obj.K, D);
                    totalFE = totalFE + k;
                end
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            if ~highDim && ~isfield(Pop,'para'), Pop.para = []; end
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'V', obj.V, 'mechanism', obj.mechanism, 'switchGen', obj.switchGen, ...
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            if isfield(Pop,'para') && ~isempty(Pop.para), Population.para = Pop.para; end
            warning(w0);
        end

        %% ===== EED v4 环境选择（v12 选择框架 + FDSEA 参数化开发）=====
        function Pop = eedGeneration_v4(obj, Problem, Pop, N, M, epsGrid, K)
            D = Problem.nVar;
            Lp = 2*K + 2;
            % ---- 改进D：参数空间 FRGA（SBX + 多项式变异）生成子代参数 ----
            P = Pop.para;          % N×Lp 当前参数
            P_off = obj.frGA_param(P, K);   % N×Lp 子代参数
            % ---- Cal_Dec 映射子代参数 → 300D 决策变量 ----
            O1.decs = obj.calDec(P_off, N, D);
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);
            Pop.para = P_off;   % 子代行号 1..nO（=N）
            % ---- 合并 + EED 选择（v12 front-1 + epsilon 网格 + 角度多样性）----
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            M1.para = [Pop.para; P_off];
            nAll = size(M1.objs, 1);
            F = M1.objs;
            Fmin = min(F,[],1); Fmax = max(F,[],1);
            width = Fmax - Fmin; width(width==0) = 1;
            eps = width / epsGrid;
            % EED 选择：front-1 按到原点距离排序（保留最收敛的 N 个），不足 N 时按 front 层次补齐
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1); nd = nd(:);
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:N));
                nd = nd(:);
            end
            % epsilon 网格多样性修正（v12 风格：按目标空间 epsilon 网格保留代表）
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            [gU, gI] = unique(gridIdx, 'rows');
            if numel(gU) > N
                % 网格数过多：按网格数缩减（保留每网格到原点最近者）
                keepGrid = false(nAll,1);
                for gu = 1:numel(gU)
                    inG = find(gI == gu);
                    if ~isempty(inG)
                        [~, ii] = min(sum(PopObj(inG,:).^2, 2));
                        keepGrid(inG(ii)) = true;
                    end
                end
                kidx = find(keepGrid);
                target = min(N, numel(kidx));
                if numel(kidx) > 0
                    [~, ordG] = sort(sum(PopObj(kidx,:).^2, 2));
                    nd = kidx(ordG(1:target));
                    nd = nd(:);
                end
            end
            % front 层次补齐（nd < N 时，按 front 2,3,... 顺序补到 N）
            if numel(nd) < N
                rest = setdiff(1:nAll, nd);
                rest = rest(:);
                if ~isempty(rest)
                    [~, ordF] = sort(FrontNo(rest));
                    take = min(N-numel(nd), numel(rest));
                    nd = [nd; rest(ordF(1:take))];
                end
            end
            if numel(nd) > N, nd = nd(1:N); end
            nd = nd(:);
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
            Pop.para = M1.para(nd,:);
        end

        %% ===== FRGA 参数空间算子（移植 FDSEA FRGA，内联自包含）=====
        function P_off = frGA_param(obj, P, K)
            Np = size(P,1); Lp = 2*K + 2;
            Nhalf = floor(Np/2);
            P1 = P(1:Nhalf,:); P2 = P(Nhalf+1:min(2*Nhalf, Np),:);
            nO = size(P1,1);   % 子代行数
            % SBX 交叉（参数空间 [0,1]）
            proC = 1; disC = 20;
            beta = zeros(nO, Lp); mu = rand(nO, Lp);
            beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
            beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
            beta = beta .* (-1).^randi([0,1], nO, Lp);
            beta(rand(nO,Lp)<0.5) = 1;
            beta(repmat(rand(nO,1)>proC, 1, Lp)) = 1;
            O1 = [(P1+P2)/2 + beta.*(P1-P2)/2
                  (P1+P2)/2 - beta.*(P1-P2)/2];
            % 多项式变异（参数空间 [0,1]）
            proM = 1; disM = 20;
            Lower = zeros(2*nO, Lp); Upper = ones(2*nO, Lp);
            Site = rand(2*nO, Lp) < proM/Lp;
            mu2 = rand(2*nO, Lp);
            O1 = min(max(O1, Lower), Upper);
            temp = Site & (mu2<=0.5);
            O1(temp) = O1(temp) + (Upper(temp)-Lower(temp)).*((2.*mu2(temp) + (1-2.*mu2(temp)).*...
                (1-(O1(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)) - 1);
            temp = Site & (mu2>0.5);
            O1(temp) = O1(temp) + (Upper(temp)-Lower(temp)).*(1-(2.*(1-mu2(temp)) + 2.*(mu2(temp)-0.5).*...
                (1-(Upper(temp)-O1(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
            P_off = O1;
        end

        %% ===== Cal_Dec（移植 FDSEA：参数 → 决策变量，零 FE 成本）=====
        function Dec = calDec(obj, ModelParemeters, N, D)
            L = size(ModelParemeters, 2);   % 2K+2
            Dec = zeros(N, D);
            K = (L-2)/2;
            for i = 1:N
                P = ModelParemeters(i,:);
                for j = 1:D
                    Dec(i,j) = P(end)/2;
                    for k = 1:K
                        Dec(i,j) = Dec(i,j) + P(2*k+1)*cos(k*P(end-1)*j + P(2*k+2));
                    end
                end
            end
            % 归一化到 [0,1]（Cal_Dec 原始输出可能超出，FDSEA 用 (upper-lower)*Dec+lower，
            % 本地 EDD 的 OfficialProblem 边界 [0,1]，直接截断）
            Dec = min(max(Dec, 0), 1);
        end

        %% ===== 末端 HV 抛光（highDim 版：在参数空间扰动，经 Cal_Dec 映射）=====
        function [Pop, k] = polishHV(obj, Problem, Pop, M, highDim, K, D)
            N = size(Pop.decs,1); ref = max(Pop.objs,[],1)*1.1;
            best = obj.calHV(Pop.objs, ref, M); k = 0;
            Lp = 2*K + 2;
            for t = 1:3
                i = randi(N);
                if highDim && isfield(Pop,'para')
                    % 参数空间多项式式扰动（小幅）
                    dP = 0.01*(rand(1,Lp)-0.5);
                    candP = Pop.para(i,:) + dP;
                    candP = min(max(candP, 0), 1);
                    candDe = obj.calDec(candP, 1, D);
                    candDe = min(max(candDe, 0), 1);
                    candO = Problem.CalObj(candDe);
                    Pop.decs(i,:) = candDe; Pop.objs(i,:) = candO;
                    Pop.cons(i,:) = Problem.CalCon(candDe);
                    Pop.para(i,:) = candP;
                else
                    cand = Pop.decs(i,:) + 0.01*(rand(1,Problem.nVar)-0.5);
                    cand = min(max(cand, Problem.lower), Problem.upper);
                    candO = Problem.CalObj(cand);
                    Pop.objs(i,:) = candO; Pop.decs(i,:) = cand;
                    Pop.cons(i,:) = Problem.CalCon(cand);
                end
                k = k+1;
            end
        end

        %% ===== 继承 HCEAV4 APD/SMS（D<100 用）=====
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
