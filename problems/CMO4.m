classdef CMO4 < Problem
% CMO4 - constrained MOP (CMO4 style, D=10, M=2; linear feasible strip)
% CalObj: DTLZ2-style bounded quarter-circle front (radius 1, g=0 at optimum)
% CalCon: C1 = x1 - 0.3;  C2 = 0.7 - x1   (feasible strip 0.3 <= x1 <= 0.7)
% PF: quarter circle F1^2 + F2^2 = 1

    methods
        function obj = CMO4()
            obj@Problem('CMO4', 10, 2);
        end

        function F = CalObj(obj, X)
            M = obj.M; D = obj.D; N = size(X, 1);
            g = (D - M + 1) * sum((X(:, M+1:end) - 0.5).^2, 2);
            F = zeros(N, 2);
            F(:, 1) = (1 + g) .* cos(X(:, 1) * pi / 2);
            F(:, 2) = (1 + g) .* sin(X(:, 2) * pi / 2);
        end

        function C = CalCon(obj, X)
            N = size(X, 1);
            C = zeros(N, 2);
            C(:, 1) = X(:, 1) - 0.3;
            C(:, 2) = 0.7 - X(:, 1);
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            theta = linspace(0, pi/2, nPoints)';
            PF = [cos(theta), sin(theta)];
        end
    end
end
