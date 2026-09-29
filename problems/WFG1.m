classdef WFG1 < Problem
% WFG1 - many-objective benchmark (mixed front; PlatEMO master official formula)
% PF: official GetOptimum (numerical front-tracing via UniformPoint + root refinement)
% Reference: S. Huband, P. Hingston, L. Barone, L. While. IEEE TEVC, 2006, 10(5): 477-506.

    methods
        function obj = WFG1(M)
            if nargin < 1, M = 2; end
            obj@Problem('WFG1', M - 1 + 10, M);
            obj.lower = zeros(1, M - 1 + 10);
            obj.upper = 2 : 2 : 2 * (M - 1 + 10);
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            S = 2:2:2*M;
            A = ones(1, M-1);
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);

            t1 = zeros(size(X,1), K + L);
            t1(:,1:K) = z01(:,1:K);
            t1(:,K+1:end) = s_linear(z01(:,K+1:end), 0.35);

            t2 = zeros(size(X,1), K + L);
            t2(:,1:K) = t1(:,1:K);
            t2(:,K+1:end) = b_flat(t1(:,K+1:end), 0.8, 0.75, 0.85);

            t3 = b_poly(t2, 0.02);

            t4 = zeros(size(X,1), M);
            for i = 1:M-1
                w = 2*((i-1)*K/(M-1)+1) : 2 : 2*i*K/(M-1);
                t4(:,i) = r_sum(t3(:, (i-1)*K/(M-1)+1 : i*K/(M-1)), w(:));
            end
            w = 2*(K+1) : 2 : 2*(K+L);
            t4(:,M) = r_sum(t3(:, K+1:K+L), w(:));

            x = zeros(size(X,1), M);
            for i = 1:M-1
                x(:,i) = max(t4(:,M), A(i)) .* (t4(:,i) - 0.5) + 0.5;
            end
            x(:,M) = t4(:,M);

            h = convex(x); h(:,M) = mixed(x);
            F = x(:,M) * ones(1,M) + S .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            % Official PlatEMO WFG1 GetOptimum (deterministic; identical reference for all algorithms)
            if nargin < 2, nPoints = 500; end
            M = obj.M;
            R = UniformPoint(nPoints, M);
            c = ones(size(R,1), M);
            for i = 1:size(R,1)
                for j = 2:M
                    temp = R(i,j) / R(i,1) * prod(1 - c(i, M-j+2:M-1));
                    c(i, M-j+1) = (temp^2 - temp + sqrt(2*temp)) / (temp^2 + 1);
                end
            end
            x = acos(c) * 2 / pi;
            temp = (1 - sin(pi/2 * x(:,2))) .* R(:,M) ./ R(:,M-1);
            a = 0 : 0.001 : 1;
            E = abs(temp * (1 - cos(pi/2 * a)) - 1 + ...
                repmat(a + cos(10*pi*a + pi/2) / (10/pi), size(x,1), 1));
            [~, rank] = sort(E, 2);
            for i = 1:size(x,1)
                x(i,1) = a(min(rank(i, 1:10)));
            end
            R = convex(x); R(:,M) = mixed(x);
            R = R .* repmat(2:2:2*M, size(R,1), 1);
            PF = sortrows(R);
        end
    end
end
