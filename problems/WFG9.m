classdef WFG9 < Problem
% WFG9 - many-objective benchmark (deceptive + non-separable; PlatEMO master official formula)
    methods
        function obj = WFG9(M)
            if nargin < 1, M = 2; end
            obj@Problem('WFG9', M - 1 + 10, M);
            obj.lower = zeros(1, M - 1 + 10);
            obj.upper = 2 : 2 : 2 * (M - 1 + 10);
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);
            Y = (fliplr(cumsum(fliplr(z01), 2)) - z01) ./ repmat(D-1:-1:0, size(X,1), 1);
            t1 = z01(:,1:K+L-1).^ (0.02 + (50 - 0.02) * (0.98/49.98 - ...
                (1 - 2*Y(:,1:K+L-1)) .* abs(floor(0.5 - Y(:,1:K+L-1)) + 0.98/49.98)));
            t1 = [t1, z01(:,end)];
            t2 = [s_decept(t1(:,1:K), 0.35, 0.001, 0.05), s_multi(t1(:,K+1:end), 30, 95, 0.35)];
            t3 = zeros(size(X,1), M);
            for i = 1:M-1
                t3(:,i) = r_nonsep(t2(:, (i-1)*K/(M-1)+1 : i*K/(M-1)), K/(M-1));
            end
            SUM = zeros(size(X,1), 1);
            for i = K+1:K+L-1
                for j = i+1:K+L
                    SUM = SUM + abs(t2(:,i) - t2(:,j));
                end
            end
            t3(:,M) = (sum(t2(:,K+1:end), 2) + 2*SUM) / ceil(L/2) / (1 + 2*L - 2*ceil(L/2));
            A = ones(1, M-1);
            x = zeros(size(X,1), M);
            for i = 1:M-1
                x(:,i) = max(t3(:,M), A(i)) .* (t3(:,i) - 0.5) + 0.5;
            end
            x(:,M) = t3(:,M);
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
