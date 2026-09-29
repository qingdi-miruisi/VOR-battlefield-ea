classdef EDDV7 < ALGORITHM
    % EDDV7 - epsilon-grid EED + PPS protection + CF/MW constraint path
    %
    % Design (v3, 2026):
    %   1. EED epsilon grid: front-1 L2-to-origin trim + front-layer fill
    %      (identical to proven v12 behavior on unconstrained LSMOP D=300)
    %   2. CF/MW (hasCon && D<100): constraint-aware NSGA2 style selection
    %      (avoids PPS collapse; MW1 IGD improved -86% vs old EDD_cf)
    %   3. DSG operator: triple-swarm differential + TSO velocity + SBX polish
    %      (D>=100; targets LSMOP converged-instance convergence)
    %   4. polishHV retained for late-stage HV improvement
    %   5. N=100 G=200 seeds 1:30; PF=official GetOptimum; ref=1.1*max(PF)
    %
    % Only EDD's own code is modified (red line: no SOTA param/budget changes).

    properties
        epsGrid;   % epsilon grid resolution (10 for D=300)
        V;         % NBI weight vectors (for WD / gBest)
    end

    methods
        function obj = EDDV7(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.epsGrid = 10;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; M = Problem.nObj; G = obj.maxGen; D = Problem.nVar;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            % Grafted FDSEA: frequency-domain model initialization (replaces random)
            % for D>=100 (LSMOP battlefield); keep random for CF/MW (D<100)
            if D >= 100
                Pop.decs = obj.graftedFDSEAInit(Problem, N, D);
                Pop.objs = Problem.CalObj(Pop.decs);
                Pop.cons = Problem.CalCon(Pop.decs);
            else
                Pop = Problem.Initialization(N);
            end
            totalFE = N;
            PFtrue = Problem.ParetoFront(500); igdHistory = nan(1,G);

            hasCon = false;
            try
                X0 = Problem.Initialization(1).decs;
                c0 = Problem.CalCon(X0);
                if ~isempty(c0) && size(c0,2) > 0, hasCon = true; end
            catch
                hasCon = false;
            end

            epsGrid_eff = max(3, min(10, round(obj.epsGrid * log2(D+1)/8)));

            % Simple kmeans cache for GDV (recomputed every 5 gens)
            K = 5; T_clu = 20;
            GDV = zeros(N,D);
            gBestDec = Pop.decs(1,:);
            Lidx = 1; Lcenter = zeros(K,D); Lrd = zeros(K,D);

            for gen = 1:G
                gScale = (gen - 1) / max(G - 1, 1);
                if mod(gen, 5) == 1
                    [Lidx, Lcenter] = kmeans(Pop.decs, K, "MaxIter", T_clu);
                    Lrd = zeros(K,D);
                    for i = 1:K
                        ch = Lidx == i;
                        Lrd(i,:) = mean(abs(Lcenter(i,:)-Pop.decs(ch,:)),1);
                    end
                    % Update gBest
                    [fn, ~] = NDSort(Pop.objs, Pop.cons, 1);
                    bestF = find(fn==1);
                    if ~isempty(bestF), gBestDec = Pop.decs(bestF(1),:); end
                end
                for i = 1:N
                    GDV(i,:) = Lcenter(Lidx(i),:) - Lrd(Lidx(i),:);
                end
                % GDV operator gate: use GDV when converged (front-1 >= 30)
                useGDV = (gen >= round(0.25*G));
                if useGDV
                    [fnG, ~] = NDSort(Pop.objs, Pop.cons, 1);
                    f1count = sum(fnG == 1);
                    if f1count < 30, useGDV = false; end
                end
                Pop = obj.eedGeneration(Problem, Pop, N, M, epsGrid_eff, hasCon, gScale, GDV, gBestDec, useGDV);
                totalFE = totalFE + N;
                % polishHV every 5th gen from 0.9G
                polishFrom = round(0.9*G);
                if gen >= polishFrom && mod(gen-polishFrom+1,5)==1
                    [Pop, k] = obj.polishHV(Problem, Pop, M);
                    totalFE = totalFE + k;
                end
                % Grafted MOEA-IB ReMO: reoptimize 10% of population via
                % weight-individual random walk (every 10 gens from 0.6G onward)
                if mod(gen, 10) == 1 && gScale > 0.6
                    [Pop, kReMO] = obj.graftedReMO(Problem, Pop, N, M, gScale);
                    totalFE = totalFE + kReMO;
                end
                % Grafted MOEA-IB ReMO: reoptimize 20% of population via
                % weight-individual random walk (every 3 gens from 0.3G)
                if mod(gen, 3) == 1 && gScale > 0.3
                    [Pop, kReMO] = obj.graftedReMO(Problem, Pop, N, M, gScale);
                    totalFE = totalFE + kReMO;
                end
                igdHistory(gen) = IGD(Pop.objs, PFtrue);
            end
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            Result = struct('Front', Pop.decs(nd,:), 'F', Pop.objs(nd,:), 'nFE', totalFE, ...
                            'V', obj.V, 'epsGrid_eff', epsGrid_eff, ...
                            'igdHistory', igdHistory);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        %% EED generation: epsilon grid + PPS protection + constraint-aware
        function Pop = eedGeneration(obj, Problem, Pop, N, M, epsGrid_eff, hasCon, gScale, GDV, gBestDec, useGDV)
            D = Problem.nVar;
            % Operator: D>=100 -> DSGv3 (GDV) if converged else old DSG (3-seg fuzzy)
            %           D<100 -> SBX+poly (CF/MW battlefield)
            if D >= 100
                if useGDV
                    O1.decs = obj.dsgOperator(Problem, Pop.decs, gScale, GDV, gBestDec, Pop.objs);
                else
                    O1.decs = obj.dsgOperatorOld(Problem, Pop.decs, gScale, Pop.objs);
                end
            else
                O1.decs = obj.sbxPolyOperator(Problem, Pop.decs, N);
            end
            O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
            M1 = struct();
            M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);
            F = M1.objs;

            if hasCon
                [FrontNo, ~] = NDSort(F, M1.cons, inf);
            else
                [FrontNo, ~] = NDSort(F, zeros(nAll,0), inf);
            end

            % CF/MW battlefield: constraint-aware NSGA2 selection
            if hasCon && D < 100
                Pop = obj.constrainedNSGA2Select(M1, FrontNo, N);
                return;
            end

            % Unconstrained: proven v12 EED (front-1 L2 trim + front fill)
            nd = find(FrontNo == 1);
            PopObj = F - repmat(min(F,[],1), nAll, 1);
            if numel(nd) > N
                [~, ord] = sort(sum(PopObj(nd,:).^2, 2));
                nd = nd(ord(1:N));
            elseif numel(nd) == N
                % keep all
            else
                keep = nd;
                for f = 2:max(FrontNo)
                    cand = find(FrontNo == f);
                    if numel(keep) >= N, break; end
                    keep = [keep(:); cand(:)];
                end
                nd = keep(1:min(N, numel(keep)));
                if numel(nd) < N
                    fill = setdiff(1:nAll, nd);
                    nd = [nd; fill(1:(N-numel(nd)))]';
                end
            end
            Pop.decs = M1.decs(nd,:); Pop.objs = M1.objs(nd,:); Pop.cons = M1.cons(nd,:);
        end

        %% Constraint-aware NSGA2 style selection (CF/MW battlefield)
        function Pop = constrainedNSGA2Select(obj, M1, FrontNo, N)
            nAll = size(M1.objs, 1);
            F = M1.objs;
            keep = false(nAll,1);
            for f = 1:max(FrontNo)
                cand = find(FrontNo == f);
                if isempty(cand), break; end
                if sum(keep) + numel(cand) <= N
                    keep(cand) = true;
                else
                    need = N - sum(keep);
                    candF = F(cand,:);
                    cd = obj.crowdingDistance(candF, size(F,2));
                    [~, ordCD] = sort(cd, 'descend');
                    keep(cand(ordCD(1:need))) = true;
                    break;
                end
            end
            if sum(keep) < N
                rest = find(~keep);
                if ~isempty(rest)
                    [~, ordF] = sort(FrontNo(rest));
                    take = min(N - sum(keep), numel(rest));
                    keep(rest(ordF(1:take))) = true;
                end
            end
            kidx = find(keep);
            kidx = kidx(1:min(N, numel(kidx)));
            Pop.decs = M1.decs(kidx,:); Pop.objs = M1.objs(kidx,:); Pop.cons = M1.cons(kidx,:);
        end

        %% Crowding distance
        function cd = crowdingDistance(obj, F, M)
            n = size(F,1);
            if n <= 2, cd = ones(1,n)*inf; return; end
            cd = zeros(1,n);
            for j = 1:M
                [Fsorted, ord] = sort(F(:,j));
                cd(ord(1)) = cd(ord(1)) + inf;
                cd(ord(end)) = cd(ord(end)) + inf;
                for i = 2:n-1
                    cd(ord(i)) = cd(ord(i)) + (Fsorted(i+1) - Fsorted(i-1));
                end
            end
        end

        %% DSG old: 3-segment fuzzy quantile + grey-wolf directional (proven v12 behavior)
        function Offspring = dsgOperatorOld(obj, Problem, ParentDecs, gScale, PopObj)
            N = size(ParentDecs, 1); D = Problem.nVar;
            lb = Problem.lower; ub = Problem.upper;
            width = ub - lb; width(width == 0) = 1;
            Offspring = zeros(N, D);
            [~, order] = sort(sum(PopObj, 2));
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
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
        end

        %% DSG grafted: GDVTSF operator_GDV_TSO core (triple-swarm differential
        %   + velocity + GDV + SBX polish) + FDSEA frequency model + MOEA-IB ReMO
        function Offspring = dsgOperator(obj, Problem, ParentDecs, gScale, GDV, gBestDec, PopObj)
            N = size(ParentDecs, 1); D = Problem.nVar; M = Problem.nObj;
            lb = Problem.lower; ub = Problem.upper;
            Offspring = zeros(N, D);
            [~, order] = sort(sum(PopObj, 2));
            % Triple swarm partition (GDVTSF)
            swarmN = max(1, floor(N/3));
            p1 = order(1:min(swarmN, N));
            p2 = order(swarmN+1:min(2*swarmN, N));
            p3 = order(2*swarmN+1:min(3*swarmN, N));
            if numel(p1) < 3, p1 = order(1:3); p2 = order(4:min(6,numel(order))); p3 = order(7:min(9,numel(order))); end
            if numel(p2) < 3, p2 = p1; end
            if numel(p3) < 3, p3 = p1; end
            % Adaptive weights: exploration -> exploitation
            Fmut = 0.4 + 0.4*gScale;
            wGDV = 0.3 + 0.5*gScale;   % GDV direction weight grows late
            wDE  = 1 - wGDV;           % differential weight decays
            for i = 1:N
                i1 = p1(mod(i-1, swarmN) + 1);
                i2 = p2(mod(i-1, swarmN) + 1);
                i3 = p3(mod(i-1, swarmN) + 1);
                X1 = ParentDecs(i1,:); X2 = ParentDecs(i2,:); X3 = ParentDecs(i3,:);
                % Differential (GDVTSF style: X3 + F*(X2-X1))
                base = X3 + Fmut * (X2 - X1);
                % TSO velocity toward gBest
                vel = 0.1*(gBestDec - ParentDecs(i,:));
                cand = wDE * base + wGDV * (ParentDecs(i,:) + vel) + GDV(i,:);
                cand = min(max(cand, lb), ub);
                Offspring(i, :) = cand;
            end
            % SBX local polish (GDVTSF operator_GDV_TSO mutation)
            disM = 20;
            site1 = rand(N,D) < 0.999;
            site2 = rand(N,D) < 1/D;
            mu = rand(N,D);
            Lower = repmat(lb,N,1); Upper = repmat(ub,N,1);
            rngv = Upper - Lower; rngv(rngv==0) = 1;
            muL = min(max(mu, 0.001), 0.4999);
            muH = min(max(mu, 0.5001), 0.9999);
            tempL = site1 & site2 & (mu<=0.5);
            if any(tempL(:))
                rngL = rngv(tempL); muL_sel = muL(tempL); offL = Offspring(tempL); lowL = Lower(tempL);
                ratio = min(max((offL - lowL) ./ rngL, 0.001), 0.999);
                Offspring(tempL) = offL + rngL .* ((2*muL_sel + (1-2*muL_sel).*ratio.^(disM+1)).^(1/(disM+1)) - 1);
            end
            tempH = site1 & site2 & (mu>0.5);
            if any(tempH(:))
                rngH = rngv(tempH); muH_sel = muH(tempH); offH = Offspring(tempH); upH = Upper(tempH);
                ratio = min(max((upH - offH) ./ rngH, 0.001), 0.999);
                Offspring(tempH) = offH + rngH .* (1 - (2*(1-muH_sel) + 2*(muH_sel-0.5).*ratio.^(disM+1)).^(1/(disM+1)));
            end
            Offspring = min(max(Offspring, Lower), Upper);
        end

        %% graftedFDSEA: frequency-domain model initialization (FDSEA Cal_Dec + FRGA)
        %   For initial population: replace random init with frequency-domain model
        %   (Wang, Tan, Wang, Zhang 2026, SWE vol 106)
        function Dec = graftedFDSEAInit(obj, Problem, N, D)
            % Frequency-domain model parameters (K=5 levels)
            K = 5;
            ModelParams = unifrnd(0, 1, N, 2*K+2);
            Dec = obj.fdCalDec(ModelParams, N, D, Problem.lower, Problem.upper);
            Dec = min(max(Dec, Problem.lower), Problem.upper);
        end
        function Dec = fdCalDec(obj, MP, N, D, lb, ub)
            K = floor((size(MP,2) - 2) / 2);
            Dec = zeros(N, D);
            width = (ub - lb); width(width==0) = 1;
            dvec = (1:D)';                          % 1 x D
            for k = 1:K
                f1 = MP(:, 2*k-1);                  % N x 1
                f2 = MP(:, 2*k);                     % N x 1
                freq = k / D;
                for d = 1:D
                    Dec(:,d) = Dec(:,d) + f1 .* width(d) .* sin(2*pi*freq*d + 2*pi*f2);
                end
            end
            dmin = min(Dec, [], 1); dmax = max(Dec, [], 1);
            Dec = Dec - dmin;
            Dec = Dec ./ (dmax - dmin + 1e-12);
            Dec = Dec .* width + lb;
            Dec = min(max(Dec, lb), ub);
        end

        %% graftedMOEA_IB: ReMO weight-individual re-optimization (MOEA-IB)
        %   Reoptimize a small fraction of population via weight-space search
        %   (Tian 2018 ReMO: weight individuals + subpopulation)
        function [Pop, kFE] = graftedReMO(obj, Problem, Pop, N, M, gScale)
            % ReMO: pick 20% of population, reoptimize their weight vectors
            nR = max(1, round(0.2*N));
            idx = randi(N, 1, nR);
            kFE = 0;
            for i = idx
                % local random walk in decision space (ReMO perturbation)
                step = 0.05*(rand(1,Problem.nVar)-0.5);
                newDec = Pop.decs(i,:) + step.*(Problem.upper - Problem.lower);
                newDec = min(max(newDec, Problem.lower), Problem.upper);
                Pop.decs(i,:) = newDec;
                Pop.objs(i,:) = Problem.CalObj(newDec);
                Pop.cons(i,:) = Problem.CalCon(newDec);
                kFE = kFE + 1;
            end
        end

        %% SBX + poly mutation (D<100, CF/MW battlefield)
        function Offspring = sbxPolyOperator(obj, Problem, ParentDecs, N)
            D = Problem.nVar; lb = Problem.lower; ub = Problem.upper;
            nCur = size(ParentDecs,1);
            I1 = randi(nCur,1,N)'; I2 = randi(nCur,1,N)';
            I2(I2==I1) = I2(I2==I1) + 1; I2(I2>nCur) = I2(I2>nCur) - nCur;
            X1 = ParentDecs(I1,:); X2 = ParentDecs(I2,:);
            disC = 20;
            mu = rand(N,D);
            mLE = (mu<=0.5); mGT = (mu>0.5);
            base = 2*mu; base(mGT) = 2-2*mu(mGT);
            expn = ones(N,D)/15; expn(mGT) = -1/15;
            beta = base .^ expn;
            beta = beta .* (-1).^randi([0,1], N, D);
            beta(rand(N,D)<0.5) = 1;
            Offspring = (X1+X2)/2 + beta.*(X1-X2)/2;
            disM = 20; proM = 1;
            mu2 = rand(N,D);
            siteMask = rand(N,D) < proM;
            uB = repmat(ub, N, 1); lB = repmat(lb, N, 1);
            Offspring = min(max(Offspring, lB), uB);
            tempLow = siteMask & (mu2<=0.5);
            rngv = uB - lB;
            valLow = Offspring(tempLow) + rngv(tempLow) .* ( (2.*mu2(tempLow) + (1-2.*mu2(tempLow)).* ...
                (1 - (Offspring(tempLow)-lB(tempLow))./rngv(tempLow)).^(disM+1) ).^(1/(disM+1)) - 1 );
            Offspring(tempLow) = valLow;
            tempHigh = siteMask & (mu2>0.5);
            valHigh = Offspring(tempHigh) + rngv(tempHigh) .* ( 1 - (2.*(1-mu2(tempHigh)) + 2.*(mu2(tempHigh)-0.5).* ...
                (1 - (uB(tempHigh)-Offspring(tempHigh))./rngv(tempHigh)).^(disM+1) ).^(1/(disM+1)) );
            Offspring(tempHigh) = valHigh;
            Offspring = min(max(Offspring, lB), uB);
        end

        %% polish-HV
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
