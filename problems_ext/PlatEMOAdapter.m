classdef PlatEMOAdapter < Problem
    % PlatEMOAdapter - 桥接 PlatEMO 原生类（GetPF/CalObj/CalCon/Initialization）到 Problem 基类接口
    properties
        pfCache;     % 预生成 Pareto 前沿（固定种子，所有算法共享）
        baseM;       % 目标数
    end

    methods
        function obj = PlatEMOAdapter(name, M)
            base = OfficialProblem(name, M, 0);
            obj@Problem(name, base.D, M);
            obj.baseM = M;
            % 用官方原生类 GetPF 直接取 Pareto 前沿（UF/CF 族返回 M-cell 网格）
            raw = base.officialObj.GetPF();
            if iscell(raw)
                % M-cell 数组：每个是 2D 网格（M 目标用 M-1 自由参数参数化）
                n = size(raw{1}, 1);
                PF = zeros(n * n, M);
                for k = 1:M
                    PF(:, k) = raw{k}(:);
                end
            elseif ~isempty(raw)
                PF = raw;
                if size(PF, 1) == 1, PF = PF'; end
            else
                % GetPF 返回空 → 退化用 GetOptimum
                PF = base.officialObj.GetOptimum(500);
            end
            if size(PF, 1) > 1000, PF = PF(1:1000, :); end
            obj.pfCache = PF;
        end

        function F = CalObj(obj, X)
            base = OfficialProblem(obj.name, obj.baseM, obj.D);
            F = base.CalObj(X);
        end

        function CV = CalCon(obj, X)
            base = OfficialProblem(obj.name, obj.baseM, obj.D);
            CV = base.CalCon(X);
        end

        function Pop = Initialization(obj, N)
            base = OfficialProblem(obj.name, obj.baseM, obj.D);
            Pop = base.Initialization(N);
        end

        function PF = ParetoFront(obj, nPoints)
            n = min(nPoints, size(obj.pfCache,1));
            idx = round(linspace(1, size(obj.pfCache,1), n));
            PF = obj.pfCache(idx, :);
        end

        function obj = setRefPoint(obj, PF)
            obj.refPoint = 1.1 * max(PF, [], 1);
        end
    end
end