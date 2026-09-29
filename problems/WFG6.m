classdef WFG6 < Problem
% WFG6 - many-objective benchmark (concave front, non-separable; PlatEMO master official formula)
    methods
        function obj = WFG6(M)
            if nargin < 1, M = 2; end
            obj@Problem('WFG6', M - 1 + 10, M);
            obj.lower = zeros(1, M - 1 + 10);
            obj.upper = 2 : 2 : 2 * (M - 1 + 10);
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);
            t1 = [z01(:,1:K), s_linear(z01(:,K+1:end), 0.35)];
            t2 = zeros(size(X,1), M);
            for i = 1:M-1
                t2(:,i) = r_nonsep(t1(:, (i-1)*K/(M-1)+1 : i*K/(M-1)), K/(M-1));
            end
            SUM = zeros(size(X,1), 1);
            for i = K+1:K+L-1
                for j = i+1:K+L
                    SUM = SUM + abs(t1(:,i) - t1(:,j));
                end
            end
            t2(:,M) = (sum(t1(:,K+1:end), 2) + 2*SUM) / ceil(L/2) / (1 + 2*L - 2*ceil(L/2));
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
