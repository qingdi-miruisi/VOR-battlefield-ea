classdef CMO8 < Problem
% CMO8 - constrained MOP (CMO8 style, D=10, M=2; disconnected feasible region)
% CalObj: g = 1 + 9*mean(x(M+1:D)); F1 = x1; F2 = g*(1 - x1/g)
% CalCon: C1 = (x1 - 0.2)*(x1 - 0.4);  C2 = (x1 - 0.6)*(x1 - 0.8)
% Feasible when C1 <= 0 and C2 <= 0 => x1 in [0.2,0.4] U [0.6,0.8]
% PF: two segments f1 in [0.2,0.4] and [0.6,0.8], f2 = 1 - f1 (g=1)

    methods
        function obj = CMO8()
            obj@Problem('CMO8', 10, 2);
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
            C(:, 1) = (X(:,1) - 0.2)*(X(:,1) - 0.4);
            C(:, 2) = (X(:,1) - 0.6)*(X(:,1) - 0.8);
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 200; end
            f1 = [linspace(0.2, 0.4, floor(nPoints/2))'; linspace(0.6, 0.8, ceil(nPoints/2))'];
            PF = [f1, 1 - f1];
        end
    end
end
