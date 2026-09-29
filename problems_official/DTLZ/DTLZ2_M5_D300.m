classdef DTLZ2_M5_D300 < PROBLEM
    % DTLZ2_M5_D300 - 官方 DTLZ2 公式原样，M=5 D=300 固定配置
    % （M5 预筛/全量题；PF=解析球面 UniformPoint 归一化，与官方 GetOptimum M>=4 退化口径一致）
    methods
        function Setting(obj)
            obj.M = 5;
            obj.D = 300;
            obj.lower    = zeros(1, obj.D);
            obj.upper    = ones(1, obj.D);
            obj.encoding = ones(1, obj.D);
        end
        % 官方 DTLZ2 CalObj 公式原样
        function PopObj = CalObj(obj, PopDec)
            g      = sum((PopDec(:, obj.M:end) - 0.5).^2, 2);
            PopObj = repmat(1 + g, 1, obj.M) .* fliplr(cumprod([ones(size(g,1),1), cos(PopDec(:,1:obj.M-1)*pi/2)], 2)) ...
                     .* [ones(size(g,1),1), sin(PopDec(:, obj.M-1:-1:1)*pi/2)];
        end
        % 官方 GetOptimum 原样（M>=4 归一化球面）
        function R = GetOptimum(obj, N)
            R = UniformPoint(N, obj.M);
            R = R ./ repmat(sqrt(sum(R.^2, 2)), 1, obj.M);
        end
    end
end
