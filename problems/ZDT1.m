classdef ZDT1 < Problem
% ZDT1 - bi-objective benchmark (Zitzler et al. 2000; official PlatEMO formulas)
% f1 = x1;  g = 1 + 9*mean(x2:xD);  f2 = g*(1 - sqrt(f1/g))
% True front: g=1 -> f2 = 1 - sqrt(f1), f1 in [0,1]

    methods
        function obj = ZDT1(D)
            if nargin < 1, D = 30; end
            obj@Problem('ZDT1', D, 2);
        end

        function F = CalObj(obj, X)
            [N, D] = size(X);
            F = zeros(N, 2);
            F(:,1) = X(:,1);
            g = 1 + 9 * mean(X(:,2:end), 2);
            h = 1 - sqrt(F(:,1) ./ g);
            F(:,2) = g .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0, 1, nPoints)';
            PF = [f1, 1 - sqrt(f1)];
        end
    end
end
