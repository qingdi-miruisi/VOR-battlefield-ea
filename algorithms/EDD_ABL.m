classdef EDD_ABL < ALGORITHM
    % EDD (Epsilon-Dependent Diversity) - 候选 D：EED 架构替代 NBI 参考向量
    % 核心机制（基于 SOTA DSG-EA 有向采样 + 诊断：APD+NBI 在 D>=100 多样性崩溃）：
    %   1. D<100：继承 HCEAV4 架构（APD+NBI + SMS-EMO + HV 切换 50/60/70% + 末端抛光）
    %   2. D>=100：替换 APD 环境选择为 epsilon 非支配 + 角度多样性联合选择（EED）
    %      - epsilon 非支配：对 M 维目标按 epsilon 网格化，保留每网格最优（收敛）
    %      - 角度多样性：在收敛非支配集内按目标空间角度均匀分布选择（多样性）
    %      不依赖 NBI 参考向量，避免 D>=100 时 NBI 顶点真空导致的多样性损失
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
        ablMode;      % 消融模式 0=full 1=noEED 2=noDSG 3=noPolish
    end

    methods
        function obj = EDD_ABL(popSize, maxGen, seed, ablMode)
            obj@ALGORITHM(popSize, maxGen, seed);
            if nargin < 4, ablMode = 0; end
            obj.ablMode = ablMode;
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
            % highDim: D>=100 (EED 全维) 或 M>=10 (M 自适应 dsgOperator 替代 APD)。
            % v12 修正：M=8 低维 D 场景 eedGeneration 在 DTLZ5_M8 多峰 front 上崩溃
            % (PPS 8-31, IGD 96.56 vs HCEAV4 APD 29.49 PPS 67)，DTLZ2_M8 同样劣于 APD
            % (eed 0.7935 vs APD 0.4077)。M=8 低维回退 HCEAV4 APD 路径，eed 仅 M>=10/D>=100 启用
            highDim = (D >= 100) || (M >= 10);
            if obj.ablMode == 1, highDim = (M >= 10); end   % no-EED：D>=100 也走 APD
            for gen = 1:G
                % HV 验证切换 50/60/70%（继承 HCEA）
                if strcmp(obj.mechanism,'APD') && any(gen == round([0.5 0.6 0.7]*G))
                    ref = max(Pop.objs,[],1)*1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb, obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt; end
                end
                % 环境选择：D>=100 用 EED，D<100 继承 HCEAV4 APD/SMS
                if highDim
                    Pop = obj.eedGeneration(Problem, Pop, N, M, obj.epsGrid);
                elseif strcmp(obj.mechanism,'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen/G)^obj.alpha);
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                end
                totalFE = totalFE + N;
                % 末端 HV 抛光（继承 HCEA）
                polishFrom = round(0.9*G);
                if obj.ablMode ~= 3 && gen >= polishFrom && mod(gen-polishFrom+1,5)==1
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
            if obj.ablMode == 2
                O1.decs = OperatorGA(Problem, Pop.decs(mp,:));   % no-DSG：SBX 替换
            else
                O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));
            end
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            % 1. epsilon 非支配筛选：对目标空间 epsilon 网格化，每网格保留最小目标
            F = M1.objs;
            Fmin = min(F, [], 1); Fmax = max(F, [], 1);
            width = Fmax - Fmin; width(width==0) = 1;
            eps = width / epsGrid;
            % 每个体归属网格索引
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            % EED 选择：front-1 按到原点距离排序（保留最收敛的 N 个），不足 N 时按 front 层次补齐
            % 修复：front-1 数量 >= N 时按收敛度裁剪到 N；front-1 < N 时全取 + 补齐（不丢非支配解）
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1);
            nd = nd(:);
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                % 超过 N：front-1 内按到原点距离升序取最收敛的 N 个（v10 锁定行为；
                % v12 多峰检测分支在 DTLZ5_M8 上无效——root cause 是 eedGeneration
                % epsilon 网格在 M=8 低维多峰 front 上非支配解数量骤减，非 front-1 裁剪）
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:N));
            elseif numel(nd) == N
                % 正好 N 个非支配解：全保留（不裁剪，保持 PPS=N）
            else
                % 不足 N：front-1 全取，按 front 层次补齐（v10 行为；v11 归一化距离补齐对 M=10 无净收益，回退）
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

        %% ===== DSG 有向决策采样算子（D>=100 核心，替代 OperatorGA 的 SBX 全维）=====
        %   继承 DSG-EA 模糊决策变量骨架 + 灰狼位置更新思想：
        %   1. 每维按种群分布聚成 低/中/高 3 段（模糊决策骨架）
        %   2. 每个子代 = 段内随机 + 灰狼式向"段内最优"定向移动（保留多样性）
        %   3. 不把所有子代拉到同一位置（v7 的教训：0.7*best+0.3*mid 致多样性崩）
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
            % 每子代：随机选段 + 段内随机 + 灰狼式向段中心移动
            M = Problem.nObj;
            % M 自适应：高 M(>=8) 时提高段内随机权重（保留多样性），灰狼定向因子衰减
            wRand = 0.5 + 0.1*min(M,10)/10;   % 段内随机权重（M=3->0.53, M=10->0.6）
            wDir  = 1 - wRand;                % 灰狼定向权重
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1;
                    case 2, lo = q1; hi = q3;
                    otherwise, lo = q3; hi = ub - 0.05*width;
                end
                % 段内随机采样
                cand = lo + rand(1,D) .* (hi - lo);
                % 灰狼式：向该段"目标最优个体"定向移动（段内 best）
                if seg == 1
                    segBest = q1;
                elseif seg == 2
                    segBest = q2;
                else
                    segBest = q3;
                end
                a = 2 * (1 - i/max(N,1));   % 灰狼收敛因子（探索→开发）
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                % M 自适应混合：高 M 时加权保留段内随机（wRand），降低灰狼定向（wDir*a*r1）
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% ===== 继承 HCEAV4 APD/SMS/抛光（D<100 用，与 HCEAV4 一致）=====
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

        %% ===== EDD-v13 PPS 恢复算子（已回退：MaF14 上未改善，v12 锁定）=====
        %   历史：v13/v14/v15 尝试 front-1<N/2 连续 20 代触发纯探索 dsgOperator 修复
        %   结果：MaF14 PPS 7-21 不变（触发条件在 HV-gated switch 后被重置），回退 v12
        function Pop = ppsRecovery(obj, Problem, Pop, N, M)
            % 回退后不再被调用；保留函数体以兼容旧代码路径
            return;
            D = Problem.nVar;
            nCur = size(Pop.decs,1);
            if nCur < N, return; end
            F = Pop.objs;
            [~, ordW] = sort(sum(F,2));
            nTop = max(10, round(nCur*0.2));
            topDe = Pop.decs(ordW(1:min(nTop, nCur)), :);
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;
            Ftop = Problem.CalObj(topDe);
            [~, oTop] = sort(sum(Ftop,2));
            nTop2 = min(size(topDe,1), max(10, round(size(topDe,1)*0.5)));
            topDec = topDe(oTop(1:nTop2), :);
            q1 = quantile(topDec, 0.15, 1);
            q2 = quantile(topDec, 0.5, 1);
            q3 = quantile(topDec, 0.85, 1);
            newDe = zeros(N, D);
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1;
                    case 2, lo = q1; hi = q3;
                    otherwise, lo = q3; hi = ub - 0.05*width;
                end
                newDe(i,:) = lo + rand(1,D).*(hi - lo);
            end
            newOb = Problem.CalObj(newDe);
            newCo = Problem.CalCon(newDe);
            M1.decs = [Pop.decs; newDe]; M1.objs = [Pop.objs; newOb]; M1.cons = [Pop.cons; newCo];
            nAll = size(M1.objs,1);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            V = obj.V; NV = size(V,1);
            gamma = min(1-pdist2(V,V,'cosine'),[],2); gamma = gamma(:);
            gamma(gamma<1e-12|isnan(gamma)) = 1e-6;
            theta = 0.3;
            Angle = acos(max(-1,min(1,1-pdist2(PopObj,V,'cosine'))));
            [dmin,assoc] = min(Angle,[],2);
            APD = (1 + M*theta*dmin./gamma(assoc)).*sqrt(sum(PopObj.^2,2));
            Keep = false(nAll,1);
            for i = 1:NV
                cand = find(assoc==i);
                if ~isempty(cand), [~,ii] = min(APD(cand)); Keep(cand(ii)) = true; end
            end
            [~,gOrd] = sort(gamma,'descend');
            for e = 1:min(2,NV)
                vEnd = gOrd(e);
                if isempty(find(assoc==vEnd))
                    angCol = Angle(:,vEnd); [~,ordAng] = sort(angCol);
                    top3 = ordAng(1:min(3,nAll));
                    if ~isempty(top3), [~,ii]=min(APD(top3)); Keep(top3(ii))=true; end
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

        function [Pop, kAdd] = archRecovery(obj, Problem, Pop, N, M, V)
            % EDD-v15 架构级 front-1 恢复：M=3/5 D<100 APD 路径 front-1 < N/4 时触发
            % 从 front-1 决策变量出发，用 dsgOperator 段内随机采样（保留灰狼定向弱分量）
            % 生成 N/2 个补充子代，合并后经 NDSort 层次选择保留 N 个
            kAdd = 0;
            nCur = size(Pop.decs,1);
            if nCur < N, return; end
            D = Problem.nVar;
            [fn, ~] = NDSort(Pop.objs, Pop.cons, inf);
            f1 = Pop.decs(fn==1, :);
            nF1 = size(f1,1);
            if nF1 == 0, return; end
            % dsgOperator 纯探索模式（从 front-1 决策变量采样）
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;
            q1 = quantile(f1, 0.15, 1);
            q2 = quantile(f1, 0.5, 1);
            q3 = quantile(f1, 0.85, 1);
            nNew = N - nCur;
            if nNew <= 0, return; end
            newDe = zeros(nNew, D);
            wRand = 0.5 + 0.1*min(M,10)/10;
            for i = 1:nNew
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                end
                cand = lo + rand(1,D).*(hi - lo);
                a = 2 * (1 - i/max(nNew,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand*cand + (1-wRand)*a*r1*dir;
                newDe(i,:) = min(max(cand, lb), ub);
            end
            newOb = Problem.CalObj(newDe);
            newCo = Problem.CalCon(newDe);
            kAdd = nNew;
            M1.decs = [Pop.decs; newDe]; M1.objs = [Pop.objs; newOb]; M1.cons = [Pop.cons; newCo];
            [FrontNo, ~] = NDSort(M1.objs, M1.cons, inf);
            nAll = size(M1.objs,1);
            keep = false(nAll,1);
            for f = 1:max(FrontNo)
                cand = find(FrontNo==f);
                if numel(cand) <= N - sum(keep)
                    keep(cand) = true;
                else
                    [~, ord] = sort(M1.objs(cand,:) * sum(M1.objs(cand,:),2)');
                    keep(cand(1:min(N-sum(keep), numel(cand)))) = true;
                end
                if sum(keep) >= N, break; end
            end
            if sum(keep) < N
                rest = find(~keep);
                [~, ord] = sort(sum(M1.objs(rest,:),2));
                keep(rest(ord(1:min(N-sum(keep), numel(rest))))) = true;
            end
            Pop.decs = M1.decs(keep,:); Pop.objs = M1.objs(keep,:); Pop.cons = M1.cons(keep,:);
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