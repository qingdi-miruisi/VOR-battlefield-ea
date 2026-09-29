classdef ZDT5 < Problem
% ZDT5 - binary MOP (Zitzler et al. 2002; PlatEMO official formula)
% f1 = 30*x1; g = sum_{i=2:25} x_i (binary); h = g*(30+2)/(30*x1+2)
% D = 25 (binary), M = 2

    properties
        isBinary = true;
    end

    methods
        function obj = ZDT5(D)
            if nargin < 1, D = 25; end
            obj@Problem('ZDT5', D, 2);
            obj.lower = zeros(1,D); obj.upper = ones(1,D);
        end

        function F = CalObj(obj, X)
            N = size(X, 1);
            Xb = round(X);
            F = zeros(N, 2);
            F(:,1) = 30 * Xb(:,1);
            g = sum(Xb(:,2:end), 2);
            F(:,2) = g .* (30 + 2) ./ (30 * Xb(:,1) + 2);
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0, 30, nPoints)';
            PF = [f1, (30 + 2) * ones(nPoints, 1)];
        end
    end
end
