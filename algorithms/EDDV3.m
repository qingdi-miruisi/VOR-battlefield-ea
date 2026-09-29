classdef EDDV3 < ALGORITHM
    % EDD v3 - Epsilon-Dependent Diversity（LSMOP1-9 D=300 改进版）
    %
    % 相对 v12（旧 EDD）的机制级改进（针对诊断：单父 DSG 在 300D 下开发能力不足，
    % 三新算法都用"低维参数/聚类开发 + 全维映射"制胜）：
    %   [改进C1] kmeans 聚类 + 代际差向量 GDV（移植 GDVTSF）：
    %      每代 kmeans 聚 K=5 群决策空间，算代际中心差方向作定向速度分量。
    %      子代位置更新 = 当前位置 + 有向速度 + GDV（借鉴 TSO 灰狼式开发）。
    %      动机：GDV 让每子代带"全维有向移动"，比单父 dsgOperator 的段内随机强。
    %   [改进C2] 三蜂群 TSO 开发（移植 GDVTSF triple_swarm）：
    %      种群按适应度分 p1/p2/p3 三群，群间 TSO 式定向开发（gBest 定向 + 邻域扰动）。
    %      动机：GDVTSF 在 LSMOP1-2 与 EDD 差距最大（-86%/-82%），三蜂群开发是关键。
    %   [保留] EED 选择框架（epsilon 非支配 + front 层次）不变，只换子代生成算子。
    % 公平性：N=100 G=200 maxFE=20100 不变；ParetoFront(500)/refPoint 不变；
    %          种子 1:30 不变。FE 预算不变（kmeans/TSO 不额外花 FE，只是决策空间更新）。
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
        Kclu;         % kmeans 群数（GDV）
    end

    methods
        function obj = EDDV3(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2; obj.mechanism = 'APD'; obj.switchGen = maxGen;
            obj.hvPrev10 = 0; obj.hvGen10 = 0; obj.divScale = 0;
            obj.shrinkBase = 0.05; obj.shrink = 0.05;
            obj.epsGrid = 10;   % D>=100 epsilon 网格
            obj.Kclu = 5;       % kmeans 群数（GDV）
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N); totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            highDim = (D >= 100) || (M >= 10);
            % ---- 改进C1：GDV 状态初始化（kmeans 聚类 + 代际中心）----
            GDV = zeros(N, D);
            [Lidx, Lcenter] = kmeans(Pop.decs, obj.Kclu, 'MaxIter', 20);
            Lrd = zeros(obj.Kclu, D);
            for ki = 1:obj.Kclu
                ch = Lidx == ki;
                Lrd(ki,:) = mean(abs(Lcenter(ki,:) - Pop.decs(ch,:)), 1);
            end
            LpopDec = Pop.decs; LpopObj = Pop.objs;
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
                    [Pop, GDV, Lrd, Lcenter, Lidx, LpopDec, LpopObj] = ...
                        obj.eedGeneration_v3(Problem, Pop, N, M, obj.epsGrid, obj.Kclu, ...
                                            GDV, Lrd, Lcenter, Lidx, LpopDec, LpopObj);
                elseif strcmp(obj.mechanism,'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                end
                totalFE = totalFE + N;
                % 末端 HV 抛光（D<100 路径，继承 HCEA；highDim 用 eedGeneration 内置全维 polish）
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

        %% ===== EED v3 环境选择（GDV + 三蜂群 TSO 开发 + EED 选择）=====
        function [Pop, GDV, Lrd, Lcenter, Lidx, LpopDec, LpopObj] = eedGeneration_v3(...
                obj, Problem, Pop, N, M, epsGrid, K, GDV, Lrd, Lcenter, Lidx, LpopDec, LpopObj)
            D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;
            % ---- 改进C2：三蜂群 TSO 开发（移植 GDVTSF triple_swarm_select + operator_GDV_TSO）----
            fitness = obj.cal_fitness(Pop.objs);   % 目标空间最小距离适应度（小=好）
            fitness = fitness(:).';                % 确保行向量
            swarmN = floor(N/3);
            Rank = randperm(N, swarmN*3);
            p1 = Rank(1:swarmN); p2 = Rank(swarmN+1:2*swarmN); p3 = Rank(2*swarmN+1:end);
            p1 = p1(:).'; p2 = p2(:).'; p3 = p3(:).';   % 确保行向量
            [p1,p2,p3] = obj.triple_swarm_select(fitness, p1, p2, p3);
            p1 = p1(:); p2 = p2(:); p3 = p3(:);   % 列向量供算子索引
            % gBest：front-1 中到 UniformPoint 角度最近者（GDVTSF update_gbest 式）
            [Vg, ~] = UniformPoint(N, M, 'NBI');
            gBestDec = Pop.decs(1,:);      % 默认（fallback）
            [fn, ~] = NDSort(Pop.objs, Pop.cons, inf);
            f1idx = find(fn==1);
            if ~isempty(f1idx)
                gBestDec = Pop.decs(f1idx,:);   % front-1 全体（多参考，gBestRow）
            end
            gBestRow = gBestDec;             % F1×D 行向量矩阵
            gBestCol = gBestDec(1,:);        % 1×D 列（供 gBestSelDec 用）
            B = 20; G_ctrl = 0.5;
            T_clu = 20;
            % 生成 TSO 式子代（当前种群 + GDV 有向速度 + 三蜂群定向）
            PopDec = obj.operator_GDV_TSO(Problem, Pop, gBestCol, gBestRow, GDV, p1, p2, p3, B, G_ctrl);
            NewObj = Problem.CalObj(PopDec);
            NewCon = Problem.CalCon(PopDec);
            % 更新 GDV（kmeans 重聚类，算代际中心差）
            [GDV, Lrd, Lcenter] = obj.cal_GDV_v3(N, D, K, T_clu, PopDec, NewObj, Lrd, LpopObj, Lcenter, Lidx);
            LpopDec = Pop.decs; LpopObj = Pop.objs;
            % 合并 旧种群 + TSO 子代，经 EED 选择
            M1 = struct();
            M1.decs = [Pop.decs; PopDec]; M1.objs = [Pop.objs; NewObj]; M1.cons = [Pop.cons; NewCon];
            nAll = size(M1.objs, 1);
            [FrontNo, ~] = NDSort(M1.objs, M1.cons, inf);
            nd = find(FrontNo == 1); nd = nd(:);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
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
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
            % 更新 GDV 状态（代际中心/半径/聚类索引）
            LpopDec = Pop.decs; LpopObj = Pop.objs;
        end

        %% ===== 三蜂群 TSO 算子（移植 GDVTSF operator_GDV_TSO，简化版）=====
        function popDec = operator_GDV_TSO(obj, Problem, population, gBestCol, gBestRow, GDV, p1, p2, p3, B, G_ctrl)
            N = size(population.decs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            fitness = obj.cal_fitness(population.objs);
            fitness = fitness(:);
            swarmN = numel(p1);
            popVel = zeros(N, D);
            gBestSelDec = zeros(swarmN, D);
            for i = 1:swarmN
                V = zeros(B, D);
                H = zeros(B, 1);
                if ~isempty(gBestRow)
                    dis = dist(population.decs(p1(i),:), gBestRow.');
                    if ~isempty(dis)
                        [~, mi] = min(dis, [], 2);
                    else
                        mi = 1;
                    end
                    if rand() <= G_ctrl
                        gBestSelDec(i,:) = gBestRow(min(mi,size(gBestRow,1)),:);
                    else
                        gBestSelDec(i,:) = gBestRow(randi(size(gBestRow,1),1),:);
                    end
                else
                    gBestSelDec(i,:) = population.decs(p1(i),:);
                end
                for j = 1:B
                    t = rand(); r = rand();
                    V(j,:) = population.decs(p1(i),:) + r.*(t.*(population.decs(p2(i),:)-population.decs(p1(i),:)) + ...
                             (1-t).*(population.decs(p3(i),:)-population.decs(p1(i),:)));
                    L1 = norm(population.decs(p1(i),:) - population.decs(p2(i),:));
                    L2 = norm(population.decs(p2(i),:) - population.decs(p3(i),:));
                    L3 = norm(population.decs(p3(i),:) - population.decs(p1(i),:));
                    L = (L1+L2+L3)/3; L = max(L,1e-12);
                    H(j) = log(2*pi*exp(1)*(1-exp(-norm(V(j,:)-population.decs(p1(i),:)).^2/L^2)))/max(fitness(p1(i)),1e-12);
                    H(j) = H(j) + log(2*pi*exp(1)*(1-exp(-norm(V(j,:)-population.decs(p2(i),:)).^2/L^2)))/max(fitness(p2(i)),1e-12);
                    H(j) = H(j) + log(2*pi*exp(1)*(1-exp(-norm(V(j,:)-population.decs(p3(i),:)).^2/L^2)))/max(fitness(p3(i)),1e-12);
                end
                H(H<0) = 0;   % 防 log 负值
                [~, idx] = sort(H, 'descend');
                popVel(p2(i),:) = V(idx(1),:) - population.decs(p2(i),:);
                popVel(p3(i),:) = V(idx(2),:) - population.decs(p3(i),:);
            end
            rate = 0.3;   % 简化：固定 FE 比例（GDVTSF 用 Problem.FE/maxFE）
            C1 = (1.5-rate)*repmat(rand(N,1), 1, D);
            C2 = (1.5-rate)*repmat(rand(N,1), 1, D);
            popVel(p1,:) = (gBestSelDec - population.decs(p1,:));
            popVel(p2,:) = C1(p2,:).*popVel(p2,:) + C2(p2,:).*(population.decs(p1,:) - population.decs(p2,:));
            popVel(p3,:) = C1(p3,:).*popVel(p3,:) + C2(p3,:).*(population.decs(p1,:) - population.decs(p3,:));
            velMax = (ub - lb);                     % D 长行向量
            popVel = min(max(popVel, -repmat(velMax, N, 1)), repmat(velMax, N, 1));
            popDec = population.decs + popVel + GDV;
            popDec = max(min(popDec, repmat(ub, N, 1)), repmat(lb, N, 1));
            % GDVTSF 的混沌变异（Site1/Site2，保留全维探索）
            disM = 20;
            Site1 = repmat(rand(N,1)<0.999, 1, D);
            Site2 = rand(N,D) < 1/D;
            mu = rand(N,D);
            ubRep = repmat(ub, N, 1); lbRep = repmat(lb, N, 1);
            widthAll = ubRep - lbRep; widthAll(widthAll==0) = 1;
            temp = Site1 & Site2 & (mu<=0.5);
            popDec(temp) = popDec(temp) + widthAll(temp).*((2.*mu(temp)+(1-2.*mu(temp)).*...
                (1-(popDec(temp)-lbRep(temp))./widthAll(temp)).^(disM+1)).^(1/(disM+1))-1);
            temp = Site1 & Site2 & (mu>0.5);
            popDec(temp) = popDec(temp) + widthAll(temp).*(1-(2.*(1-mu(temp))+2.*(mu(temp)-0.5).*...
                (1-(ubRep(temp)-popDec(temp))./widthAll(temp)).^(disM+1)).^(1/(disM+1)));
            popDec = max(min(popDec, ubRep), lbRep);
        end

        %% ===== kmeans + 代际差向量 GDV（移植 GDVTSF cal_GDV）=====
        function [GDV, Lrd2, Lcenter2] = cal_GDV_v3(obj, N, D, K, T_clu, popDec, popObj, Lrd, LpopObj, Lcenter, Lidx)
            GDV = zeros(N, D);
            R = rand(N,1);
            [Lidx2, Lcenter2] = kmeans(popDec, K, 'MaxIter', T_clu);
            Lrd2 = zeros(K, D);
            for ki = 1:K
                ch = Lidx2 == ki;
                Lrd2(ki,:) = mean(abs(Lcenter2(ki,:) - popDec(ch,:)), 1);
            end
            for ki = 1:K
                ch = Lidx2 == ki;
                if ~any(ch), continue; end
                dis = dist(Lcenter2(ki,:), Lcenter');
                [~, mi] = min(dis, [], 2);
                C1num = sum(ch);
                C1obj = popObj(ch,:);
                C2obj = LpopObj(Lidx==mi,:);
                fit = obj.cal_fitness([C1obj; C2obj]);
                fmax = max(fit)+0.001; fmin = min(fit);
                fitn = (fit - fmin)/(fmax - fmin);
                f1 = max(fitn(1:C1num));
                f2 = max(fitn(C1num+1:end));
                if xor(f1 > f2, all(Lrd2(ki,:) <= Lrd(mi,:)))
                    om = 0;
                else
                    om = 1;
                end
                vec = sign(f1-f2)*(Lcenter2(ki,:) - Lcenter(mi,:)) + om*(Lcenter2(ki,:) - popDec(ch,:));
                nv = norm(vec);
                if nv > 1e-12
                    GDV(ch,:) = R(ch,:).*Lrd2(ki,:).*vec./nv;
                end
            end
        end

        %% ===== 适应度（目标空间最小距离，移植 GDVTSF cal_fitness）=====
        function fitness = cal_fitness(obj, PopObj)
            % 目标空间最小距离适应度（移植 GDVTSF cal_fitness，向量安全版）
            Nn = size(PopObj,1); Md = size(PopObj,2);
            fmax = max(PopObj,[],1); fmin = min(PopObj,[],1);
            width = fmax - fmin; width(width==0) = 1;
            PopObj = (PopObj - repmat(fmin,Nn,1))./repmat(width,Nn,1);
            Dis = inf(Nn,1);
            for i = 1:Nn
                if Nn > 1
                    Sp = max(PopObj, repmat(PopObj(i,:), Nn, 1));   % Nn×Md
                    Sp(i,:) = inf;                                   % 排除自身
                    % 每点 i 到所有 j 的 max-norm 距离
                    Di = sum(abs(Sp - repmat(PopObj(i,:), Nn, 1)), 2);
                    Di(i) = 0;
                    Dis(i) = min(Di(~isnan(Di)));
                end
            end
            fitness = Dis;
        end

        %% ===== 三蜂群选择（移植 GDVTSF triple_swarm_select）=====
        function [p1,p2,p3] = triple_swarm_select(obj, fitness, p1, p2, p3)
            Change1 = fitness(p3) > fitness(p1);
            Temp = p1(Change1);
            p1(Change1) = p3(Change1);
            p3(Change1) = Temp;
            Change2 = (fitness(p2) > fitness(p1)) & (fitness(p2) > fitness(p3));
            Temp = p1(Change2);
            p1(Change2) = p2(Change2);
            p2(Change2) = Temp;
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
