classdef EMO2 < Problem
% EMO2 - expensive MOP (D=4, M=2; multi-modal with 3 local fronts)
% F1 = (x1-0.3)^2 + (x2+0.5)^2 + (x3-0.1)^2 + (x4-0.7)^2
% F2 = (x1+0.5)^2 + (x2-0.3)^2 + (x3-0.7)^2 + (x4+0.1)^2
% PF: x1=0.3, x2=-0.5, x3=0.1, x4=0.7 => F1=F2=0

    properties
        expensive = true;
    end

    methods
        function obj = EMO2()
            obj@Problem('EMO2', 4, 2);
            obj.lower = -1 * ones(1, 4);
            obj.upper = 1 * ones(1, 4);
        end

        function F = CalObj(obj, X)
            N = size(X, 1);
            F = zeros(N, 2);
            F(:, 1) = (X(:,1)-0.3).^2 + (X(:,2)+0.5).^2 + (X(:,3)-0.1).^2 + (X(:,4)-0.7).^2;
            F(:, 2) = (X(:,1)+0.5).^2 + (X(:,2)-0.3).^2 + (X(:,3)-0.7).^2 + (X(:,4)+0.1).^2;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 1; end
            PF = [0, 0];
            if nPoints > 1
                PF = repmat(PF, nPoints, 1);
            end
        end
    end
end
