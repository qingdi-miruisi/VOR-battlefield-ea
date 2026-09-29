classdef CMO2 < Problem
% CMO2 - constrained MOP (CMO2 style, D=10, M=2; disconnected feasible region)
% CalObj: DTLZ2-style front (bounded quarter circle)
% CalCon: C1 = (x1 - 0.2)^2 + (x2 - 0.2)^2 - 0.02;
%         C2 = 0.02 - (x1 - 0.8)^2 - (x2 - 0.8)^2
% PF: quarter circle F1^2 + F2^2 = 1

    methods
        function obj = CMO2()
            obj@Problem('CMO2', 10, 2);
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
            C(:, 1) = (X(:,1) - 0.2).^2 + (X(:,2) - 0.2).^2 - 0.02;
            C(:, 2) = 0.02 - (X(:,1) - 0.8).^2 - (X(:,2) - 0.8).^2;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            theta = linspace(0, pi/2, nPoints)';
            PF = [cos(theta), sin(theta)];
        end
    end
end
