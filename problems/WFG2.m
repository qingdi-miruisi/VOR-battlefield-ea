classdef WFG2 < Problem
% WFG2 - many-objective benchmark (Huband et al. 2006; PlatEMO master official formula)
% K = M-1; D = ceil((K+10-K)/2)*2 + K (rounded so L = D-K is even); bounds [0, 2:2:2D]
% PF: official GetOptimum (numerical front-tracing with disc front shape)

    methods
        function obj = WFG2(M)
            if nargin < 1, M = 2; end
            K = M - 1;
            D = ceil((K + 10 - K)/2)*2 + K;
            obj@Problem('WFG2', D, M);
            obj.lower = zeros(1, D);
            obj.upper = 2 : 2 : 2 * D;
        end

        function F = CalObj(obj, X)
            M = obj.M; K = M - 1; D = obj.D; L = D - K;
            half = floor(L/2);
            z01 = X ./ repmat(2:2:2*D, size(X,1), 1);
            t1 = [z01(:,1:K), s_linear(z01(:,K+1:end), 0.35)];
            t2 = [t1(:,1:K), (t1(:,K+1:2:end) + t1(:,K+2:2:end) + ...
                2*abs(t1(:,K+1:2:end) - t1(:,K+2:2:end))) / 3];
            t3 = zeros(size(X,1), M);
            for i = 1:M-1
                w = K/(M-1);
                t3(:,i) = r_sum(t2(:, (i-1)*w+1 : i*w), ones(1, w));
            end
            t3(:,M) = r_sum(t2(:, K+1:K+half), ones(1, half));
            A = ones(1, M-1);
            x = zeros(size(X,1), M);
            for i = 1:M-1
                x(:,i) = max(t3(:,M), A(i)) .* (t3(:,i) - 0.5) + 0.5;
            end
            x(:,M) = t3(:,M);
            h = convex(x); h(:,M) = disc(x);
            S = 2:2:2*M;
            F = x(:,M) * ones(1,M) + S .* h;
        end
        function PF = ParetoFront(obj, nPoints)
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
                repmat(a .* cos(5*pi*a).^2, size(x,1), 1));
            [~, rank] = sort(E, 2);
            for i = 1:size(x,1)
                x(i,1) = a(min(rank(i, 1:10)));
            end
            R = convex(x); R(:,M) = disc(x);
            R = R .* repmat(2:2:2*M, size(R,1), 1);
            PF = sortrows(R);
        end
    end
end
