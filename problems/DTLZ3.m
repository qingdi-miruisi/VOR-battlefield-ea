classdef DTLZ3 < Problem
% DTLZ3 - scalable MOP benchmark (disconnected; PlatEMO master official formula)
% D = M + 7, bounds [0,1]. g = 100*(D-M+1+sum((x_{M+1:D}-0.5)^2 - cos(20*pi*(x_{M+1:D}-0.5))));
% F = (1+g) * cos structure (same objective mapping as DTLZ2); PF = unit sphere orthant.

    methods
        function obj = DTLZ3(M)
            if nargin < 1, M = 3; end
            obj@Problem('DTLZ3', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            g = 100 * (obj.D - M + 1 + sum((X(:, M+1:end) - 0.5).^2 - ...
                cos(20 * pi * (X(:, M+1:end) - 0.5)), 2));
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
