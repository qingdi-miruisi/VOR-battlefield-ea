classdef ZDT3 < Problem
% ZDT3 - 2 目标基准问题（PlatEMO 官方原版，向量化实现）
% 决策变量：D 维（默认 30），[0,1]
% 目标：f1 = x1, f2 = g*(1 - sqrt(f1/g) - (f1/g)*sin(10*pi*f1))
% 真实前沿：g=1 时不连续前沿（由非支配过滤得到多段）
%
% 参考：E. Zitzler, K. Deb, L. Thiele. Comparison of multiobjective
%       evolutionary algorithms: Empirical results.
%       Evolutionary Computation, 2000, 8(2): 173-195.
%
% PlatEMO 官方 CalObj（向量化，本文件完全保持此公式）：
%   PopObj(:,1) = PopDec(:,1);
%   g = 1 + 9*mean(PopDec(:,2:end),2);
%   h = 1 - (PopObj(:,1)./g).^0.5 - PopObj(:,1)./g.*sin(10*pi*PopObj(:,1));
%   PopObj(:,2) = g.*h;
%
% PlatEMO 官方 GetOptimum（本文件 ParetoFront 完全保持语义）：
%   R(:,1) = linspace(0,1,N)';
%   R(:,2) = 1 - R(:,1).^0.5 - R(:,1).*sin(10*pi*R(:,1));
%   R      = R(NDSort(R,1)==1,:);
%   注：PlatEMO 中 NDSort(R,1) 为两参调用（第 2 参 = 需排序个数），
%   即"只求第一前沿"；本工作区 NDSort 为三参 (PopObj, cons, nSort)，
%   故等价写作 NDSort(R, zeros(size(R,1),0), 1) == 1。
%
% Copyright (c) 2026 BIMK Group

    methods
        function obj = ZDT3(D)
            if nargin < 1, D = 30; end
            obj@Problem('ZDT3', D, 2);obj.M = 2;
        end

        function Obj = CalObj(obj, Dec)
            % 忠实 PlatEMO 官方 ZDT3.m CalObj 向量化公式
            [N, ~] = size(Dec);
            Obj = zeros(N, 2);
            Obj(:, 1) = Dec(:, 1);
            g = 1 + 9 * mean(Dec(:, 2:end), 2);
            h = 1 - (Obj(:, 1) ./ g).^0.5 - Obj(:, 1) ./ g .* sin(10 * pi * Obj(:, 1));
            Obj(:, 2) = g .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            % 忠实 PlatEMO 官方 ZDT3.m GetOptimum（NDSort 第一前沿过滤）
            if nargin < 2, nPoints = 100; end
            R = zeros(nPoints, 2);
            R(:, 1) = linspace(0, 1, nPoints)';
            R(:, 2) = 1 - R(:, 1).^0.5 - R(:, 1) .* sin(10 * pi * R(:, 1));
            R = R(NDSort(R, zeros(size(R,1), 0), 1) == 1, :);
            PF = R;
        end
    end
end

