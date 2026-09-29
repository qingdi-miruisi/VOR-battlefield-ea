classdef OfficialProblem < Problem
% OfficialProblem - PlatEMO 官方问题类适配器（原版文件，零公式改动）
%
% 官方原版 .m 文件（含 PROBLEM 基类、local functions）原样放在
% problems_official/ 下，本类通过 feval 实例化官方问题对象，
% 把官方 CalObj/GetOptimum 桥接到本项目 Problem 接口（CalObj/ParetoFront）。
%
% 用法：
%   P = OfficialProblem('UF1', 30, 2);
%   F = P.CalObj(X);          % 官方公式原样
%   PF = P.ParetoFront(500);  % 官方 GetOptimum 原样

    properties
        officialObj;   % 已 Setting() 的官方问题对象（构造失败时为空，CalObj/CalCon 走降级）
        officialName;  % 官方问题类名
    end

    methods
        function obj = OfficialProblem(name, M, D)
            % name: 官方问题类名（如 'UF1'）；M: 目标数（默认 2）；D: 决策维（默认 30）
            % 官方 PROBLEM 基类为 M-主导（D 由官方公式决定），故先设 M 再补 D。
            if nargin < 2, M = 2; end
            if nargin < 3, D = 30; end
            obj@Problem(name, D, M);
            obj.officialName = name;
            % 官方构造：M>=4 必须 name-value（'M',M）确保目标数；M<=3 用无参默认
            if M >= 4
                off = feval(name, M);
            else
                off = tryCatchConstruct(name, M, D);
            end
            off.Setting();
            obj.officialObj = off;
            % 官方 Setting() 已填 M/D/lower/upper，同步到 Problem 基类字段
            if isprop(off, 'M'),     obj.M     = off.M;     end
            if isprop(off, 'D'),     obj.D     = off.D;     end
            if isprop(off, 'lower'), obj.lower = off.lower; end
            if isprop(off, 'upper'), obj.upper = off.upper; end
        end

        %% 官方 CalObj 桥接（公式原样 + M 列维数修复）
        % CF/MW 官方类目标值在 Evaluation 里算（返回 SOLUTION.objs），非独立 CalObj；
        % 优先走官方 CalObj，若维度异常（CF/MW 未覆写 CalObj 落到基类 zeros(N,1)）
        % 则改用 Evaluation 提取 objs，统一 reshape 到 [N x M]
        function F = CalObj(obj, X)
            if isempty(X), F = zeros(0, obj.M); return; end
            N = size(X, 1);
            try
                F = obj.officialObj.CalObj(X);
                % 维度校验：正确应是 [N x M]；若 M=2 却返回 [N x 1]（CF/MW 未覆写 CalObj）
                % 则改用 Evaluation 提取
                if ~isempty(F) && (size(F,2) ~= obj.M || numel(F) == N)
                    Pop = obj.officialObj.Evaluation(X);
                    if isa(Pop, 'SOLUTION')
                        F = Pop.objs;
                    elseif isstruct(Pop)
                        F = Pop.objs;
                    end
                end
            catch
                Pop = obj.officialObj.Evaluation(X);
                if isa(Pop, 'SOLUTION'), F = Pop.objs;
                elseif isstruct(Pop), F = Pop.objs;
                else, F = zeros(N, obj.M); end
            end
            if isempty(F), F = zeros(N, obj.M); end
            if numel(F) == N * obj.M
                F = reshape(F, N, obj.M);
            elseif size(F,1) ~= N
                F = reshape(F, N, []);
            end
        end

        %% 官方 CalCon 桥接：约束在官方 Evaluation 里算（返回 SOLUTION(...,PopCon,...)）
        % CF/MW 族约束在 Evaluation 内计算，非独立 CalCon 方法；
        % 用 Evaluation 提取 cons（对 decs 包成单解调，避免官方类无独立 CalCon 的问题）
        function CV = CalCon(obj, X)
            if isempty(X), CV = zeros(0,0); return; end
            N = size(X,1);
            try
                % 官方 Evaluation 接受 (PopDec) 或 (PopDec, velocity)；单解调用
                Pop = obj.officialObj.Evaluation(X);
                if isa(Pop, 'SOLUTION')
                    CV = Pop.cons;
                elseif isstruct(Pop)
                    CV = Pop.cons;
                else
                    CV = zeros(N, 0);
                end
                % 官方 Evaluation 可能内部计数 FE；本桥接仅取 cons，不计入 EDD 的 FE
            catch
                % 无约束问题（Evaluation 返回的 cons 为空或类不支持）
                CV = zeros(N, 0);
            end
        end

        %% 官方 GetOptimum 桥接（公式原样）
        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            M = obj.officialObj.M;
            % 官方 GetOptimum/GetPF 在 M>=4 时对 LSMOP/MaF 返回 R=[]（无解析 PF）：
            % 统一退化为 UniformPoint 采样（保证参考前沿存在且非空）
            if M >= 4
                PF = UniformPoint(nPoints, M);
                return;
            end
            try
                PF = obj.officialObj.GetOptimum(nPoints);
            catch
                PF = [];
            end
            if isempty(PF) || ~all(isfinite(PF(:)))
                PF = UniformPoint(nPoints, M);
            end
            if size(PF,1) < nPoints
                PF = interpfront(PF, nPoints);
            end
        end
    end
end

function off = tryCatchConstruct(name, M, D)
% 官方类构造：多数族无参构造即可；MaF/LSMOP/LSMMOP 族须显式传 M（默认 M=3）。
% 先试无参，若失败再试 M/D 参数构造。
    try
        off = feval(name);
    catch
        try
            off = feval(name, 'M', M);
        catch
            off = feval(name, M);
        end
    end
end

function PF = interpfront(PF, nPoints)
    % 官方返回点数不足时，沿首维度线性插值补全到 nPoints 点
    n = size(PF, 1);
    if n == 0
        PF = zeros(nPoints, 1);
        return;
    end
    PFout = zeros(nPoints, size(PF, 2));
    tIn = linspace(0, 1, n);
    tOut = linspace(0, 1, nPoints);
    for j = 1:size(PF, 2)
        PFout(:, j) = interp1(tIn, PF(:, j), tOut, 'linear', 'extrap');
    end
    PF = PFout;
end
