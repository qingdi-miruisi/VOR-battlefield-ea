classdef ZDT2 < Problem
% ZDT2 - 2 目标基准问题（PlatEMO 官方原版，向量化实现）
% 决策变量：D 维（默认 30），[0,1]
% 目标：f1 = x1, f2 = g*(1 - (f1/g)^2)
% 真实前沿：g=1 时 f2 = 1 - f1^2, f1 in [0,1]
%
% 参考：E. Zitzler, K. Deb, L. Thiele. Comparison of multiobjective
%       evolutionary algorithms: Empirical results.
%       Evolutionary Computation, 2000, 8(2): 173-195.
%
% PlatEMO 官方 CalObj（向量化，本文件完全保持此公式）：
%   PopObj(:,1) = PopDec(:,1);
%   g = 1 + 9*mean(PopDec(:,2:end),2);
%   h = 1 - (PopObj(:,1)./g).^2;
%   PopObj(:,2) = g.*h;
%
% PlatEMO 官方 GetOptimum（本文件 ParetoFront 完全保持）：
%   R(:,1) = linspace(0,1,N)';
%   R(:,2) = 1 - R(:,1).^2;
%
% Copyright (c) 2026 BIMK Group

    methods
        function obj = ZDT2(D)
            if nargin < 1, D = 30; end
            obj@Problem('ZDT2', D, 2);
        end

        function Obj = CalObj(obj, Dec)
            % 忠实 PlatEMO 官方 ZDT2.m CalObj 向量化公式
            [N, ~] = size(Dec);
            Obj = zeros(N, 2);
            Obj(:, 1) = Dec(:, 1);
            g = 1 + 9 * mean(Dec(:, 2:end), 2);
            h = 1 - (Obj(:, 1) ./ g).^2;
            Obj(:, 2) = g .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            % 忠实 PlatEMO 官方 ZDT2.m GetOptimum
            if nargin < 2, nPoints = 100; end
            PF = zeros(nPoints, 2);
            PF(:, 1) = linspace(0, 1, nPoints)';
            PF(:, 2) = 1 - PF(:, 1).^2;
        end
    end
end

