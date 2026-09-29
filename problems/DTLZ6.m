classdef DTLZ6 < Problem
% DTLZ6 - hard MOP (non-separable g, discontinuous front); PlatEMO official formula

    methods
        function obj = DTLZ6(M)
            if nargin < 1, M = 2; end
            obj@Problem('DTLZ6', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            Xl = X(:, 1:M); Xl(:, 1:M-1) = Xl(:, 1:M-1).^2;
            g = sum((X(:, M+1:end) - 0.5).^2, 2);
            t = fliplr(cumprod([ones(size(g,1),1), cos(Xl(:, 1:M-1) * pi/2)], 2)) .* ...
                [ones(size(g,1),1), sin(Xl(:, M-1:-1:1) * pi/2)];
            F = (1 + g) .* t;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            U = UniformPoint(nPoints, obj.M);
            PF = U ./ sqrt(sum(U.^2, 2));
        end
    end
end