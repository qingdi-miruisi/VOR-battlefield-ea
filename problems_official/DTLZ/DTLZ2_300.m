classdef DTLZ2_300 < PROBLEM
% DTLZ2_300 - 官方 PlatEMO DTLZ2 类，M=3 D=300 固定配置（本项目交叉验证题）
% 公式与本地 problems\DTLZ2_300D_M3.m 完全一致：
%   g = sum((x_3:end-1 - 0.5)^2)，PF = 单位球第一卦限，范围 [0,1]^300
% 独立类名 DTLZ2_300 避免与 problems\DTLZ2.m（本地 Problem 子类）类名冲突。
% 注意：官方 GetOptimum 在 M=3 时返回 91 点（UniformPoint 固定点数）。

    methods
        %% 固定 M=3, D=300
        function Setting(obj)
            obj.M = 3;
            obj.D = 300;
            obj.lower    = zeros(1, obj.D);
            obj.upper    = ones(1, obj.D);
            obj.encoding = ones(1, obj.D);
        end
        %% 官方 DTLZ2 公式原样
        function PopObj = CalObj(obj, PopDec)
            M = obj.M;
            g = sum((PopDec(:, M:end) - 0.5).^2, 2);
            PopObj = repmat(1 + g, 1, M) .* fliplr(cumprod([ones(size(g,1),1), cos(PopDec(:,1:M-1)*pi/2)], 2)) ...
                     .* [ones(size(g,1),1), sin(PopDec(:, M-1:-1:1)*pi/2)];
        end
        %% 官方 GetOptimum 原样
        function R = GetOptimum(obj, N)
            R = UniformPoint(N, obj.M);
            R = R ./ repmat(sqrt(sum(R.^2, 2)), 1, obj.M);
        end
    end
end
