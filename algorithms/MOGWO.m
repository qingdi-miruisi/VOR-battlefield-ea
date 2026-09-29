classdef MOGWO < ALGORITHM
% MOGWO - 多目标灰狼优化算法（忠实移植 Mirjalili 2016 原版逻辑）
% 参考：S. Mirjalili et al. "Multi-objective grey wolf optimizer: A novel algorithm
%       for multi-criterion optimization." Expert Systems with Applications, 2016, 51: 185-196.
% 源码：http://www.alimirjalili.com/GWO.html（MATLAB Central #55979）

    properties
        archive;
        archive_size;
        nGrid;
        beta;
        gamma;
        alphaParam;
        G;
    end

    methods
        function obj = MOGWO(popSize, maxGen, seed)
            obj@ALGORITHM(popSize, maxGen, seed);
            obj.archive_size = 100;
            obj.nGrid = 10;
            obj.beta = 4;
            obj.gamma = 2;
            obj.alphaParam = 0.1;
        end

        function [Population, Result] = run(obj, Problem)
            rng(obj.seed);
            nVar = Problem.nVar;
            lb = Problem.lower;
            ub = Problem.upper;

            %% 初始化狼群（忠实 Mirjalili 原版）
            GreyWolves = obj.createEmptyParticle(obj.popSize);
            for i = 1:obj.popSize
                GreyWolves(i).Position = lb + rand(1, nVar) .* (ub - lb);
                GreyWolves(i).Cost = Problem.F(GreyWolves(i).Position);
                GreyWolves(i).Best.Position = GreyWolves(i).Position;
                GreyWolves(i).Best.Cost = GreyWolves(i).Cost;
            end

            GreyWolves = obj.determineDomination(GreyWolves);
            obj.archive = obj.getNonDominatedParticles(GreyWolves);
            if ~isempty(obj.archive)
                Archive_costs = obj.getCosts(obj.archive);
                obj.G = obj.createHypercubes(Archive_costs, obj.nGrid, obj.alphaParam);
                for i = 1:numel(obj.archive)
                    [obj.archive(i).GridIndex, obj.archive(i).GridSubIndex] = ...
                        obj.getGridIndex(obj.archive(i), obj.G);
                end
            end

            %% 主优化循环（忠实 Mirjalili 原版）
            MaxIt = obj.maxGen;
            for it = 1:MaxIt
                a = 2 - it .* (2 / MaxIt);
                for i = 1:obj.popSize
                    Delta = obj.selectLeader(obj.archive, obj.beta);
                    Beta  = obj.selectLeader(obj.archive, obj.beta);
                    Alpha = obj.selectLeader(obj.archive, obj.beta);

                    c = 2 .* rand(1, nVar);
                    D = abs(c .* Delta.Position - GreyWolves(i).Position);
                    A = 2 .* a .* rand(1, nVar) - a;
                    X1 = Delta.Position - A .* D;

                    c = 2 .* rand(1, nVar);
                    D = abs(c .* Beta.Position - GreyWolves(i).Position);
                    A = 2 .* a .* rand() - a;
                    X2 = Beta.Position - A .* D;

                    c = 2 .* rand(1, nVar);
                    D = abs(c .* Alpha.Position - GreyWolves(i).Position);
                    A = 2 .* a .* rand() - a;
                    X3 = Alpha.Position - A .* D;

                    GreyWolves(i).Position = (X1 + X2 + X3) / 3;
                    GreyWolves(i).Position = min(max(GreyWolves(i).Position, lb), ub);
                    GreyWolves(i).Cost = Problem.F(GreyWolves(i).Position);
                end

                %% 支配判定 + 非支配提取
                GreyWolves = obj.determineDomination(GreyWolves);
                non_dominated_wolves = obj.getNonDominatedParticles(GreyWolves);

                %% 存档管理（忠实 Mirjalili 原版）
                if ~isempty(non_dominated_wolves)
                    obj.archive = [obj.archive; non_dominated_wolves];
                end
                if ~isempty(obj.archive)
                    obj.archive = obj.determineDomination(obj.archive);
                    obj.archive = obj.getNonDominatedParticles(obj.archive);
                    % 重新计算超立方体网格（基于当前存档）
                    if ~isempty(obj.archive)
                        Archive_costs = obj.getCosts(obj.archive);
                        obj.G = obj.createHypercubes(Archive_costs, obj.nGrid, obj.alphaParam);
                    end
                    % 为所有存档粒子计算 GridIndex
                    for i = 1:numel(obj.archive)
                        [obj.archive(i).GridIndex, obj.archive(i).GridSubIndex] = ...
                            obj.getGridIndex(obj.archive(i), obj.G);
                    end
                    % 超出存档容量则删除（忠实 DeleteFromRep）
                    if numel(obj.archive) > obj.archive_size
                        EXTRA = numel(obj.archive) - obj.archive_size;
                        obj.archive = obj.deleteFromRep(obj.archive, EXTRA, obj.gamma);
                        if numel(obj.archive) > obj.archive_size
                            keepIdx = randperm(numel(obj.archive), obj.archive_size);
                            obj.archive = obj.archive(keepIdx);
                        end
                        Archive_costs = obj.getCosts(obj.archive);
                        obj.G = obj.createHypercubes(Archive_costs, obj.nGrid, obj.alphaParam);
                        % 重新计算 GridIndex
                        for i = 1:numel(obj.archive)
                            [obj.archive(i).GridIndex, obj.archive(i).GridSubIndex] = ...
                                obj.getGridIndex(obj.archive(i), obj.G);
                        end
                    end
                end
            end

            %% 结果
            nArch = numel(obj.archive);
            if nArch > 0
                frontDecs = zeros(nArch, Problem.nVar);
                for i = 1:nArch
                    frontDecs(i,:) = obj.archive(i).Position;
                end
                frontObjs = obj.getCosts(obj.archive)';
            else
                frontDecs = zeros(0, Problem.nVar);
                frontObjs = zeros(0, Problem.nObj);
            end
            Result = struct('Front', frontDecs, ...
                            'F',    frontObjs, ...
                            'nFE',  obj.popSize * (obj.maxGen + 1));
            Population = struct('decs', frontDecs, ...
                                'objs', frontObjs, 'cons', []);
        end

        %% ==================== Mirjalili 原版辅助方法 ====================

        function particle = createEmptyParticle(obj, n)
            empty_particle.Position = [];
            empty_particle.Velocity = [];
            empty_particle.Cost = [];
            empty_particle.Dominated = false;
            empty_particle.Best.Position = [];
            empty_particle.Best.Cost = [];
            empty_particle.GridIndex = [];
            empty_particle.GridSubIndex = [];
            particle = repmat(empty_particle, n, 1);
        end

        function rep_h = selectLeader(obj, rep, beta)
            if nargin < 3
                beta = 1;
            end
            if isempty(rep)
                rep_h = rep;
                return;
            end
            [occ_cell_index, occ_cell_member_count] = obj.getOccupiedCells(rep);
            if isempty(occ_cell_index)
                rep_h = rep(1);
                return;
            end
            p = occ_cell_member_count .^ (-beta);
            p = p / sum(p);
            selected_cell_index = occ_cell_index(obj.rouletteWheelSelection(p));
            GridIndices = [rep.GridIndex];
            selected_cell_members = find(GridIndices == selected_cell_index);
            if isempty(selected_cell_members)
                selected_cell_members = 1;
            end
            n = numel(selected_cell_members);
            h = selected_cell_members(randi(n));
            h = min(h, numel(rep));
            rep_h = rep(h);
        end

        function i = rouletteWheelSelection(obj, p)
            r = rand;
            c = cumsum(p);
            i = find(r <= c, 1, 'first');
            if isempty(i), i = numel(p); end
        end

        function rep = deleteFromRep(obj, rep, EXTRA, gamma)
            % 忠实 Mirjalili DeleteFromRep.m
            if isempty(rep)
                return;
            end
            for k = 1:EXTRA
                if isempty(rep), return; end
                [occ_cell_index, occ_cell_member_count] = obj.getOccupiedCells(rep);
                if isempty(occ_cell_index), return; end
                p = occ_cell_member_count .^ gamma;
                p = p / sum(p);
                selected_cell_index = occ_cell_index(obj.rouletteWheelSelection(p));
                GridIndices = [rep.GridIndex];
                selected_cell_members = find(GridIndices == selected_cell_index);
                if isempty(selected_cell_members)
                    selected_cell_members = 1;
                end
                j = selected_cell_members(randi(numel(selected_cell_members)));
                j = min(j, numel(rep));
                if j == 1
                    rep = rep(2:end);
                elseif j == numel(rep)
                    rep = rep(1:j-1);
                else
                    rep = [rep(1:j-1); rep(j+1:end)];
                end
            end
        end

        function [Index, SubIndex] = getGridIndex(obj, particle, G)
            c = particle.Cost;
            nobj = numel(c);
            ngrid = numel(G(1).Upper);
            SubIndex = zeros(1, nobj);
            for j = 1:nobj
                U = G(j).Upper;
                i = find(c(j) < U, 1, 'first');
                if isempty(i), i = ngrid; end
                SubIndex(j) = i;
            end
            Index = sub2ind(ones(1, nobj) * ngrid, SubIndex);
        end

        function nd_pop = getNonDominatedParticles(obj, pop)
            if isempty(pop)
                nd_pop = pop;
                return;
            end
            ND = ~[pop.Dominated];
            nd_pop = pop(ND);
        end

        function pop = determineDomination(obj, pop)
            if isempty(pop)
                return;
            end
            npop = numel(pop);
            for i = 1:npop
                pop(i).Dominated = false;
                for j = 1:i-1
                    if ~pop(j).Dominated
                        if obj.dominates(pop(i), pop(j))
                            pop(j).Dominated = true;
                        elseif obj.dominates(pop(j), pop(i))
                            pop(i).Dominated = true;
                            break;
                        end
                    end
                end
            end
        end

        function dom = dominates(obj, x, y)
            if isstruct(x), x = x.Cost; end
            if isstruct(y), y = y.Cost; end
            dom = all(x <= y) && any(x < y);
        end

        function [occ_cell_index, occ_cell_member_count] = getOccupiedCells(obj, pop)
            if isempty(pop)
                occ_cell_index = [];
                occ_cell_member_count = [];
                return;
            end
            GridIndices = [pop.GridIndex];
            occ_cell_index = unique(GridIndices);
            occ_cell_member_count = zeros(size(occ_cell_index));
            m = numel(occ_cell_index);
            for k = 1:m
                occ_cell_member_count(k) = sum(GridIndices == occ_cell_index(k));
            end
        end

        function G = createHypercubes(obj, costs, ngrid, alpha)
            nobj = size(costs, 1);
            empty_grid.Lower = [];
            empty_grid.Upper = [];
            G = repmat(empty_grid, nobj, 1);
            for j = 1:nobj
                min_cj = min(costs(j, :));
                max_cj = max(costs(j, :));
                dcj = alpha * (max_cj - min_cj);
                min_cj = min_cj - dcj;
                max_cj = max_cj + dcj;
                gx = linspace(min_cj, max_cj, ngrid - 1);
                G(j).Lower = [-inf gx];
                G(j).Upper = [gx inf];
            end
        end

        function costs = getCosts(obj, pop)
            % 忠实 Mirjalili 原版：返回 [nObj x nPop]
            n = numel(pop);
            if n == 0
                costs = [];
                return;
            end
            nobj = numel(pop(1).Cost);
            costs = zeros(nobj, n);
            for i = 1:n
                costs(:, i) = pop(i).Cost;
            end
        end
    end
end
