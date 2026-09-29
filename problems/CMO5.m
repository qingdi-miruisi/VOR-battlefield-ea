classdef CMO5 < Problem
% CMO5 - constrained MOP (CMO5 style, D=10; equality constraint on F1)
% CalObj: g = 1 + 9*mean(x(M+1:D)); F1 = x1; F2 = g*(1 - x1/g)
% CalCon: C1 = F1 - 0.5 (equality-like; feasible when |C1| <= 0.05)
% PF: single point at f1 = 0.5, f2 = 0.5

    methods
        function obj = CMO5()
            obj@Problem('CMO5', 10, 2);
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
            C = zeros(N, 1);
            C(:, 1) = X(:, 1) - 0.5;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 1; end
            PF = [0.5, 0.5];
            if nPoints > 1
                PF = repmat(PF, nPoints, 1);
            end
        end
    end
end
