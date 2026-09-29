classdef EDDV5 < ALGORITHM
    % EDD v5 - 双种群 EDD（第四轮·架构级·强化版a）
    %
    % 架构（用户指定）：
    %   子种群 A（Na=50）：DSG 决策空间开发（A 的 load-bearing 算子，为 300D 设计）
    %   子种群 B（Nb=50）：EED 目标空间多样性维护（B 的 load-bearing 选择机制）
    %                       B 子代生成 = 强化版(a)：DSG 三段分位骨架(0.15/0.5/0.85)引导
    %                       探索方向 + 变异率自适应 EED 网格空格数（空格多→变异大）
    %                       目的 = 覆盖决策空间不同区域（探索非开发）
    %   跨域交换（每 10 代，零 FE，复用目标值）：
    %     A→B：A 中 IGD 贡献最大（到原点距离最小）的 5 解 注入 B，替换 B 中 EED 网格
    %           覆盖最差（所在网格内离原点最远/网格占用最稀）的 5 解
    %     B→A：B 中 EED 网格覆盖最稀疏方向的 5 解 注入 A，替换 A 中 IGD 最差（到原点
    %           距离最大）的 5 解
    %   末端共享 polish-HV（继承 v12：0.9G 起每 5 代 3 次 1% 决策空间扰动，FE 计入）
    %
    % FE 预算：初始化 100 + 每代 100（A 产 50 + B 产 50）× 200 代 + polish ≈ 21
    %           ≈ 20121（与旧 EDD 同量级，FE 预算未变；N/G/种子/PF/参考点全不变）
    %
    % 消融开关 ablation（load-bearing 验证）：
    %   'full'    - 完整（A=DSG + B=强化版a+EED网格选择 + 跨域交换）
    %   'noDSG'   - A 改用 SBX 双父交叉（去 DSG）→ 测 DSG load-bearing（IGD 应恶化）
    %   'noEED'   - B 改用 front-1 填充选择（去 EED 网格）→ 测 EED load-bearing（HV 应恶化）
    %   'noXchg'  - 去跨域交换（A/B 独立演化后各自选择合并）→ 测交换贡献
    %
    % 红线：不引入 FDSEA 傅里叶参数化主路径（无 calDec/calMP/frGA）；FDSEA/GDVTSF/
    %       MOEA-IB 源码只读；不篡改数据/PF/参考点/种子/FE 预算。
    % 定位：第四轮为最后一轮（解除 3 轮上限）。LSMOP1-3 对 FDSEA 胜负比 0:3→≥1:2 则
    %       续跑 LSMOP4-9 + 重算 Friedman；仍 0:3 则停止改进循环进入最终判定。

    properties
        ablation;   % 'full' | 'noDSG' | 'noEED' | 'noXchg'
        epsGrid;    % EED epsilon 网格数（B 用）
    end

    methods
        function obj = EDDV5(popSize, maxGen, seed, ablation)
            obj@ALGORITHM(popSize, maxGen, seed);
            if nargin >= 4 && ~isempty(ablation), obj.ablation = ablation; else obj.ablation = 'full'; end
            obj.epsGrid = 10;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            Na = ceil(N/2); Nb = N - Na;                 % A=50, B=50
            highDim = (D >= 100) || (M >= 10);
            if ~highDim
                error('EDDV5 is designed for D>=100 or M>=10.');
            end

            % ---- 初始化（FE=N）：整体初始化 N 解，切分 A/B ----
            Pop = Problem.Initialization(N);
            totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);
            nX = min(5, min(Na, Nb));                         % 交换规模（用户指定 5）

            for g = 1:G
                %% ===== 子代生成（FE=N）=====
                A = Pop.decs(1:Na,:); fA = Pop.objs(1:Na,:); cA = Pop.cons(1:Na,:);
                if strcmp(obj.ablation, 'noDSG')
                    O_A = obj.sbxOperator(Problem, A);
                else
                    O_A = obj.dsgOperator(Problem, A, fA);
                end
                B = Pop.decs(Na+1:N,:); fB = Pop.objs(Na+1:N,:); cB = Pop.cons(Na+1:N,:);
                O_B = obj.exploreB(Problem, B, fB, cB, obj.epsGrid, Na, Nb);
                O = [O_A; O_B];                          % N×D（A 产 Na + B 产 Nb）
                Os.decs = O;
                Os.objs = Problem.CalObj(Os.decs);
                Os.cons = Problem.CalCon(Os.decs);
                totalFE = totalFE + N;

                %% ===== 各自选择（FE=0）=====
                % A：front-1 按到原点距离收敛选择（保留 A 的开发产物）
                % B：EED epsilon 网格选择（noEED 消融时改 front-1 填充）
                PopA = obj.convergeSelect(Problem, A, fA, cA, Os.decs(1:Na,:), Os.objs(1:Na,:), Os.cons(1:Na,:), Na);
                if strcmp(obj.ablation, 'noEED')
                    PopB = obj.frontFillSelect(Problem, B, fB, cB, Os.decs(Na+1:N,:), Os.objs(Na+1:N,:), Os.cons(Na+1:N,:), Nb);
                else
                    PopB = obj.eedSelect(Problem, B, fB, cB, Os.decs(Na+1:N,:), Os.objs(Na+1:N,:), Os.cons(Na+1:N,:), Nb, obj.epsGrid);
                end
                Pop.decs = [PopA.decs; PopB.decs];
                Pop.objs = [PopA.objs; PopB.objs];
                Pop.cons = [PopA.cons; PopB.cons];

                %% ===== 每 10 代跨域交换（FE=0，复用目标值）=====
                if ~strcmp(obj.ablation, 'noXchg') && mod(g, 10) == 0
                    Pop = obj.crossExchange(Pop, Na, Nb, nX);
                end

                %% ===== 末端 polish-HV（继承 v12：0.9G 起每 5 代 3 次扰动，FE 计入）=====
                polishFrom = round(0.9*G);
                if g >= polishFrom && mod(g-polishFrom+1, 5) == 1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                igdHistory(g) = IGD(Pop.objs, PFtrue);
            end

            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            if isempty(nd), nd = 1:N; end
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'ablation', obj.ablation, 'PPS_A', Na, 'PPS_B', Nb, ...
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        %% ===== A 选择：front-1 按到原点距离收敛裁剪到 Na =====
        function Pop = convergeSelect(obj, Problem, A, fA, cA, O, o, cO, Na)
            M1.decs = [A; O]; M1.objs = [fA; o]; M1.cons = [cA; cO];
            nAll = size(M1.objs,1); F = M1.objs;
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo==1); nd = nd(:);
            if numel(nd) > Na
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:Na));
            elseif numel(nd) < Na
                keep = nd;
                for f = 2:max(FrontNo)
                    cand = find(FrontNo==f);
                    if numel(keep) >= Na, break; end
                    keep = [keep; cand(:)];
                end
                nd = keep(1:min(Na, numel(keep)));
                if numel(nd) < Na
                    fill = setdiff(1:nAll, nd);
                    nd = [nd(:); fill(1:(Na-numel(nd)))];
                end
            end
            nd = nd(:);
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
        end

        %% ===== B 选择：EED epsilon 网格（每格保留离原点最近）到 Nb =====
        function Pop = eedSelect(obj, Problem, B, fB, cB, O, o, cO, Nb, epsGrid)
            M1.decs = [B; O]; M1.objs = [fB; o]; M1.cons = [cB; cO];
            nAll = size(M1.objs,1); F = M1.objs; M = Problem.nObj;
            Fmin = min(F,[],1); Fmax = max(F,[],1);
            width = Fmax - Fmin; width(width==0) = 1;
            eps = width / epsGrid;
            PopObj = F - repmat(Fmin, nAll, 1);
            gridIdx = zeros(nAll, M);
            for i = 1:nAll
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / eps(j)));
                end
            end
            [gU, gI] = unique(gridIdx, 'rows');
            nd = false(nAll,1);
            for gu = 1:numel(gU)
                inG = find(gI == gu);
                if ~isempty(inG)
                    [~, ii] = min(sum(PopObj(inG,:).^2, 2));
                    nd(inG(ii)) = true;
                end
            end
            kidx = find(nd);
            if numel(kidx) > Nb
                [~, ordG] = sort(sum(PopObj(kidx,:).^2, 2));
                nd = false(nAll,1); nd(kidx(ordG(1:Nb))) = true;
                kidx = find(nd);
            end
            % 不足 Nb：front 层次补齐
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            if numel(kidx) < Nb
                rest = setdiff(1:nAll, kidx); rest = rest(:);
                if ~isempty(rest)
                    [~, ordF] = sort(FrontNo(rest));
                    take = min(Nb-numel(kidx), numel(rest));
                    kidx = [kidx; rest(ordF(1:take))];
                end
            end
            if numel(kidx) > Nb, kidx = kidx(1:Nb); end
            kidx = kidx(:);
            Pop.decs = M1.decs(kidx,:); Pop.objs = M1.objs(kidx,:); Pop.cons = M1.cons(kidx,:);
        end

        %% ===== B 选择（noEED 消融用）：front-1 填充到 Nb =====
        function Pop = frontFillSelect(obj, Problem, B, fB, cB, O, o, cO, Nb)
            M1.decs = [B; O]; M1.objs = [fB; o]; M1.cons = [cB; cO];
            nAll = size(M1.objs,1); F = M1.objs;
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            [FrontNo, ~] = NDSort(F, M1.cons, inf);
            nd = find(FrontNo==1); nd = nd(:);
            if numel(nd) > Nb
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:Nb));
            elseif numel(nd) < Nb
                keep = nd;
                for f = 2:max(FrontNo)
                    cand = find(FrontNo==f);
                    if numel(keep) >= Nb, break; end
                    keep = [keep; cand(:)];
                end
                nd = keep(1:min(Nb, numel(keep)));
                if numel(nd) < Nb
                    fill = setdiff(1:nAll, nd);
                    nd = [nd(:); fill(1:(Nb-numel(nd)))];
                end
            end
            nd = nd(:);
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
        end

        %% ===== 强化版(a) B 子代：DSG 三段分位骨架引导探索 + 变异率自适应 EED 空格 =====
        function O = exploreB(obj, Problem, B, fB, cB, epsGrid, Na, Nb)
            % B 的探索子代：用 B 当前解的 0.15/0.5/0.85 分位段作引导骨架（继承 DSG 思想），
            % 每子代随机选段 → 段内采样 → 向段中心灰狼式定向移动；
            % 变异率（步长缩放）自适应 EED 网格空格数：空格多 → 变异大（扩大探索），
            % 空格少 → 变异小（精细覆盖）。目的 = 覆盖决策空间不同区域（非开发）。
            N = size(B,1); D = Problem.nVar; M = Problem.nObj;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width==0) = 1;
            F = fB; C = cB;
            [FrontNo, ~] = NDSort(F, C, inf);
            f1 = find(FrontNo==1);
            if numel(f1) < 5, f1 = 1:N; end            % front-1 太少时用全体
            q1 = quantile(B(f1,:), 0.15, 1);
            q2 = quantile(B(f1,:), 0.5, 1);
            q3 = quantile(B(f1,:), 0.85, 1);
            % EED 网格空格统计（B 当前 + 子代候选前的 B 池）：
            Fmin = min(F,[],1); Fmax = max(F,[],1); w = Fmax-Fmin; w(w==0)=1;
            e = w / epsGrid;
            gridIdx = zeros(N, M);
            for i = 1:N
                for j = 1:M
                    gridIdx(i,j) = min(epsGrid, ceil((F(i,j)-Fmin(j)) / e(j)));
                end
            end
            nOcc = size(unique(gridIdx, 'rows'), 1);        % 已占网格数
            nCell = epsGrid^M;                               % 总网格数
            nEmpty = max(nCell - nOcc, 0);                    % 空格数
            % 变异率自适应：空格占比高 → 步长大（0.5~1.0）；空格少 → 步长小（0.1~0.4）
            ratio = nEmpty / max(nCell, 1);
            mutScale = 0.1 + 0.9 * min(max(ratio,0),1);       % 0.1 ~ 1.0
            wRand = 0.5 + 0.1*min(M,10)/10;
            wDir  = 1 - wRand;
            O = zeros(Nb, D);
            for i = 1:Nb
                seg = randi(3);
                switch seg
                    case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                a = 2 * (1 - i/max(Nb,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                % 变异率自适应：按 mutScale 放大探索步（向随机方向 + 变异）
                cand = cand + mutScale * 0.1 * (rand(1,D)-0.5) .* width;
                O(i,:) = min(max(cand, lb), ub);
            end
        end

        %% ===== 跨域交换（A 5 最优注入 B 最劣；B 5 最多样注入 A 最劣；零 FE 复用目标值）=====
        function Pop = crossExchange(obj, Pop, Na, Nb, nX)
            N = Na + Nb;
            A = Pop.decs(1:Na,:); cA = Pop.cons(1:Na,:); fA = Pop.objs(1:Na,:);
            B = Pop.decs(Na+1:N,:); cB = Pop.cons(Na+1:N,:); fB = Pop.objs(Na+1:N,:);
            % A→B：A 中 IGD 贡献最大（到原点距离最小）的 nX 解 → 替换 B 中 IGD 最差（距离最大）nX 解
            [~, ordA] = sort(sum(fA.^2, 2));            % 升序：最优在前（返回索引）
            [~, ordBw] = sort(sum(fB.^2, 2), 'descend');  % 降序：最差在前（返回索引）
            A_best = A(ordA(1:nX), :);
            B_worst_abs = (Na+1) + ordBw(1:nX);         % B 最劣在 Pop 中的绝对行号
            Pop.decs(B_worst_abs, :) = A_best;
            Pop.objs(B_worst_abs, :) = fA(ordA(1:nX), :);   % 复用目标值（A 已评估）
            Pop.cons(B_worst_abs, :) = cA(ordA(1:nX), :);
            % B→A：B 中 IGD 贡献最大（到原点距离最小）的 nX 解 → 替换 A 中最差 nX 解
            B_best = B(ordBw(end-nX+1:end), :);          % B 最优（降序末尾）
            A_worst = ordA(end-nX+1:end);                % A 最劣（升序末尾）
            Pop.decs(A_worst, :) = B_best;
            Pop.objs(A_worst, :) = fB(ordBw(end-nX+1:end), :);
            Pop.cons(A_worst, :) = cB(ordBw(end-nX+1:end), :);
        end

        %% ===== DSG 有向决策采样算子（继承 v12，A 开发）=====
        function Offspring = dsgOperator(obj, Problem, ParentDecs, fP)
            N = size(ParentDecs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width == 0) = 1;
            Offspring = zeros(N, D);
            F = fP;
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
                    case 1, lo = lb + 0.05*width; hi = q1; segBest = q1;
                    case 2, lo = q1; hi = q3; segBest = q2;
                    otherwise, lo = q3; hi = ub - 0.05*width; segBest = q3;
                end
                cand = lo + rand(1,D) .* (hi - lo);
                a = 2 * (1 - i/max(N,1));
                r1 = 2*(rand()-0.5);
                dir = segBest - cand;
                cand = wRand * cand + wDir * a * r1 * dir;
                Offspring(i, :) = min(max(cand, lb), ub);
            end
        end

        %% ===== SBX 双父交叉（noDSG 消融用：A 改 SBX，去 DSG）=====
        function Offspring = sbxOperator(obj, Problem, ParentDecs)
            N = size(ParentDecs,1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            Offspring = zeros(N, D);
            P1 = randi(N,1,N); P2 = randi(N,1,N);
            same = (P2==P1); P2(same) = mod(P2(same), N)+1;
            X1 = ParentDecs(P1,:); X2 = ParentDecs(P2,:);
            mu = rand(N,D);
            mLE = (mu<=0.5); mGT = (mu>0.5);
            base = 2*mu; base(mGT) = 2-2*mu(mGT);
            expn = ones(N,D)/15; expn(mGT) = -1/15;
            beta = base .^ expn;
            beta = beta .* (-1).^randi([0,1], N, D);
            beta(rand(N,D)<0.5) = 1;
            Offspring = (X1+X2)/2 + beta.*(X1-X2)/2;
            Offspring = min(max(Offspring, lb), ub);
        end

        %% ===== 末端 HV 抛光（继承 v12：1% 决策空间扰动 ×3 次，FE 计入）=====
        function [Pop, k] = polishHV(obj, Problem, Pop, M)
            N = size(Pop.decs,1); ref = max(Pop.objs,[],1)*1.1;
            best = obj.calHV(Pop.objs, ref, M); k = 0;
            for t = 1:3
                i = randi(N);
                cand = Pop.decs; cand(i,:) = cand(i,:) + 0.01*(rand(1,Problem.nVar)-0.5);
                cand = min(max(cand,Problem.lower),Problem.upper);
                candO = Problem.CalObj(cand(i,:));
                Pop.objs(i,:) = candO; Pop.decs(i,:) = cand(i,:);
                Pop.cons(i,:) = Problem.CalCon(cand(i,:));
                k = k+1;
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
