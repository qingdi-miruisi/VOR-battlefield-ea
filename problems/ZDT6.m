classdef ZDT6 < Problem
% ZDT6 - 2-objective (disconnected front, nonuniform density; PlatEMO official formula)
% f1 = x1^0.25; g = 1 + 9*mean(x2:D); f2 = g*(1 - sqrt(f1/g))
% D = M + 10 = 12

    methods
        function obj = ZDT6(D)
            if nargin < 1, D = 12; end
            obj@Problem('ZDT6', D, 2);
        end

        function F = CalObj(obj, X)
            N = size(X, 1);
            F = zeros(N, 2);
            F(:,1) = X(:,1).^(0.25);
            g = 1 + 9 * mean(X(:,2:end), 2);
            F(:,2) = g .* (1 - sqrt(F(:,1)./g));
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0, 1, nPoints)';
            PF = [f1, 1 - sqrt(f1)];
        end
    end
end
