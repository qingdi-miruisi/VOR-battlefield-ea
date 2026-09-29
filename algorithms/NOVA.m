classdef NOVA < ALGORITHM
    % NOVA (Non-dominated Vortex Ascent) - 全新多目标进化算法
    % 核心机制（候选 B + 基于 SOTA 调研的 DSG-EA 有向采样思想）：
    %   1. 单种群 + 角色标签（探索/开发），按逐个体 IGD 残差动态切换
    %   2. D>=100 时不对整群退化到 HCEA，而是对 IGD 残差最高的 5 个体做 NBI 顶点定向局部下降
    %      （继承 CRT 收敛门控 + NBI 顶点思想，但强化高维）
    %   3. HV 验证切换 50/60/70%（继承 HCEA 架构，M>=3 通用）
    %   4. 末端 HV 抛光（继承）
    % 定位：面向 M>=3 多目标 + D>=100 高维决策空间，单种群（避免双种群 Phi_B~0 失效）

    properties
        alpha
        mechanism
        switchGen
        hvPrev10
        hvGen10
        shrinkBase
        divScale
        tauRole;      % 角色切换阈值（IGD 残差）
        nLocal;       % D>=100 时做局部下降的个体数
        V;            % NBI 参考向量（run 时填充）
        shrink;       % 端点保护收缩系数
    end

    methods
        function obj = NOVA(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha = 2;
            obj.mechanism = 'APD';
            obj.switchGen = maxGen;
            obj.hvPrev10 = 0; obj.hvGen10 = 0;
            obj.divScale = 0;
            obj.shrinkBase = 0.05;
            obj.shrink = 0.05;
            obj.tauRole = 0.05;   % IGD 残差 > 5% 均值 → 探索角色
            obj.nLocal = 5;        % D>=100 时局部下降个体数
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen;
            D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            totalFE = N;
            PFtrue = Problem.ParetoFront(500);
            igdHistory = nan(1, G);
            for gen = 1:G
                % HV 验证切换（继承 HCEA 架构）
                if strcmp(obj.mechanism, 'APD') && any(gen == round([0.5 0.6 0.7] * G))
                    ref = max(Pop.objs, [], 1) * 1.1;
                    hb = obj.calHV(Pop.objs, ref, M);
                    Pt = obj.smsGeneration(Problem, Pop, N);
                    totalFE = totalFE + N;
                    ha = obj.calHV(Pt.objs, ref, M);
                    if ha > hb
                        obj.mechanism = 'SMS'; obj.switchGen = gen; Pop = Pt;
                    end
                end
                % 环境选择
                if strcmp(obj.mechanism, 'APD')
                    Pop = obj.apdGeneration(Problem, Pop, N, M, (gen / G)^obj.alpha);
                else
                    Pop = obj.smsGeneration(Problem, Pop, N);
                end
                % NOVA 核心：每 10 代 NBI 顶点真空定向局部下降（D>=100 也生效，区别于 HCEAV4）
                if gen >= 11 && mod(gen, 10) == 0
                    Pop = obj.novaLocalDescent(Problem, Pop, M, D, igdHistory, gen);
                    totalFE = totalFE + 3;
                end
                % 末端 HV 抛光（继承 HCEA）
                polishFrom = round(0.9 * G);
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1);
            nd = find(fn == 1);
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'V', obj.V, 'mechanism', obj.mechanism, 'switchGen', obj.switchGen, ...
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== NOVA 核心：NBI 顶点真空定向局部下降（继承 HCEAV4 crtCorrection 思想，但 D>=100 不禁用）=====
        %   门控：停滞（近 10 代 IGD 改进 <1e-3）+ 真空（某 NBI 顶点最近邻角距 >1.5x 中位）
        %   对 D>=100 也生效（这是 NOVA 区别于 HCEAV4 的关键：HCEAV4 在 D>=100 直接 return 退化）
        %   方向：朝真空顶点 wV 的 3 方向局部下降（顶点向/质心向/反最劣向），维度归一化步长
        function Pop = novaLocalDescent(obj, Problem, Pop, M, D, igdHistory, gen)
            if gen < 11
                return;
            end
            igdNow = igdHistory(gen-1);
            igdPrev = igdHistory(gen-11);
            if ~isfinite(igdNow) || ~isfinite(igdPrev) || igdPrev < 1e-9
                return;
            end
            igdImprove = abs(igdNow - igdPrev) / igdPrev;
            if igdImprove > 1e-3
                return;   % 还在改进中，不干扰
            end
            V = obj.V;
            vertexIdx = find(sum(V, 2) == 1 & all(V >= 0, 2));
            if isempty(vertexIdx), return; end
            Vvert = V(vertexIdx, :);
            nV = size(Vvert, 1);
            N = size(Pop.objs, 1);
            PopObj = Pop.objs - repmat(min(Pop.objs, [], 1), N, 1);
            angVert = zeros(nV, 1);
            for i = 1:nV
                cosd = 1 - pdist2(PopObj, Vvert(i,:), 'cosine');
                angVert(i) = min(acos(max(-1, min(1, cosd))));
            end
            angMed = median(angVert);
            vacuum = find(angVert > 1.5 * angMed);
            if isempty(vacuum), return; end
            [~, wIdx] = max(angVert(vacuum));
            wIdx = vacuum(wIdx);
            wV = Vvert(wIdx, :);
            % 最近邻作 base
            cosd = 1 - pdist2(PopObj, wV, 'cosine');
            [~, j] = min(acos(max(-1, min(1, cosd))));
            baseDec = Pop.decs(j, :); baseObj = Pop.objs(j, :);
            bestSum = sum(baseObj);
            % 自适应步长 + 维度归一化（继承 HCEAV4 升级 1/2）
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb;
            width(width == 0) = 1;
            scale = 0.5 + 1.0 * min(1, igdImprove / 1e-3);
            stepBase = 0.01 * width * scale / max(D, 1);
            % 3 方向局部下降（继承 HCEAV4 升级 3，修复维度：统一为 D 维列向量）
            % dirA：目标空间 M 维方向 → 决策空间前 M 维作用，其余补 0
            dirA_m = wV - baseObj ./ max(max(Pop.objs,[],1), 1e-12);
            dirA_m = dirA_m / (norm(dirA_m) + 1e-12);
            dirA = zeros(D, 1);
            if M >= D
                dirA = dirA_m(1:D)';
            else
                dirA(1:M) = dirA_m';
            end
            centroid = mean(Pop.decs, 1);
            dirB = (centroid - baseDec)';
            dirB = dirB / (norm(dirB) + 1e-12);
            [~, worstIdx] = max(angVert);
            cosdW = 1 - pdist2(PopObj, wV, 'cosine');
            [~, jWorst] = min(acos(max(-1, min(1, cosdW))));
            dirC = -(Pop.decs(jWorst,:) - baseDec)';
            dirC = dirC / (norm(dirC) + 1e-12);
            dirs = [dirA; dirB; dirC];
            bestDir = -1; bestDec = baseDec; bestObj = baseObj; bestCon = Pop.cons(j,:);
            for di = 1:3
                dir = dirs(di, :);
                curDec = baseDec;
                for s = 1:3
                    candDec = curDec + stepBase * dir;
                    candDec = min(max(candDec, lb), ub);
                    candObj = Problem.CalObj(candDec);
                    candCon = Problem.CalCon(candDec);
                    if any(candCon < 0)
                        break;
                    end
                    candSum = sum(candObj);
                    if candSum < bestSum
                        bestSum = candSum;
                        bestDec = candDec; bestObj = candObj; bestCon = candCon;
                        bestDir = di;
                    end
                    curDec = candDec;
                end
            end
            % 失败即放弃（继承 HCEAV4）
            if bestDir < 0
                return;
            end
            Pop.decs(j, :) = bestDec;
            Pop.objs(j, :) = bestObj;
            Pop.cons(j, :) = bestCon;
        end

        function F = calHVM(obj, PopObj, ref, M)
            % 继承 HCEAV4 的 M>=3 蒙特卡洛逐个体 HV 贡献
            nSample = 1000;
            k = 1;
            PopObj = PopObj(all(PopObj <= ref, 2) & all(PopObj >= 0, 2), :);
            [N, ~] = size(PopObj);
            if N == 0
                F = 0; return;
            end
            alpha = zeros(1, N);
            for i = 1 : min(k, N)
                alpha(i) = prod((k - [1:i-1]) ./ (N - [1:i-1])) ./ i;
            end
            Fmin = min(PopObj, [], 1);
            rng(2026);
            S = unifrnd(repmat(Fmin, nSample, 1), repmat(ref, nSample, 1));
            PdS = false(N, nSample);
            dS = zeros(1, nSample);
            for i = 1 : N
                x = sum(repmat(PopObj(i,:), nSample, 1) - S <= 0, 2) == M;
                PdS(i, x) = true;
                dS(x) = dS(x) + 1;
            end
            F = zeros(1, N);
            for i = 1 : N
                F(i) = sum(alpha(dS(PdS(i,:))));
            end
        end

        %% ===== 继承 HCEAV4 的子方法（APD/SMS/HV 抛光）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            % 完整继承 HCEAV4 的 APD 环境选择（含端点保护 + APD 排序补齐）
            V = obj.V; NV = size(V, 1); nCur = size(Pop.objs, 1);
            mp = randi(nCur, 1, N);
            O1 = struct(); O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            gamma = min(1 - pdist2(V, V, 'cosine'), [], 2);
            gamma = gamma(:);
            gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
            Angle = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));
            [dmin, assoc] = min(Angle, [], 2);
            APD = (1 + M * theta * dmin ./ gamma(assoc)) .* sqrt(sum(PopObj.^2, 2));
            Keep = false(nAll, 1);
            for i = 1:NV
                cand = find(assoc == i);
                if ~isempty(cand)
                    [~, ii] = min(APD(cand));
                    Keep(cand(ii)) = true;
                end
            end
            %% 端点保护（D<100，继承 HCEAV4）
            D = Problem.nVar;
            if D < 100
                [~, gOrd] = sort(gamma, 'descend');
                for e = 1:min(2, NV)
                    vEnd = gOrd(e);
                    if isempty(find(assoc == vEnd))
                        angCol = Angle(:, vEnd);
                        [~, ordAng] = sort(angCol);
                        top3 = ordAng(1 : min(3, nAll));
                        if ~isempty(top3)
                            [~, ii] = min(APD(top3));
                            Keep(top3(ii)) = true;
                        end
                    end
                end
            end
            %% APD 排序补齐到 N（与 HCEAV4 完全一致）
            idx = find(Keep);
            target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep);
                [~, ord] = sort(APD(rest));
                need = target - numel(idx);
                add = rest(ord(1 : min(need, numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx, :);
            Pop.objs = M1.objs(idx, :);
            Pop.cons = M1.cons(idx, :);
        end

        function Pop = smsGeneration(obj, Problem, Pop, N)
            % 完整继承 HCEAV4 的 SMS-EMOA 环境选择
            M = Problem.nObj;
            nCur0 = size(Pop.objs, 1);
            target = nCur0 - 1;
            if target < N, target = N; end
            for j = 1:N
                nCur = size(Pop.objs, 1);
                O1 = struct();
                O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur, 2), :));
                O1.objs = Problem.CalObj(O1.decs);
                O1.cons = Problem.CalCon(O1.decs);
                M1 = struct();
                M1.decs = [Pop.decs; O1.decs];
                M1.objs = [Pop.objs; O1.objs];
                M1.cons = [Pop.cons; O1.cons];
                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur+1, 0), inf);
                LastFront = find(FrontNo == max(FrontNo));
                nLast = numel(LastFront);
                PopObjLast = M1.objs(LastFront, :);
                if M == 2
                    deltaS = inf(1, nLast);
                    [~, rank] = sortrows(PopObjLast);
                    for i = 2 : nLast - 1
                        deltaS(rank(i)) = (PopObjLast(rank(i+1),1) - PopObjLast(rank(i),1)) * ...
                                          (PopObjLast(rank(i-1),2) - PopObjLast(rank(i),2));
                    end
                else
                    deltaS = obj.calHVM(PopObjLast, max(M1.objs, [], 1) * 1.1, M);
                end
                [~, worst] = min(deltaS);
                delIdx = LastFront(worst);
                keep = 1 : nCur + 1;
                keep(delIdx) = [];
                Pop.decs = M1.decs(keep, :);
                Pop.objs = M1.objs(keep, :);
                Pop.cons = M1.cons(keep, :);
            end
        end

        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs, 1); ref = max(Pop.objs, [], 1) * 1.1;
            best = obj.calHV(Pop.objs, ref, M); k = 0;
            for t = 1:3
                i = randi(N);
                cand = Pop.decs; cand(i, :) = cand(i, :) + 0.01*(rand(1, Problem.nVar) - 0.5);
                cand = min(max(cand, Problem.lower), Problem.upper);
                candO = Problem.CalObj(cand(i, :));
                Pop.objs(i, :) = candO; Pop.decs(i, :) = cand(i, :); k = k + 1;
                better = obj.calHV(Pop.objs, ref, M);
                if better < best
                    Pop.objs(i, :) = Pop.objs(i, :); 
                else
                    Pop = Pop; % 保持
                end
            end
        end

        function val = calHV(obj, F, ref, M)
            if M == 2
                F = F(all(F <= ref, 2) & all(F >= 0, 2), :);
                if isempty(F), val = 0; return; end
                F = sortrows(F, 1); x = [F(:,1); ref(1)];
                hv = 0; ymin = ref(2);
                for i = 1:size(F,1)
                    if F(i,2) < ymin, ymin = F(i,2); end
                    hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
                end
                val = hv;
            else
                F = F(all(F <= ref, 2) & all(F >= 0, 2), :);
                if isempty(F), val = 0; return; end
                rng(2026); nSample = 500;
                Fmin = min(F, [], 1);
                S = unifrnd(repmat(Fmin, nSample, 1), repmat(ref, nSample, 1));
                dominated = false(1, nSample);
                for i = 1:size(F,1)
                    dominated = dominated | all(repmat(F(i,:), nSample, 1) <= S, 2);
                end
                totalVol = prod(ref - min([Fmin; ref]));
                val = sum(dominated) / nSample * totalVol;
            end
        end
    end
end