classdef EMO1 < Problem
% EMO1 - expensive MOP (D=3, M=2; quadratic with hidden optimum)
% F1 = x1^2 + x2^2 + x3^2; F2 = (x1-1)^2 + x2^2 + x3^2
% PF: x1 = 0.5, x2 = x3 = 0 => F1 = 0.25, F2 = 0.25

    properties
        expensive = true;
    end

    methods
        function obj = EMO1()
            obj@Problem('EMO1', 3, 2);
            obj.lower = zeros(1, 3);
            obj.upper = ones(1, 3);
        end

        function F = CalObj(obj, X)
            N = size(X, 1);
            F = zeros(N, 2);
            F(:, 1) = X(:,1).^2 + X(:,2).^2 + X(:,3).^2;
            F(:, 2) = (X(:,1)-1).^2 + X(:,2).^2 + X(:,3).^2;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 1; end
            PF = [0.25, 0.25];
            if nPoints > 1
                PF = repmat(PF, nPoints, 1);
            end
        end
    end
end
