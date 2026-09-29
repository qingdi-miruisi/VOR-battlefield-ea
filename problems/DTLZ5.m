classdef DTLZ5 < Problem
% DTLZ5 - DTLZ1 variant with variable linkage (x_i^100); PlatEMO official formula

    methods
        function obj = DTLZ5(M)
            if nargin < 1, M = 3; end
            obj@Problem('DTLZ5', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            g = 100 * (obj.D - M + 1 + sum((X(:, M+1:end) - 0.5).^2 - ...
                cos(20 * pi * (X(:, M+1:end) - 0.5)), 2));
            Xl = X(:, 1:M); Xl(:, 1:M-1) = Xl(:, 1:M-1).^100;
            t = fliplr(cumprod([ones(size(g,1),1), Xl(:, 1:M-1)], 2)) .* ...
                [ones(size(g,1),1), 1 - Xl(:, M-1:-1:1)];
            F = 0.5 * (1 + g) .* t;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            PF = 0.5 * UniformPoint(nPoints, obj.M);
        end
    end
end