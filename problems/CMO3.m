classdef CMO3 < Problem
% CMO3 - constrained MOP (CMO3 style, D=10, M=2; convex front + tight constraints)
% CalObj: g = 1 + 9*mean((x(M+1:D)-0.5)^2); F1 = (1+g)*cos(x1*pi/2); F2 = (1+g)*sin(x2*pi/2)
% CalCon: C1 = 1 - (x1 + x2);  C2 = (x1 + x2) - 0.5
% Feasible when 0.5 <= x1+x2 <= 1
% PF: quarter circle F1^2 + F2^2 = 1 (g=0)

    methods
        function obj = CMO3()
            obj@Problem('CMO3', 10, 2);
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
            C(:, 1) = 1 - (X(:, 1) + X(:, 2));
            C(:, 2) = (X(:, 1) + X(:, 2)) - 0.5;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            theta = linspace(0, pi/2, nPoints)';
            PF = [cos(theta), sin(theta)];
        end
    end
end
