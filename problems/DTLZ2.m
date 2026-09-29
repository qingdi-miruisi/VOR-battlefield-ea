classdef DTLZ2 < Problem
% DTLZ2 - scalable MOP benchmark (concave front; PlatEMO official formula)
% D = M + 7, bounds [0,1]. True front: unit sphere (orthant), g = 0.

    methods
        function obj = DTLZ2(M)
            if nargin < 1, M = 2; end
            obj@Problem('DTLZ2', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            g = sum((X(:, M+1:end) - 0.5).^2, 2);
            t = fliplr(cumprod([ones(size(g,1),1), cos(X(:, 1:M-1) * pi/2)], 2)) .* ...
                [ones(size(g,1),1), sin(X(:, M-1:-1:1) * pi/2)];
            F = (1 + g) .* t;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            U = UniformPoint(nPoints, obj.M);
            PF = U ./ sqrt(sum(U.^2, 2));
        end
    end
end