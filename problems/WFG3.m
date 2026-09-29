classdef WFG3 < Problem
% WFG3 - many-objective benchmark (linear front; PlatEMO master official formula)
% D = K + 10 (K = M-1 default); bounds [0, 2:2:2D]; front = linear
% Pair-reduction uses adjacent pairs: t1(:,K+1:2:end) & t1(:,K+2:2:end)

    methods
        function obj = WFG3(M)
            if nargin < 1, M = 2; end
            K = M - 1;
            D = ceil((K + 10 - K)/2)*2 + K;
            obj@Problem('WFG3', D, M);
            obj.lower = zeros(1, D);
            obj.upper = 2 : 2 : 2 * D;
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);
            t1 = [z01(:,1:K), s_linear(z01(:,K+1:end), 0.35)];
            half = floor(L/2);
            t2 = [t1(:,1:K), (t1(:,K+1:2:end) + t1(:,K+2:2:end) + ...
                2*abs(t1(:,K+1:2:end) - t1(:,K+2:2:end))) / 3];
            t3 = zeros(size(X,1), M);
            for i = 1:M-1
                w = K/(M-1);
                t3(:,i) = r_sum(t2(:, (i-1)*w+1 : i*w), ones(1, w));
            end
            t3(:,M) = r_sum(t2(:, K+1:K+half), ones(1, half));
            A = [1, zeros(1,M-2)];
            x = zeros(size(X,1), M);
            for i = 1:M-1
                x(:,i) = max(t3(:,M), A(i)) .* (t3(:,i) - 0.5) + 0.5;
            end
            x(:,M) = t3(:,M);
            h = wfg3_linear(x);
            S = 2:2:2*M;
            F = x(:,M) * ones(1,M) + S .* h;
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            M = obj.M;
            X = [linspace(0, 1, nPoints)', zeros(nPoints, M-2) + 0.5, zeros(nPoints, 1)];
            PF = wfg3_linear(X) .* (2:2:2*M);
        end
    end
end
