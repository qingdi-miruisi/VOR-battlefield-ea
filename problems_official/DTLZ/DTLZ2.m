classdef DTLZ2 < PROBLEM
% <2005> <multi/many> <real> <large/none> <expensive/none>
% DTLZ2 - PlatEMO official formula (Deb, Thiele, Laumanns, Zitzler 2005)
% Setting() 支持任意 M（M≥5 时 D=M+9，GetOptimum 返回单位球投影 UniformPoint）

    methods
        %% Default settings of the problem
        function Setting(obj)
            if isempty(obj.M); obj.M = 3; end
            if isempty(obj.D); obj.D = obj.M + 9; end
            obj.lower    = zeros(1, obj.D);
            obj.upper    = ones(1, obj.D);
            obj.encoding = ones(1, obj.D);
        end
        %% Calculate objective values
        function PopObj = CalObj(obj, PopDec)
            g      = sum((PopDec(:, obj.M:end) - 0.5).^2, 2);
            PopObj = repmat(1 + g, 1, obj.M) .* fliplr(cumprod([ones(size(g,1),1), cos(PopDec(:,1:obj.M-1)*pi/2)], 2)) ...
                     .* [ones(size(g,1),1), sin(PopDec(:, obj.M-1:-1:1)*pi/2)];
        end
        %% Generate points on the Pareto front
        function R = GetOptimum(obj, N)
            R = UniformPoint(N, obj.M);
            R = R ./ repmat(sqrt(sum(R.^2, 2)), 1, obj.M);
        end
        %% Generate the image of Pareto front
        function R = GetPF(obj)
            if obj.M == 2
                R = obj.GetOptimum(100);
            elseif obj.M == 3
                a = linspace(0, pi/2, 10)';
                R = {sin(a)*cos(a'), sin(a)*sin(a'), cos(a)*ones(size(a'))};
            else
                R = [];
            end
        end
    end
end
