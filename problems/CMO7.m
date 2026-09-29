classdef CMO7 < Problem
% CMO7 - constrained MOP (CMO7 style, D=10; high violation rate)
% CalObj: g = 1 + 9*mean(x(M+1:D)); F1 = x1; F2 = g*(1 - x1/g)
% CalCon: C1 = (x1 - 0.5)*2 - 0.6; C2 = 0.6 - (x1 - 0.5)*2
% Feasible region: x1 in [0.2, 0.8]
% PF: f1 in [0.2, 0.8], f2 = 1 - f1

    methods
        function obj = CMO7()
            obj@Problem('CMO7', 10, 2);
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
            C(:, 1) = (X(:, 1) - 0.5)*2 - 0.6;
            C(:, 2) = 0.6 - (X(:, 1) - 0.5)*2;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0.2, 0.8, nPoints)';
            PF = [f1, 1 - f1];
        end
    end
end
