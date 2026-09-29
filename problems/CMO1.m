classdef CMO1 < Problem
% CMO1 - constrained MOP (CMO1 style, D=10, M=2; DTLZ2-style bounded front)
% CalObj: g = 1 + 9*mean(x(M+1:D) - 0.5)^2 * (D-M+1) + ... (bounded)
%         F1 = (1+g)*cos... ; F2 = (1+g)*sin...
%         Front: F1^2 + F2^2 = 1 (quarter circle) when g=0
% CalCon: C1 = 1 - x1;  C2 = x2 - 0.5
% Feasible when x1 <= 1 and x2 >= 0.5; g=0 reachable => PF = quarter circle
% PF: F1 = cos(theta), F2 = sin(theta), theta in [0, pi/2]

    methods
        function obj = CMO1()
            obj@Problem('CMO1', 10, 2);
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
            C(:, 1) = 1 - X(:, 1);
            C(:, 2) = X(:, 2) - 0.5;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            theta = linspace(0, pi/2, nPoints)';
            PF = [cos(theta), sin(theta)];
        end
    end
end
