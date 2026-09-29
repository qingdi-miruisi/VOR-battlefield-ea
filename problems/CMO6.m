classdef CMO6 < Problem
% CMO6 - constrained MOP (CMO6 style, D=10; nonlinear inequality constraints)
% CalObj: g = 1 + 9*mean(x(M+1:D)); F1 = x1; F2 = g*(1 - x1/g)
% CalCon: C1 = 1 - (x1 - 0.5)^2 / 0.05; C2 = 1 - (x2 - 0.5)^2 / 0.05
% PF: f1 in [0,1], f2 = 1 - f1 (full front, constraints carve out the feasible region)

    methods
        function obj = CMO6()
            obj@Problem('CMO6', 10, 2);
        end

        function F = CalObj(obj, X)
            M = obj.M; D = obj.D; N = size(X, 1);
            g = 1 + 9 * mean(X(:, M+1:D), 2);
            F = zeros(N, 2);
            F(:, 1) = X(:, 1);
            F(:, 2) = g .* (1 - F(:, 1) ./ g);
        end

        function C = CalCon(obj, X)
            N = size(X, 1);
            C = zeros(N, 2);
            C(:, 1) = 1 - (X(:, 1) - 0.5).^2 / 0.05;
            C(:, 2) = 1 - (X(:, 2) - 0.5).^2 / 0.05;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0, 1, nPoints)';
            PF = [f1, 1 - f1];
        end
    end
end
