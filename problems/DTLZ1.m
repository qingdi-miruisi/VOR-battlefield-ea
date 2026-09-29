classdef DTLZ1 < Problem
% DTLZ1 - scalable MOP benchmark (Deb, Thiele, Laumanns, Zitzler 2005; PlatEMO official formula)
% D = M + 7, bounds [0,1]. True front: simplex, sum(f_i) = 0.5.

    methods
        function obj = DTLZ1(M)
            if nargin < 1, M = 3; end
            obj@Problem('DTLZ1', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            g = 100 * (obj.D - M + 1 + sum((X(:, M+1:end) - 0.5).^2 - ...
                cos(20 * pi * (X(:, M+1:end) - 0.5)), 2));
            t = fliplr(cumprod([ones(size(g,1),1), X(:, 1:M-1)], 2)) .* ...
                [ones(size(g,1),1), 1 - X(:, M-1:-1:1)];
            F = 0.5 * (1 + g) .* t;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            PF = 0.5 * UniformPoint(nPoints, obj.M);
        end
    end
end