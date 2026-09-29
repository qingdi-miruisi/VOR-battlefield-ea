classdef WFG5 < Problem
% WFG5 - many-objective benchmark (deceptive front; PlatEMO master official formula)
% K = M-1; D = K + 10; bounds [0, 2:2:2D]
% t1 = s_decept(z01, 0.35, 0.001, 0.05); t2 = r_sum blocks; x = bias; F = 1*xM + S*concave(x)

    methods
        function obj = WFG5(M)
            if nargin < 1, M = 2; end
            obj@Problem('WFG5', M - 1 + 10, M);
            obj.lower = zeros(1, M - 1 + 10);
            obj.upper = 2 : 2 : 2 * (M - 1 + 10);
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);
            t1 = s_decept(z01, 0.35, 0.001, 0.05);
            t2 = zeros(size(X,1), M);
            for i = 1:M-1
                t2(:,i) = r_sum(t1(:, (i-1)*K/(M-1)+1 : i*K/(M-1)), ones(1, K/(M-1)));
            end
            t2(:,M) = r_sum(t1(:, K+1:K+L), ones(1, L));
            A = ones(1, M-1);
            x = zeros(size(X,1), M);
            for i = 1:M-1
                x(:,i) = max(t2(:,M), A(i)) .* (t2(:,i) - 0.5) + 0.5;
            end
            x(:,M) = t2(:,M);
            h = concave(x);
            S = 2:2:2*M;
            F = x(:,M) * ones(1,M) + S .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            U = UniformPoint(nPoints, obj.M);
            PF = U ./ sqrt(sum(U.^2, 2)) .* (2:2:2*obj.M);
        end
    end
end
