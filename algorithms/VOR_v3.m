classdef VOR_v3 < ALGORITHM
% VOR_v3 - SSV-driven Online Resource Scheduling framework for MOEA
%
% 设计（VOR-v2 的 7 机制统一重构，第三轮修订版 2026-09-30）：
%
%   (1) 搜索状态向量 SSV = [s_conv, s_div, s_feas_eff, s_scale] ∈ [0,1]^4
%       s_conv  = 1 - IGD_t/IGD_0（clip 到 [0,1]；IGD_0<1e-9 时 s_conv=1）
%       s_div   = 1 - PPS_t/N（front-1 塌方程度）
%       s_feas  = 1 - feasible_count/N（约束题）；无约束题 = 0
%       s_feas_eff = max(s_feas, 0.5*hasCon)
%       s_scale = min(1, D/300)
%
%   (2) 资源权重 W ∈ R^4（每代更新，ΣW=1）
%       a = baseW + SSV * phi'  (4×1)
%       g = stageGains(τ)
%       W = max(0,a) ⊙ g / Σ
%
%   (3) 主算子槽资格制：
%       large-scale (s_scale≥0.33) / feasibility (hasCon) / convergence (simpleState)
%       GDV：s_scale≥0.33 && gen≥30 && igdStagn≥20 && s_conv<0.9 && ~ppsRecover
%       PPS floor：D≥100 前代 PPS<0.8N 时强制 Q-EPS+SBX + ORA/CBIM 恢复
%       CF1 部分 SMS：hasCon && s_scale<0.33 && gen≥0.5G && IGD≥0.02
%                     前 50% SMS 精修 + Q-EPS+SBX 恢复多样性
%
%   (4) 辅助槽（门控与 v2 对齐）：
%       GDV：s_scale≥0.33 && gen≥30 && igdStagn≥20 && s_conv<0.9 && ~ppsRecover
%       CBIM：~simpleState && gen≥30 && 5≤igdStagn<10 && s_div>0.3 && s_conv<0.9
%       ORA：~simpleState && gen≥30 && mod(gen,10)==0 && igdStagn≥3
%             || (D≥100 && ppsRecover && mod(gen,10)==0)
%       polish：hasCon from 0.75G 每 4 代；无约束 from 0.9G 每 5 代（3 FE/次）
%
% 与 VOR-v2 触发逻辑等价对照见 results/ssv_design.md §5。

    properties
        %% SSV 分量与派生量
        sConv; sDiv; sFeas; sFeasEff; sScale;
        sHard; igd0;
        sconvStagn; sConvPrev; sconvStagn3;
        igdStagn;         % v2 对齐的 IGD 10 代窗口停滞计数
        ppsHist;          % 每代 front-1 计数（PPS floor 兜底）
        %% 资源权重
        W; phi; baseW;
        WHist; SSVHist; MainHist; OpHist;
        %% 继承 VOR-v2 的状态
        V; cluster; clusterDir; K;
        GDV; LpopDec; LpopObj; Lcenter; Lidx; Lrd; GDVK;
        hasCon;
        igdHistory;
        pfTrue;
    end

    methods
        function obj = VOR_v3(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.sConv = 0; obj.sDiv = 1; obj.sFeas = 0; obj.sFeasEff = 0; obj.sScale = 0;
            obj.sHard = 0; obj.igd0 = 0; obj.sconvStagn = 0; obj.sConvPrev = 0;
            obj.sconvStagn3 = 0; obj.igdStagn = 0; obj.ppsHist = 0;
            obj.W = [0.25, 0.25, 0.25, 0.25];
            obj.phi = [  0, -0.5, 0,   0;
                       -0.5,  1,  0,  0;
                        0,   0,  2,  0;
                        0,   0,  0, 1.5];
            obj.baseW = [1.0; 0.0; 0.0; 0.0];
            obj.WHist = []; obj.SSVHist = []; obj.MainHist = []; obj.OpHist = [];
            obj.V = []; obj.cluster = []; obj.clusterDir = [];
            obj.K = max(3, ceil(popSize/20));
            obj.GDV = []; obj.LpopDec = []; obj.LpopObj = [];
            obj.Lcenter = []; obj.Lidx = []; obj.Lrd = []; obj.GDVK = 5;
            obj.hasCon = false;
            obj.igdHistory = []; obj.pfTrue = [];
        end

        %% ===== 主循环（SSV → W → 主算子槽 + 辅助槽） =====
        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen;
            D = Problem.nVar;
            obj.sScale = min(1, D/300);

            % 约束检测：与 v2 完全对齐（size(c0,2)>0 即判 hasCon）
            obj.hasCon = false;
            try
                X0 = Problem.Initialization(1).decs;
                c0 = Problem.CalCon(X0);
                if ~isempty(c0) && size(c0,2) > 0, obj.hasCon = true; end
            catch
            end

            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            obj.pfTrue = Problem.ParetoFront(500);

            Pop = Problem.Initialization(N); totalFE = N;
            igd0 = IGD(Pop.objs, obj.pfTrue);
            obj.igd0 = igd0;
            obj.sHard = min(1, igd0/30);
            obj.igdHistory = igd0;
            obj.WHist = zeros(G, 4); obj.SSVHist = zeros(G, 4);
            obj.MainHist = zeros(G, 1); obj.OpHist = zeros(G, 1);
            [fn0, ~] = NDSort(Pop.objs, Pop.cons, 1);
            obj.ppsHist = sum(fn0 == 1);   % ppsHist(1) = 初始种群 front-1 数

            for gen = 1:G
                tau = gen / G;
                %% ---- SSV 在线估计 ----
                igdNow = IGD(Pop.objs, obj.pfTrue);
                obj.igdHistory(end+1) = igdNow;
                if obj.igd0 > 1e-9
                    obj.sConv = max(0, min(1, 1 - igdNow/obj.igd0));
                else
                    obj.sConv = 1;
                end
                [fn, ~] = NDSort(Pop.objs, Pop.cons, 1);
                PPS = sum(fn == 1);
                obj.ppsHist(end+1) = PPS;
                obj.sDiv = 1 - PPS/N;
                if obj.hasCon
                    feas = sum(all(Pop.cons <= 0, 2))/N;
                    obj.sFeas = 1 - feas;
                else
                    obj.sFeas = 0;
                end
                obj.sFeasEff = max(obj.sFeas, 0.5*obj.hasCon);

                if abs(obj.sConv - obj.sConvPrev) < 0.01
                    obj.sconvStagn = obj.sconvStagn + 1;
                else
                    obj.sconvStagn = 0;
                end
                obj.sConvPrev = obj.sConv;
                obj.sconvStagn3 = obj.sconvStagn >= 3;

                SSV = [obj.sConv, obj.sDiv, obj.sFeasEff, obj.sScale];

                %% ---- W 在线更新 ----
                a = obj.baseW + (SSV * obj.phi').';
                g = obj.stageGains(tau);
                w = max(0, a) .* g;
                if sum(w) < 1e-12, w = [1,0,0,0]; end
                obj.W = w / sum(w);
                obj.WHist(gen, :) = obj.W;
                obj.SSVHist(gen, :) = SSV;

                %% ---- 门控 ----
                simpleState = (obj.sScale < 0.33) && (obj.sFeasEff <= 0);
                feasElig = obj.hasCon;
                lsElig = obj.sScale >= 0.33;
                dsgElig = (obj.sScale >= 0.33 && obj.sHard >= 0.5) || ...
                          (obj.hasCon && obj.sScale >= 0.1 && obj.sScale < 0.33);

                % PPS floor 兜底：前代 PPS<0.8N 时触发恢复
                % CF1 型约束低维题（s_scale 0.1-0.33）也触发（PPS 51 vs 目标 52）
                if gen >= 2
                    PPSprev = obj.ppsHist(end-1);
                    ppsRecover = (obj.sScale >= 0.1) && (PPSprev < 0.8*N);
                else
                    ppsRecover = false; PPSprev = N;
                end

                % GDV：对齐 v2（stagn≥20 + s_conv<0.9 + s_scale≥0.33）
                % PPS 恢复代禁用 GDV
                gdvActive = (obj.sScale >= 0.33) && (gen >= 30) && ...
                            (obj.igdStagn >= 20) && (obj.sConv < 0.9) && ~ppsRecover;
                cbimActive = (~simpleState) && (gen >= 30) && (obj.igdStagn >= 5) && ...
                              (obj.igdStagn < 10) && (obj.sDiv > 0.3) && ...
                              (obj.sConv < 0.9) && ~isempty(obj.clusterDir);
                oraActive = (~simpleState) && (gen >= 30) && mod(gen,10)==0 && ...
                            obj.igdStagn >= 3;
                % PPS 恢复代强制激活 ORA/CBIM（恢复分布）
                oraActive = oraActive || (obj.sScale >= 0.33 && ppsRecover && gen >= 30 && mod(gen,10)==0);
                cbimActive = cbimActive || (obj.sScale >= 0.33 && ppsRecover && gen >= 30 && ~isempty(obj.clusterDir));

                % 与 v2 完全对齐的 IGD 停滞计数（10 代窗口相对改善 <1e-3）
                if gen >= 11
                    igdNowH = obj.igdHistory(end); igdPrevH = obj.igdHistory(end-10);
                    if ~isfinite(igdNowH) || ~isfinite(igdPrevH) || igdPrevH < 1e-9
                        obj.igdStagn = 0;
                    else
                        relImp = abs(igdNowH - igdPrevH)/igdPrevH;
                        if relImp < 1e-3
                            obj.igdStagn = obj.igdStagn + 1;
                        else
                            obj.igdStagn = 0;
                        end
                    end
                else
                    obj.igdStagn = 0;
                end

                %% ---- 主算子槽（N FE；策略竞争 + 资格制） ----
                if lsElig
                    mainStrat = 3;
                elseif feasElig && (obj.W(3) >= obj.W(1) || ~simpleState)
                    mainStrat = 2;
                else
                    mainStrat = 1;
                end
                obj.MainHist(gen) = mainStrat;
                if mainStrat == 1
                    if gen >= round(0.5*G) && obj.sConv >= 0.5
                        Pop = obj.smsGeneration(Problem, Pop, N);
                        obj.OpHist(gen) = 2;
                    else
                        theta = tau^2;
                        Pop = obj.apdGeneration(Problem, Pop, N, M, theta);
                        obj.OpHist(gen) = 1;
                    end
                    totalFE = totalFE + N;
                else
                    if ppsRecover
                        Pop = obj.qepsGeneration(Problem, Pop, N, M, 'SBX');
                        obj.OpHist(gen) = 3;
                    elseif obj.hasCon && obj.sScale < 0.33 && ~dsgElig && ~gdvActive && ...
                        gen >= round(0.5*G) && obj.igdHistory(end) >= 0.02
                        halfN = max(2, round(N/2));
                        Pop = obj.smsGeneration(Problem, Pop, halfN);
                        Pop = obj.qepsGeneration(Problem, Pop, N, M, 'SBX');
                        obj.OpHist(gen) = 2;
                    elseif gdvActive
                        Pop = obj.qepsGeneration(Problem, Pop, N, M, 'GDV');
                        obj.OpHist(gen) = 5;
                    elseif dsgElig
                        Pop = obj.qepsGeneration(Problem, Pop, N, M, 'DSG');
                        obj.OpHist(gen) = 4;
                    else
                        Pop = obj.qepsGeneration(Problem, Pop, N, M, 'SBX');
                        obj.OpHist(gen) = 3;
                    end
                    totalFE = totalFE + N;
                end

                %% ---- 辅助槽 ----
                if obj.hasCon
                    polishFrom = round(0.75*G); polishMod = 4;
                else
                    polishFrom = round(0.9*G); polishMod = 5;
                end
                if gen >= polishFrom && mod(gen - polishFrom + 1, polishMod) == 1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                if oraActive
                    [obj.V, obj.cluster, obj.clusterDir] = ...
                        obj.onlineReallocation(Problem, Pop, N, M);
                end
                if cbimActive
                    nImm = max(2, round(N/10));
                    Pop = obj.crimImmigration(Problem, Pop, N, M, nImm);
                    totalFE = totalFE + nImm;
                end
            end

            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn == 1);
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), ...
                'nFE', totalFE, 'V', obj.V, 'igdHistory', obj.igdHistory, ...
                'W_final', obj.W, 'WHist', obj.WHist, 'SSVHist', obj.SSVHist, ...
                'MainHist', obj.MainHist, 'OpHist', obj.OpHist, ...
                'SSV_final', [obj.sConv, obj.sDiv, obj.sFeas, obj.sScale], ...
                'hasCon', obj.hasCon, 'D', D);
            Population.decs = Pop.decs; Population.objs = Pop.objs;
            Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== W 阶段增益 g(τ) =====
        function g = stageGains(obj, tau)
            g_conv = 1;
            if tau <= 1/3
                g_div = 1.5;
            elseif tau >= 0.75
                g_div = 1.0;
            else
                g_div = 1.5 - 0.5 * min(1, max(0, (tau - 1/3) / (0.75 - 1/3)));
            end
            g_feas = 1; g_ls = 1;
            g = [g_conv, g_div, g_feas, g_ls];
        end

        %% ===== Q-EPS 环境选择（opKind ∈ {'SBX','DSG','GDV'}） =====
        function Pop = qepsGeneration(obj, Problem, Pop, N, M, opKind)
            mp = randi(size(Pop.decs, 1), 1, N);
            if strcmp(opKind, 'GDV')
                O1.decs = obj.gdvOperator(Problem, Pop, N);
            elseif strcmp(opKind, 'DSG')
                O1.decs = obj.dsgOperator(Problem, Pop.decs(mp, :));
            else
                O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            end
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            F = M1.objs;
            q25 = quantile(F, 0.25, 1); q50 = quantile(F, 0.5, 1);
            q75 = quantile(F, 0.75, 1); q90 = quantile(F, 0.9, 1);
            qidx = zeros(nAll, M);
            for j = 1:M
                qidx(F > q90(j), j) = 4;
                qidx(F > q75(j) & F <= q90(j), j) = 3;
                qidx(F > q50(j) & F <= q75(j), j) = 2;
                qidx(F > q25(j) & F <= q50(j), j) = 1;
            end
            qOf = min(qidx, [], 2);
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo == 1);
            if isempty(nd)
                nd = 1:N; Pop.decs = M1.decs(nd, :); Pop.objs = F(nd, :);
                Pop.cons = M1.cons(nd, :); return;
            end
            nd = nd(:);
            PopObj = F - repmat(min(F, [], 1), nAll, 1);
            if numel(nd) > N
                d2 = sum(PopObj(nd, :).^2, 2);
                [~, ord] = sortrows([d2, qOf(nd)]);
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
            Pop.decs = M1.decs(nd, :); Pop.objs = M1.objs(nd, :);
            Pop.cons = M1.cons(nd, :);
        end

        %% ===== APD + θ（NBI 参考 + 角度关联 + 端点保护） =====
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            V = obj.V; NV = size(V, 1); nCur = size(Pop.objs, 1);
            mp = randi(nCur, 1, N);
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            PopObj = M1.objs - repmat(min(M1.objs, [], 1), nAll, 1);
            nDim = min(M, 2);
            PopObj2 = PopObj(:, 1:nDim);
            V2 = V(:, 1:nDim);
            if nDim == 2
                gamma = min(1 - pdist2(V2, V2, 'cosine'), [], 2); gamma = gamma(:);
                gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
                Angle = acos(max(-1, min(1, 1 - pdist2(PopObj2, V2, 'cosine'))));
                [dmin, assoc] = min(Angle, [], 2);
            else
                [dmin, assoc] = min(sum(PopObj2.^2, 2), [], 1);
                gamma = ones(NV, 1); assoc = ones(nAll, 1);
            end
            APD = (1 + M * theta * dmin ./ gamma(assoc)) .* sqrt(sum(PopObj.^2, 2));
            Keep = false(nAll, 1);
            for i = 1:NV
                cand = find(assoc == i);
                if ~isempty(cand), [~, ii] = min(APD(cand)); Keep(cand(ii)) = true; end
            end
            D = Problem.nVar;
            if D < 100
                [~, gOrd] = sort(gamma, 'descend');
                for e = 1:min(2, NV)
                    vEnd = gOrd(e);
                    if isempty(find(assoc == vEnd))
                        angCol = Angle(:, vEnd); [~, ordAng] = sort(angCol);
                        top3 = ordAng(1:min(3, nAll));
                        if ~isempty(top3), [~, ii] = min(APD(top3)); Keep(top3(ii)) = true; end
                    end
                end
            end
            idx = find(Keep); target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep); [~, ord] = sort(APD(rest));
                need = target - numel(idx); add = rest(ord(1:min(need, numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx, :); Pop.objs = M1.objs(idx, :); Pop.cons = M1.cons(idx, :);
        end

        %% ===== SMS 环境选择（crowding 2D / HV-M 高维） =====
        function Pop = smsGeneration(obj, Problem, Pop, N)
            M = Problem.nObj; nCur0 = size(Pop.objs, 1); target = nCur0 - 1;
            if target < N, target = N; end
            for j = 1:N
                nCur = size(Pop.objs, 1);
                O1.decs = OperatorGAhalf(Problem, Pop.decs(randperm(nCur, 2), :));
                O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
                M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs];
                M1.cons = [Pop.cons; O1.cons];
                [FrontNo, ~] = NDSort(M1.objs, zeros(nCur+1, 0), inf);
                LastFront = find(FrontNo == max(FrontNo)); nLast = numel(LastFront);
                PopObjLast = M1.objs(LastFront, :);
                if M == 2
                    deltaS = inf(1, nLast); [~, rank] = sortrows(PopObjLast);
                    for i = 2:nLast-1
                        deltaS(rank(i)) = (PopObjLast(rank(i+1), 1) - PopObjLast(rank(i), 1)) * ...
                                          (PopObjLast(rank(i-1), 2) - PopObjLast(rank(i), 2));
                    end
                else
                    deltaS = obj.calHVM(PopObjLast, max(M1.objs, [], 1)*1.1, M);
                end
                [~, worst] = min(deltaS); delIdx = LastFront(worst);
                keep = 1:nCur+1; keep(delIdx) = [];
                Pop.decs = M1.decs(keep, :); Pop.objs = M1.objs(keep, :);
                Pop.cons = M1.cons(keep, :);
            end
        end

        %% ===== DSG 有向三段分位采样 =====
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
            wRand = 0.5 + 0.1 * min(M, 10) / 10;
            wDir = 1 - wRand;
            for i = 1:N
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05 * width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05 * width; segBest = q3;
                end
                cand = lo + rand(1, D) .* (hi - lo);
                a = 2 * (1 - i / max(N, 1));
                r1 = 2 * (rand() - 0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% ===== GDV 代际差向量（整 N） =====
        function Offspring = gdvOperator(obj, Problem, Pop, N)
            D = Problem.nVar;
            GDV = obj.calGDV(Problem, Pop, N);
            Offspring = obj.tsoUpdate(Problem, Pop.decs, Pop.objs, GDV, N, D);
        end

        function GDV = calGDV(obj, Problem, Pop, N)
            D = Problem.nVar;
            popDec = Pop.decs; popObj = Pop.objs;
            K = obj.GDVK;
            [Lidx, Lcenter] = obj.kmeansLocal(popDec, K, obj.seed + N + 1);
            Lrd = zeros(K, D);
            for i = 1:K
                ch = Lidx == i;
                if any(ch); Lrd(i, :) = mean(abs(Lcenter(i, :) - popDec(ch, :)), 1); end
            end
            if isempty(obj.Lcenter) || size(obj.Lcenter, 2) ~= D
                GDV = zeros(N, D);
                obj.LpopDec = popDec; obj.LpopObj = popObj;
                obj.Lcenter = Lcenter; obj.Lidx = Lidx; obj.Lrd = Lrd;
                return;
            end
            GDV = zeros(N, D);
            R = rand(N, 1);
            for i = 1:K
                [dis, mi] = obj.pdist1(Lcenter(i, :), obj.Lcenter);
                if mi > K, mi = 1; end
                chCur = Lidx == i; chPrev = obj.Lidx == mi;
                if ~any(chCur) || ~any(chPrev), continue; end
                Fcur = popObj(chCur, :); Fprev = obj.LpopObj(chPrev, :);
                allF = [Fcur; Fprev];
                fmin = min(allF, [], 1); fmax = max(allF, [], 1);
                allFn = (allF - repmat(fmin, size(allF, 1), 1)) ./ ...
                        repmat(fmax - fmin + 1e-12, size(allF, 1), 1);
                fitness = sqrt(sum(allFn.^2, 2));
                f1 = max(fitness(1:size(Fcur, 1)));
                f2 = max(fitness(size(Fcur, 1)+1:end));
                rdNow = Lrd(i, :); rdPrev = obj.Lrd(mi, :);
                om = double(all(rdNow < rdPrev));
                vec = sign(f1 - f2) * (Lcenter(i, :) - obj.Lcenter(mi, :)) + ...
                      om * (Lcenter(i, :) - mean(popDec(chCur, :), 1));
                vec = vec ./ (norm(vec) + 1e-12);
                GDV(chCur, :) = R(chCur) .* rdNow .* vec;
            end
            obj.LpopDec = popDec; obj.LpopObj = popObj;
            obj.Lcenter = Lcenter; obj.Lidx = Lidx; obj.Lrd = Lrd;
        end

        function Offspring = tsoUpdate(obj, Problem, popDec, popObj, GDV, N, D)
            lb = Problem.lower; ub = Problem.upper;
            [fn, ~] = NDSort(popObj, zeros(N, 0), 1);
            f1 = find(fn == 1); if isempty(f1), f1 = 1:N; end
            dNorm = sqrt(sum(popObj(f1, :).^2, 2));
            [~, bestF1] = min(dNorm);
            gBestDec = popDec(f1(bestF1), :);
            fmin = min(popObj, [], 1); fmax = max(popObj, [], 1);
            Pn = (popObj - repmat(fmin, N, 1)) ./ repmat(fmax - fmin + 1e-12, N, 1);
            fitness = sqrt(sum(Pn.^2, 2));
            swarmN = floor(N/3);
            if N >= 3; Rank = randperm(N, swarmN*3); else; Rank = [1,1,1]; end
            p1 = Rank(1:swarmN); p2 = Rank(swarmN+1:2*swarmN); p3 = Rank(2*swarmN+1:3*swarmN);
            Change1 = fitness(p3) > fitness(p1);
            Temp = p1(Change1); p1(Change1) = p3(Change1); p3(Change1) = Temp;
            Change2 = (fitness(p2) > fitness(p1)) & (fitness(p2) > fitness(p3));
            Temp = p1(Change2); p1(Change2) = p2(Change2); p2(Change2) = Temp;
            popVel = zeros(N, D);
            C1 = repmat(rand(N, 1), 1, D);
            C2 = repmat(rand(N, 1), 1, D);
            for i = 1:swarmN
                popVel(p1(i), :) = (gBestDec - popDec(p1(i), :));
                popVel(p2(i), :) = C1(p2(i), :).*popVel(p2(i), :) + ...
                                   C2(p2(i), :).*(popDec(p1(i), :) - popDec(p2(i), :));
                popVel(p3(i), :) = C1(p3(i), :).*popVel(p3(i), :) + ...
                                   C2(p3(i), :).*(popDec(p1(i), :) - popDec(p3(i), :));
            end
            velMax = repmat((ub - lb + 1e-12) / 1.001, N, 1);
            popVel = max(min(popVel, velMax), -velMax);
            Offspring = popDec + popVel + GDV;
            Offspring = max(min(Offspring, ub), lb);
            disM = 20;
            if ~isscalar(ub), ub = ub(end); end
            if ~isscalar(lb), lb = lb(1); end
            Site1 = repmat(rand(N, 1) < 0.999, 1, D);
            Site2 = rand(N, D) < 1/D;
            mu = rand(N, D);
            temp = Site1 & Site2 & (mu <= 0.5);
            Offspring(temp) = Offspring(temp) + (ub - lb) .* ...
                ((2.*mu(temp)+(1-2.*mu(temp)).*(1-(Offspring(temp)-lb)./(ub-lb)).^(disM+1)).^(1/(disM+1))-1);
            temp2 = Site1 & Site2 & (mu > 0.5);
            Offspring(temp2) = Offspring(temp2) + (ub - lb) .* ...
                (1-(2.*(1-mu(temp2))+2.*(mu(temp2)-0.5).*(1-(ub-Offspring(temp2))./(ub-lb)).^(disM+1)).^(1/(disM+1)));
        end

        %% ===== ORA 在线参考向量再分配 =====
        function [V, cluster, clusterDir] = onlineReallocation(obj, Problem, Pop, N, M)
            F = Pop.objs;
            [fn, ~] = NDSort(F, Pop.cons, inf);
            f1 = find(fn == 1);
            if numel(f1) < 2*N/5
                V = obj.V; cluster = obj.cluster; clusterDir = obj.clusterDir; return;
            end
            F1 = F(f1, :);
            F1n = F1 ./ max(sqrt(sum(F1.^2, 2)), 1e-12);
            n1 = size(F1n, 1);
            rng(2026 + obj.seed + 1);
            idx = randperm(n1, obj.K);
            C = F1n(idx, :);
            for it = 1:5
                D2 = pdist2(F1n, C, 'cosine');
                [~, lab] = min(D2, [], 2);
                for k = 1:obj.K
                    if any(lab == k)
                        C(k, :) = mean(F1n(lab==k, :), 1);
                        C(k, :) = C(k, :) / (norm(C(k, :)) + 1e-12);
                    end
                end
            end
            cluster = C;
            clusterDir = zeros(obj.K, M);
            for k = 1:obj.K
                Pk = F1n(lab==k, :);
                if size(Pk, 1) >= 2
                    [U,~,Vc] = svd(Pk - mean(Pk, 1), 0);
                    clusterDir(k, :) = Vc(:, 1).';
                else
                    clusterDir(k, :) = C(k, :);
                end
            end
            [V0, ~] = UniformPoint(N, M, 'NBI');
            Dv = pdist2(V0, C, 'cosine');
            [~, near] = min(Dv, [], 2);
            Vnew = 0.5 * V0 + 0.5 * C(near, :);
            nn = sqrt(sum(Vnew.^2, 2));
            Vnew = Vnew ./ max(nn, 1e-12);
            V = Vnew(1:min(N, size(Vnew, 1)), :);
        end

        %% ===== CBIM 边界移民 =====
        function Pop = crimImmigration(obj, Problem, Pop, N, M, nImm)
            if isempty(obj.clusterDir), return; end
            lb = Problem.lower; ub = Problem.upper;
            base = Pop.decs;
            Fbase = Problem.CalObj(base);
            for k = 1:min(nImm, size(obj.clusterDir, 1))
                dirK = obj.clusterDir(k, :);
                Fproj = Fbase * dirK.';
                [~, iMin] = min(Fproj); [~, iMax] = max(Fproj);
                src1 = base(iMin, :); src2 = base(iMax, :);
                newDe = zeros(2, Problem.nVar);
                newDe(1, :) = min(max(src1 + 0.02*(rand(1, Problem.nVar)-0.5), lb), ub);
                newDe(2, :) = min(max(src2 + 0.02*(rand(1, Problem.nVar)-0.5), lb), ub);
                Fnew = Problem.CalObj(newDe);
                [~, wIdxOrder] = sort(sum(Fbase, 2), 'descend');
                wIdx = wIdxOrder(1:2);
                Pop.decs(wIdx(1:2), :) = newDe;
                Pop.objs(wIdx(1:2), :) = Fnew;
                Pop.cons(wIdx(1:2), :) = Problem.CalCon(newDe);
            end
        end

        %% ===== polish（末端 HV 抛光，3 FE/次，不劣化） =====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs, 1);
            k = 0;
            for t = 1:3
                i = randi(N);
                oldO = Pop.objs(i, :);
                cand = Pop.decs(i, :);
                cand = cand + 0.01 * (rand(1, Problem.nVar) - 0.5);
                cand = min(max(cand, Problem.lower), Problem.upper);
                candO = Problem.CalObj(cand);
                if ~any(candO > oldO) || sum(candO) < sum(oldO)
                    Pop.objs(i, :) = candO; Pop.decs(i, :) = cand;
                end
                k = k + 1;
            end
        end

        %% ===== K-means / 距离 / HV 工具 =====
        function [idx, center] = kmeansLocal(obj, X, K, seed)
            n = size(X, 1);
            rng(seed);
            idx0 = randperm(n, K);
            center = X(idx0, :);
            for it = 1:15
                D2 = pdist2(X, center);
                [~, idx] = min(D2, [], 2);
                for k = 1:K
                    ch = idx == k;
                    if any(ch); center(k, :) = mean(X(ch, :), 1); end
                end
            end
        end

        function [d, minIdx] = pdist1(obj, a, B)
            m = size(B, 1);
            d = zeros(1, m);
            for k = 1:m; d(1, k) = norm(a - B(k, :)); end
            [d, minIdx] = min(d);
        end

        function hv = calHV(obj, PopObj, ref, M)
            if M ~= 2
                hv = sum(obj.calHVM(PopObj, ref, M)); return;
            end
            PopObj = PopObj(all(PopObj <= ref, 2), :);
            if isempty(PopObj), hv = 0; return; end
            PopObj = sortrows(PopObj, 1);
            x = [PopObj(:, 1); ref(1)]; hv = 0; ymin = ref(2);
            for i = 1:size(PopObj, 1)
                if PopObj(i, 2) < ymin, ymin = PopObj(i, 2); end
                hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
            end
        end

        function F = calHVM(obj, PopObj, ref, M)
            nSample = 1000; k = 1;
            PopObj = PopObj(all(PopObj <= ref, 2) & all(PopObj >= 0, 2), :);
            [N, ~] = size(PopObj); if N == 0, F = 0; return; end
            alpha = zeros(1, N);
            for i = 1:min(k, N), alpha(i) = prod((k - [1:i-1]) / (N - [1:i-1]))./i; end
            Fmin = min(PopObj, [], 1); rng(2026);
            S = unifrnd(repmat(Fmin, nSample, 1), repmat(ref, nSample, 1));
            PdS = false(N, nSample); dS = zeros(1, nSample);
            for i = 1:N
                x = sum(repmat(PopObj(i, :), nSample, 1) - S <= 0, 2) == M;
                PdS(i, x) = true; dS(x) = dS(x) + 1;
            end
            F = zeros(1, N);
            for i = 1:N
                F(i) = sum(alpha(dS(PdS(i, :))));
            end
        end
    end
end
