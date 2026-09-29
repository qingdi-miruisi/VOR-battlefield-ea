classdef ZDT4 < Problem
% ZDT4 - 2-objective multimodal MOP (Zitzler et al. 2000; PlatEMO official formula)
% f1 = x1; g = 1 + 9*mean(x2:D); h = 1 - sqrt(f1/g) - 10*(f1^(0.25))*sin(10*pi*f1)
% D = M + 17 = 19 (standard)

    methods
        function obj = ZDT4(D)
            if nargin < 1, D = 19; end
            obj@Problem('ZDT4', D, 2);
        end

        function F = CalObj(obj, X)
            N = size(X, 1);
            F = zeros(N, 2);
            F(:,1) = X(:,1);
            g = 1 + 9 * mean(X(:,2:end), 2);
            F(:,2) = g .* (1 - sqrt(F(:,1)./g) - 10*(F(:,1).^(0.25)).*sin(10*pi*F(:,1)));
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            f1 = linspace(0, 1, nPoints)';
            PF = [f1, 1 - sqrt(f1)];
        end
    end
end
