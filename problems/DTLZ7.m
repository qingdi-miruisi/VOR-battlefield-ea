classdef DTLZ7 < Problem
% DTLZ7 - disconnected multi-modal MOP (PlatEMO master official formula)
% D = M + 7, bounds [0,1].
% CalObj (official):
%   g = 1 + 9*mean(x_{M+1:D});
%   F(:,1:M-1) = x(:,1:M-1);
%   F(:,M) = (1+g) * (M - sum(F(:,1:M-1)./(1+g)*(1+sin(3*pi*F(:,1:M-1))), 2));
% PF (official GetOptimum, M=2 uses non-uniform grid: median splitting)

    methods
        function obj = DTLZ7(M)
            if nargin < 1, M = 2; end
            obj@Problem('DTLZ7', M + 7, M);
        end

        function F = CalObj(obj, X)
            M = obj.M;
            F = zeros(size(X,1), M);
            g = 1 + 9 * mean(X(:, M+1:end), 2);
            F(:, 1:M-1) = X(:, 1:M-1);
            F(:, M) = (1 + g) .* (M - sum(F(:, 1:M-1) ./ (1 + g) .* (1 + sin(3*pi * F(:, 1:M-1))), 2));
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            M = obj.M;
            if M == 2
                % Official M=2 PF: grid-based
                x = linspace(0, 1, nPoints)';
                y = 2 * (2 - x ./ 2 .* (1 + sin(3*pi * x)));
                PF = [x, y];
                [~, nd] = sortrows(PF);
                PF = PF(nd, :);
            else
                % M>=3: uniform simplex + official F_M formula
                U = UniformPoint(nPoints, M - 1);
                PF = [U, 2 * (M - sum(U ./ 2 .* (1 + sin(3*pi * U)), 2))];
            end
        end
    end
end
