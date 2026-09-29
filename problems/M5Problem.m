classdef M5Problem < Problem
    % M5Problem - M>=5 高维多目标基准包装器（官方 PlatEMO 公式原样桥接）
    %
    % 为 EDD v6 新战场（M>=5 + D 中等/大）提供统一本地 Problem 接口：
    %   - MaF14/MaF15  M=5/8/10（D 自动=20M：100/160/200，官方默认 D）
    %   - DTLZ2_300   M=5/8（D=300 固定，官方 DTLZ2 公式，PF=解析球面）
    %
    % 口径约定（任务2 决策1）：
    %   - MaF14/15 M>=5 无解析 PF → UniformPoint(500) 采样参考前沿（与官方 GetPF R=[] 一致）
    %   - DTLZ2_300 M=5/8 PF → UniformPoint(500) 归一化球面（解析第一卦限）
    %   所有算法同口径。
    %
    % 构造：M5Problem('MaF14', M, D)
    %   M5Problem('MaF14', 5, 100)   % D 可不传，自动 20M=100
    %   M5Problem('DTLZ2_300', 5, 300)

    properties
        officialObj;   % 已 Setting() 的官方 PROBLEM 对象
    end

    methods
        function obj = M5Problem(name, M, D)
            obj@Problem(name, D, M);
            if nargin < 2 || isempty(M), M = 5; end
            % 官方构造：MaF14/MaF15/DTLZ2 都接受 'M'/'D' name-value
            if ~isempty(D)
                off = feval(name, 'M', M, 'D', D);
            else
                off = feval(name, 'M', M);
            end
            % MaF 默认 D=20M，DTLZ2_300 固定 D=300；若用户未指定 D 则用官方默认
            if nargin < 3 || isempty(D)
                D = off.D;
            end
            off.Setting();
            obj.officialObj = off;
            obj.M = off.M; obj.D = off.D;
            if isprop(off, 'lower'), obj.lower = off.lower; end
            if isprop(off, 'upper'), obj.upper = off.upper; end
        end

        %% 官方 CalObj 桥接（公式原样）
        function F = CalObj(obj, X)
            F = obj.officialObj.CalObj(X);
            if size(F,1) ~= size(X,1)
                F = reshape(F, size(X,1), []);
            end
        end

        function CV = CalCon(obj, X)
            if ismethod(obj.officialObj, 'CalCon')
                CV = obj.officialObj.CalCon(X);
            else
                CV = zeros(size(X,1), 0);
            end
        end

        %% PF 口径（任务2 决策1）：
        %%   MaF14/15 M>=5 无解析 PF → UniformPoint(500)
        %%   DTLZ2_300 M=5/8 → UniformPoint(500) 归一化球面（解析第一卦限）
        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            M = obj.M;
            PF = UniformPoint(nPoints, M);
            % DTLZ2 族：归一化到单位球第一卦限（g=0 时 f=cos/sin 组合 → 球面）
            if strcmp(obj.name, 'DTLZ2_300')
                PF = PF ./ sqrt(sum(PF.^2, 2));
            end
        end

        function Pop = Initialization(obj, N)
            if nargin < 2, N = 100; end
            % 用官方 bounds 随机初始化（MaF14/15 的 upper 是 [1...1 10...10]）
            lb = obj.lower; ub = obj.upper;
            Pop.decs = lb + rand(N, obj.D) .* (ub - lb);
            Pop.objs = obj.CalObj(Pop.decs);
            Pop.cons = obj.CalCon(Pop.decs);
        end
    end
end
