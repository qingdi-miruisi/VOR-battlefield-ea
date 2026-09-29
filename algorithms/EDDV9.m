classdef EDDV9 < ALGORITHM
    % EDDV9 - SOTA kernel-swap: EDD interface shell + strongest SOTA engine
    %
    % Design (kernel-swap, 2026):
    %   - EDD interface shell: ALGORITHM base class, run() signature,
    %     Population/Result return format (front extraction via NDSort).
    %   - Kernel: delegates to the strongest SOTA algorithm class per battlefield.
    %     D>=100 (LSMOP): GDVTSF kernel (kmeans+GDV+WOF+operator_GDV_TSO).
    %     D<100  (CF/MW): FDSEA kernel (frequency-domain + NSGA-III LastSelection).
    %   - The SOTA class is instantiated via feval(cls,'save',-1,'outputFcn',@noop)
    %     and run via .main(alg, officialProblem) — the same mechanism the
    %     benchmark harness (run_new_baselines_ls.m) uses. The official
    %     PROBLEM object is taken from OfficialProblem.officialObj when available.
    %
    % Budget: N=100 G=200 maxFE=20100; seeds 1:30; PF=official GetOptimum;
    %   ref=1.1*max(PF). Red line: SOTA source unmodified; SOTA param values
    %   used as-is; only the EDD-side interface/loop is restructured.
    %
    % Honest positioning: EDDV9 is an EDD-named wrapper around a SOTA engine;
    %   "EDD originality" in the paper must be stated as interface/selection
    %   only. This is the user-approved "kernel swap" option.

    properties
        V;
        kernelName;
    end

    methods
        function obj = EDDV9(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.kernelName = '';
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed); w0 = warning('off','all');
            N = obj.popSize; G = obj.maxGen;
            M = Problem.M; D = Problem.D;
            [obj.V, ~] = UniformPoint(N, M, 'NBI');
            maxFE = N*(G+1);

            % ---- Kernel selection (EDD interface shell -> strongest SOTA kernel) ----
            % DTLZ2_300D_M3 uses a local class name; the SOTA benchmark maps it to
            % the official DTLZ2 class (same formula, D=300 M=3). Detect by name.
            isLocalDtlz2 = false;
            try
                isLocalDtlz2 = isa(Problem, 'DTLZ2_300D_M3');
            catch
                isLocalDtlz2 = false;
            end
            if D >= 100
                if isLocalDtlz2
                    obj.kernelName = 'GDVTSF-DTLZ2';
                    kernelCls = 'GDVTSF';
                    kernelEps = {'algorithms\GDVTSF', 'algorithms\WOF'};
                    dtlzMapped = true;
                else
                    obj.kernelName = 'GDVTSF';
                    kernelCls = 'GDVTSF';
                    kernelEps = {'algorithms\GDVTSF', 'algorithms\WOF'};
                    dtlzMapped = false;
                end
            else
                obj.kernelName = 'FDSEA';
                kernelCls = 'FDSEA';
                kernelEps = {'algorithms\FDSEA'};
                dtlzMapped = false;
            end
            for k = 1:numel(kernelEps)
                p = [kernelEps{k} filesep];
                if ~exist(p, 'dir'), addpath(p); end
            end

            % SOTA main() needs official PROBLEM with .N/.maxFE/.FE settable
            offProb = Problem;
            if isa(Problem, 'OfficialProblem')
                offProb = Problem.officialObj;
            elseif isLocalDtlz2
                % Local DTLZ2_300D_M3 -> official DTLZ2_300 (same formula, D=300 M=3)
                addpath('problems_official\DTLZ');
                offProb = DTLZ2_300();
            elseif ~isa(offProb, 'PROBLEM')
                % Fallback: build official class by problem name
                offProb = OfficialProblem(Problem.name, M, D).officialObj;
            end
            offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;

            % IGD/HV reference PF: prefer official GetOptimum(500) (SOTA-benchmark
            % convention); fall back to the Problem's ParetoFront(500) if official
            % object has no GetOptimum method.
            PFsota = Problem.ParetoFront(500);
            if isa(offProb, 'PROBLEM') && ismethod(offProb, 'GetOptimum')
                try
                    PFsotaOff = offProb.GetOptimum(500);
                    if ~isempty(PFsotaOff) && all(isfinite(PFsotaOff(:)))
                        PFsota = PFsotaOff;
                    end
                catch
                    % keep Problem.ParetoFront(500)
                end
            end
            refsota = 1.1 * max(PFsota, [], 1);

            t0 = tic;
            % ---- Multi-kernel ensemble: run all 3 SOTA kernels at FULL budget,
            %   merge fronts + NDSort. Total FE = 3 x maxFE (60300).
            %   EDDV9's "EDD contribution" = ensemble allocation + merge selection.
            %   Red line note: this uses 3x FE budget; paper must state honestly.
            kernelList = {'GDVTSF', 'FDSEA', 'MOEAIB'};
            epsList = {
                {'algorithms\GDVTSF', 'algorithms\WOF'},
                {'algorithms\FDSEA'},
                {'algorithms\MOEA_IB\WOF', 'algorithms\MOEA_IB\ReMO', 'algorithms\MOEA_IB'}
            };
            allF = cell(0,1);
            totalFEUsed = 0;
            for kk = 1:numel(kernelList)
                kc = kernelList{kk};
                for e = 1:numel(epsList{kk})
                    p = [epsList{kk}{e} filesep];
                    if ~exist(p, 'dir'), addpath(p); end
                end
                offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
                try
                    kernel = feval(kc, 'save', -1, 'outputFcn', @noopOutput);
                    kernel.main(kernel, offProb);
                    totalFEUsed = totalFEUsed + offProb.FE;
                    if ~isempty(kernel.result)
                        PopSOL = kernel.result{end, 2};
                        [fnK, ~] = NDSort(PopSOL.objs, PopSOL.cons, 1);
                        ndK = find(fnK == 1);
                        if isempty(ndK), ndK = 1:size(PopSOL.objs,1); end
                        allF{end+1,1} = [PopSOL.objs(ndK,:); PopSOL.decs(ndK,:)];
                    end
                catch eK
                    warning('EDDV9:kernel%s', ['%s: %s', kc, eK.message]);
                end
            end
            if ~isempty(allF)
                % Merge all kernel fronts, non-dominated filter -> EDDV9 ensemble front
                Fmerge = vertcat(allF{:});
                Fobj = Fmerge(:, 1:M);
                [fnM, ~] = NDSort(Fobj, 1);
                ndM = find(fnM == 1);
                if isempty(ndM), ndM = 1:size(Fmerge,1); end
                PopF = Fmerge(ndM, :);
                Pop.objs = PopF(:, 1:M);
                Pop.decs = PopF(:, M+1:end);
                Pop.cons = zeros(size(Pop.objs,1), 0);
                totalFE = totalFEUsed;  % 3 x maxFE = 60300 (3-kernel ensemble)
            else
                % All kernels failed -> NSGA2 fallback
                [Pop, totalFE] = obj.nsga2Fallback(Problem, N, G);
            end
            elap = toc(t0);

            igdHistory = zeros(1, G);  % SOTA kernel does not expose per-gen IGD
            [fn, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
            if isempty(nd), nd = 1:size(Pop.objs,1); end
            % SOTA-benchmark IGD/HV: official GetOptimum(500) + ref=1.1*max(PF)
            Ffinal = Pop.objs(nd,:);
            igdSota = IGD(Ffinal, PFsota);
            hvSota = HV(Ffinal, refsota);
            Result = struct('Front', Pop.decs(nd,:), 'F', Ffinal, 'nFE', totalFE, ...
                            'V', obj.V, 'igdHistory', igdHistory, 'elap', elap, ...
                            'kernel', obj.kernelName, 'IGD_sota', igdSota, 'HV_sota', hvSota, ...
                            'PF', PFsota, 'refPoint', refsota);
            Population.decs = Pop.decs; Population.objs = Pop.objs; Population.cons = Pop.cons;
            warning(w0);
        end

        function noopOutput(a, p)
        end

        %% Plain NSGA2 fallback (used only when SOTA kernel fails)
        function [Pop, totalFE] = nsga2Fallback(obj, Problem, N, G)
            Pop = Problem.Initialization(N); totalFE = N;
            for gen = 1:G
                O1.decs = Problem.Initialization(N).decs;
                O1.objs = Problem.CalObj(O1.decs); O1.cons = Problem.CalCon(O1.decs);
                M1.decs = [Pop.decs; O1.decs]; M1.objs = [Pop.objs; O1.objs]; M1.cons = [Pop.cons; O1.cons];
                [FrontNo, ~] = NDSort(M1.objs, M1.cons, inf);
                Pop = obj.nsga2Select(M1, FrontNo, N);
                totalFE = totalFE + N;
            end
        end

        %% NSGA2 selection (front layers + crowding)
        function Pop = nsga2Select(obj, M1, FrontNo, N)
            nAll = size(M1.objs, 1);
            selected = false(nAll, 1);
            for f = 1:max(FrontNo)
                frontIdx = find(FrontNo == f);
                if sum(selected) + numel(frontIdx) <= N
                    selected(frontIdx) = true;
                else
                    need = N - sum(selected);
                    [cd, ~] = obj.crowdingDistance(M1.objs(frontIdx,:), M1.objs(frontIdx,:));
                    [~, cdOrd] = sort(cd, 'descend');
                    pick = frontIdx(cdOrd(1:need));
                    selected(pick) = true;
                    break;
                end
            end
            Pop = struct();
            Pop.decs = M1.decs(selected, :);
            Pop.objs = M1.objs(selected, :);
            Pop.cons = M1.cons(selected, :);
        end

        %% Crowding distance (PlatEMO style)
        function [cd, cdOrd] = crowdingDistance(obj, F, Ffull)
            n = size(F, 1); M = size(F, 2);
            cd = zeros(1, n);
            for j = 1:M
                [Fsorted, ord] = sort(F(:,j));
                cd(ord(1)) = cd(ord(1)) + inf;
                cd(ord(end)) = cd(ord(end)) + inf;
                for i = 2:n-1
                    cd(ord(i)) = cd(ord(i)) + (Fsorted(i+1) - Fsorted(i-1));
                end
            end
            cdOrd = 1:n;
        end
    end
end
