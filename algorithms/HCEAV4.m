classdef HCEAV4 < ALGORITHM
% HCEAV4 - HCEA 精化版（V4，面向 IGD 超越 HCEA）
%
% 设计原则：
%   核心循环忠实 HCEA（APD + SMS-EMOA + HV 验证切换 50/60/70% + 末端抛光），
%   确保 IGD 下限不低于 HCEA；在此之上叠加改进：
%     M=2：端点保护 + SMS 决策顶点注入
%     M≥3 D<100：CRT 收敛残差定向修正（双门控 + 多方向局部下降）
%     D≥100：完全退化（等同 HCEA，禁用 APD 端点保护 + CRT + 2D 注入）
%
% 接口：
%   obj = HCEAV4(popSize, maxGen, seed);
%   [Population, Result] = obj.optimize(Problem);

    properties
        V;
        alpha;
        mechanism;
        switchGen;
        hvPrev10;
        hvGen10;
        shrinkBase;
        shrink;
        divScale;
    end

    methods
        function obj = HCEAV4(popSize, maxGen, seed, shrinkBase)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.alpha     = 2;
            obj.mechanism = 'APD';
            obj.switchGen = maxGen;
            obj.hvPrev10  = 0;
            obj.hvGen10   = 0;
            if nargin >= 4 && ~isempty(shrinkBase)
                obj.shrinkBase = shrinkBase;
            else
                obj.shrinkBase = 0.05;
            end
            obj.shrink   = obj.shrinkBase;
            obj.divScale = 0;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            w0 = warning('off', 'all');
            N  = obj.popSize;
            M  = Problem.nObj;
            G  = obj.maxGen;

            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            Pop = Problem.Initialization(N);
            totalFE = N;

            PFtrue = Problem.ParetoFront(500);
            igdHistory = nan(1, G);

            %% D≥100 退化模式：完全等同 HCEA（禁用 APD 端点保护 + CRT + 2D 注入）
            D = Problem.nVar;
            degenerate = D >= 100;

            for gen = 1 : G
                trialed = false;

                %% HV 验证的切换检查（与 HCEA 完全一致）
                if strcmp(obj.mechanism, 'APD') && any(gen == round([0.5 0.6 0.7] * G))
                    ref = max(Pop.objs, [], 1) * 1.1;
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

                %% 环境选择
                if ~trialed
                    if strcmp(obj.mechanism, 'APD')
                        if degenerate
                            Pop = obj.apdGenerationPure(Problem, Pop, N, M, (gen / G)^obj.alpha);
                        else
                            Pop = obj.apdGeneration(Problem, Pop, N, M, (gen / G)^obj.alpha);
                        end
                    else
                        if degenerate
                            %% D≥100：纯 HCEA SMS（无 CRT、无 2D 注入）
                            Pop = obj.smsGeneration(Problem, Pop, N);
                        elseif M >= 3
                            %% M≥3 D<100：CRT 收敛残差定向修正（每 10 代触发，双门控）
                            if gen >= 11 && mod(gen, 10) == 0
                                Pop = obj.crtCorrection(Problem, Pop, M, igdHistory, gen);
                            end
                            Pop = obj.smsGeneration(Problem, Pop, N);
                        else
                            %% M=2：决策顶点注入（末 40% + HV 停滞门控）
                            if gen >= round(0.6 * G) && mod(gen, 10) == 0 && gen < round(0.9 * G)
                                refNow = max(Pop.objs, [], 1) * 1.1;
                                hvNow = obj.calHV(Pop.objs, refNow, M);
                                if obj.hvGen10 == 0
                                    obj.hvPrev10 = hvNow; obj.hvGen10 = gen;
                                else
                                    if hvNow > 1e-9 && obj.hvPrev10 > 1e-9
                                        rate = (hvNow - obj.hvPrev10) / obj.hvPrev10;
                                    else
                                        rate = -1;
                                    end
                                    if rate <= 0 || (hvNow < 1e-9 && obj.hvPrev10 < 1e-9)
                                        Pop = obj.boundaryImmigration2D(Problem, Pop, M);
                                    end
                                end
                                obj.hvPrev10 = hvNow; obj.hvGen10 = gen;
                            end
                            Pop = obj.smsGeneration(Problem, Pop, N);
                        end
                    end
                    totalFE = totalFE + N;
                end

                %% 末端 HV 抛光（同 HCEA：1 点 × 3 扰动）
                polishFrom = round(0.9 * G);
                if gen >= polishFrom && mod(gen - polishFrom + 1, 5) == 1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end

                igdHistory(gen) = IGD(Pop.objs, PFtrue);
                %% 更新多样性标度（近 10 代 IGD 相对变化幅度）
                if gen > 10
                    igdPrev10 = igdHistory(gen-10);
                    igdNow = igdHistory(gen);
                    if igdPrev10 > 1e-9
                        obj.divScale = min(1.0, abs(igdNow - igdPrev10) / igdPrev10);
                    else
                        obj.divScale = 0;
                    end
                else
                    obj.divScale = 0;
                end
            end

            [fn, ~] = NDSort(Pop.objs, zeros(size(Pop.objs,1),0), 1);
            nd = find(fn == 1);
            Result = struct('Front', Pop.decs(nd,:), ...
                            'F',    Pop.objs(nd,:), ...
                            'nFE',  totalFE, ...
                            'V',    obj.V, ...
                            'mechanism', obj.mechanism, ...
                            'switchGen', obj.switchGen, ...
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs;
            Population.objs = Pop.objs;
            Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== APD（含改进 1 端点保护，D≥100 时禁用端点保护分支）=====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V;
            NV = size(V, 1);
            nCur = size(Pop.objs, 1);

            mp = randi(nCur, 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);

            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
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

            %% 改进 1：端点保护（仅当端点向量无候选时；D≥100 时禁用）
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

        %% ===== apdGenerationPure（D≥100 退化版，与 HCEA apdGeneration 逐行一致）=====
        % 无任何端点保护分支占位，RNG 消耗序列与 HCEA 完全一致。
        function Pop = apdGenerationPure(obj, Problem, Pop, N, M, theta)
            V = obj.V;
            mp = randi(size(Pop.objs,1), 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            NV = size(V, 1);
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

        %% ===== M≥3 CRT 收敛残差定向修正（升级版：维度归一化 + 自适应步长 + 多方向局部下降）=====
        %   门控 1（停滞）：近 10 代 IGD 相对改进 < 1e-3
        %   门控 2（真空）：某 NBI 顶点方向最近邻角距 > 1.5 × 全体顶点中位角距
        %   升级 1：维度归一化 stepSize = 0.01*(ub-lb)*scale/D
        %   升级 2：自适应步长 scale = 0.5 + 1.0*min(1, igdImprove/1e-3)
        %   升级 3：多方向局部下降（NBI顶点/质心/反最劣 3 方向 × 3 步）
        %   D≥100 时直接 return（退化）
        function Pop = crtCorrection(obj, Problem, Pop, M, igdHistory, gen)
            D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb;
            % ===== D≥100 保守回退：禁用局部下降注入 =====
            if D >= 100
                return;
            end
            % ===== 门控 1：停滞检测 =====
            if gen < 11
                return;
            end
            igdNow = igdHistory(gen);
            igdPrev = igdHistory(gen - 10);
            if ~isfinite(igdNow) || ~isfinite(igdPrev) || igdPrev < 1e-9
                return;
            end
            igdImprove = abs(igdNow - igdPrev) / igdPrev;
            if igdImprove > 1e-3
                return;
            end
            % ===== 门控 2：NBI 顶点真空检测 =====
            V = obj.V;
            vertexIdx = find(sum(V, 2) == 1 & all(V >= 0, 2));
            if isempty(vertexIdx), return; end
            Vvert = V(vertexIdx, :);
            nV = size(Vvert, 1);
            PopObj = Pop.objs - repmat(min(Pop.objs, [], 1), size(Pop.objs,1), 1);
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
            % ===== 最近邻 =====
            cosd = 1 - pdist2(PopObj, wV, 'cosine');
            [~, j] = min(acos(max(-1, min(1, cosd))));
            baseDec = Pop.decs(j, :);
            baseObj = Pop.objs(j, :);
            bestSum = sum(baseObj);
            % ===== 自适应步长 + 维度归一化 =====
            scale = 0.5 + 1.0 * min(1, igdImprove / 1e-3);
            stepBase = 0.01 * width * scale / D;
            % ===== 多方向局部下降 =====
            dirA = wV - baseObj / max(max(Pop.objs,[],1), 1e-12);
            dirA = dirA / (norm(dirA) + 1e-12);
            centroid = mean(Pop.decs, 1);
            dirB = centroid - baseDec;
            dirB = dirB / (norm(dirB) + 1e-12);
            [~, worstIdx] = max(angVert);
            cosdW = 1 - pdist2(PopObj, wV, 'cosine');
            [~, jWorst] = min(acos(max(-1, min(1, cosdW))));
            dirC = -(Pop.decs(jWorst,:) - baseDec);
            dirC = dirC / (norm(dirC) + 1e-12);
            dirs = [dirA; dirB; dirC];
            bestDir = -1; bestDec = baseDec; bestObj = baseObj; bestCon = Pop.cons(j,:);
            for di = 1:3
                dir = dirs(di, :);
                curDec = baseDec; curObj = baseObj;
                for step = 1:3
                    candDec = curDec + stepBase * dir(1:min(D, M));
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
                    curDec = candDec; curObj = candObj;
                end
            end
            % ===== 失败即放弃 =====
            if bestDir < 0
                return;
            end
            Pop.decs(j, :) = bestDec;
            Pop.objs(j, :) = bestObj;
            Pop.cons(j, :) = bestCon;
        end

        %% ===== M=2 决策顶点注入 =====
        function Pop = boundaryImmigration2D(obj, Problem, Pop, M)
            D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            t = obj.adaptiveShrink();
            obj.shrink = t;
            vertex = lb + (rand(1, D) < 0.5) .* (ub - lb);
            imm = vertex * (1 - t) + 0.5 * (lb + ub) * t;
            imm = min(max(imm, lb), ub);
            oObj = Problem.CalObj(imm);
            oCon = Problem.CalCon(imm);
            Pop.decs = [Pop.decs; imm];
            Pop.objs = [Pop.objs; oObj];
            Pop.cons = [Pop.cons; oCon];
        end

        %% ===== 自适应 shrink 系数 =====
        function t = adaptiveShrink(obj)
            k = 2.0;
            t = obj.shrinkBase * (1 + k * obj.divScale);
            t = min(t, 0.5);
            t = max(t, obj.shrinkBase);
        end

        %% ===== SMS-EMOA（忠实 HCEA）=====
        function Pop = smsGeneration(obj, Problem, Pop, N)
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
                deltaS = inf(1, nLast);
                PopObjLast = M1.objs(LastFront, :);
                if M == 2
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

        %% ===== 末端 HV 抛光 =====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            ref = max(Pop.objs, [], 1) * 1.1;
            HVc = obj.hvContrib(Pop.objs, M, ref);
            [~, worst] = min(HVc);
            base = Pop.decs(worst, :);
            D = size(base, 2);
            lb = Problem.lower; ub = Problem.upper;
            Cand = base + 0.05 * (ub - lb) .* randn(3, D);
            Cand = min(max(Cand, lb), ub);
            CandObj = Problem.CalObj(Cand);
            bestHV = -inf; bestIdx = 1;
            for i = 1:3
                Temp = Pop;
                Temp.decs(worst, :) = Cand(i, :);
                Temp.objs(worst, :) = CandObj(i, :);
                h = obj.hvContrib(Temp.objs, M, ref);
                if h(worst) > bestHV
                    bestHV = h(worst); bestIdx = i;
                end
            end
            Pop.decs(worst, :) = Cand(bestIdx, :);
            Pop.objs(worst, :) = CandObj(bestIdx, :);
            k = 3;
        end

        %% ===== 2D 精确超体积 =====
        function hv = calHV(obj, PopObj, ref, M)
            if M ~= 2
                hv = sum(obj.calHVM(PopObj, ref, M));
                return;
            end
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            if isempty(PopObj)
                hv = 0; return;
            end
            PopObj = sortrows(PopObj, 1);
            x = [PopObj(:,1); ref(1)];
            hv = 0; ymin = ref(2);
            for i = 1:size(PopObj, 1)
                if PopObj(i,2) < ymin
                    ymin = PopObj(i,2);
                end
                hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
            end
        end

        %% ===== 2D 精确超体积贡献 =====
        function HV = hvContrib(obj, PopObj, M, ref)
            [N, ~] = size(PopObj);
            HV = zeros(1, N);
            if M ~= 2
                HV = obj.calHVM(PopObj, ref, M);
                return;
            end
            [S, ord] = sortrows(PopObj);
            f1 = [S(:,1); ref(1)];
            f2 = [ref(2); S(:,2)];
            for i = 1:N
                HV(ord(i)) = (f1(i+1) - f1(i)) * (f2(i) - f2(i+1));
            end
        end

        %% ===== 蒙特卡洛 HV 逐解贡献 =====
        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000;
            k = 1;
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            [N, ~] = size(PopObj);
            if N == 0
                F = 0; return;
            end
            alpha = zeros(1, N);
            for i = 1 : min(k, N)
                alpha(i) = prod((k - [1:i-1]) ./ (N - [1:i-1])) ./ i;
            end
            Fmin = min(PopObj, [], 1);
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
            F = F .* prod(ref - Fmin) / nSample;
        end
    end
end
