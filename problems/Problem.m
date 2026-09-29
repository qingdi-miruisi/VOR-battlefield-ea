classdef Problem < handle
% Problem - 多目标测试问题统一基类（可复现版，PlatEMO 接口对齐）
%
% 统一接口（与 ALGORITHM 基类配套）：
%   obj = ProblemName(D, M);
%   Pop = obj.Initialization(N);        % struct(decs,objs,cons)
%   F   = obj.CalObj(X);              % [K x M]
%   CV  = obj.CalCon(X);              % [K x C]，无约束返回 [K x 0]
%   PF  = obj.ParetoFront(nPoints);   % 固定解析前沿，[nPoints x M]
%
% PlatEMO 旧接口兼容（部分基线算法使用 Problem.F / Problem.Cons）：
%   F  = obj.F(X);    % 等价于 CalObj
%   CV = obj.Cons(X); % 等价于 CalCon
%
% 参考前沿约定（学术诚信要求）：
%   - 解析前沿：精确公式，无随机性；
%   - 无解析前沿的问题（MaF、LSMOP、真实问题、昂贵问题）：使用
%     高精度预生成（固定 rng 种子 2026，10^5 候选点非支配过滤），
%     统一存于 problems/fronts/PF_<Name>.mat，所有算法共享同一参考集。
%
% 属性：
%   D       决策维数
%   M       目标数
%   lower   决策下界（若为 cell 则按变量，否则统一标量）
%   upper   决策上界
%   nCon    约束个数（0 = 无约束）
%   refPoint HV 参考点（默认 1.1*max(PF,2.1)，由 setRefPoint 统一计算）

    properties
        D; M;
        lower; upper;
        nCon;
        refPoint;
        name;
    end

    methods
        function obj = Problem(name, D, M)
            if nargin < 1, error('Problem:badArg','需要 name'); end
            if nargin < 2, D = 30; end
            if nargin < 3, M = 2; end
            obj.name  = name;
            obj.D     = D;
            obj.M     = M;
            obj.nCon  = 0;
            obj.lower = zeros(1, D);
            obj.upper = ones(1, D);
            obj.refPoint = [];
        end

        function Pop = Initialization(obj, N)
            Pop.decs = obj.lower + rand(N, obj.D) .* (obj.upper - obj.lower);
            Pop.objs = obj.CalObj(Pop.decs);
            Pop.cons = obj.CalCon(Pop.decs);
        end

        function F = CalObj(obj, X)
            error('Problem:notImplemented', '子类必须实现 CalObj(X)');
        end

        function CV = CalCon(obj, X)
            CV = zeros(size(X,1), 0);
        end

        function PF = ParetoFront(obj, nPoints)
            error('Problem:notImplemented', '子类必须实现 ParetoFront(nPoints)');
        end

        function obj = setRefPoint(obj, PF)
            % 统一 HV 参考点：1.1 * max(PF)（逐目标），与既有实验保持一致
            obj.refPoint = 1.1 * max(PF, [], 1);
        end

        % ---- PlatEMO 旧接口兼容（供基线算法调用）----
        function F = F(obj, X)
            F = obj.CalObj(X);
        end

        function CV = Cons(obj, X)
            CV = obj.CalCon(X);
        end

        function M = nObj(obj)
            M = obj.M;
        end

        function D = nVar(obj)
            D = obj.D;
        end
    end
end
