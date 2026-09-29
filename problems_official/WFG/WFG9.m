classdef WFG9 < PROBLEM
% <2006> <multi/many> <real> <large/none> <expensive/none>
% WFG9 - PlatEMO official formula (deceptive + non-separable; M-parameterized)
% M=10 时 K=M-1=9, D=K+10=19

    properties(Access = private)
        K;  % Position parameter = M-1
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            if isempty(obj.M); obj.M = 3; end
            obj.K = obj.ParameterSet(obj.M - 1);
            if isempty(obj.D); obj.D = obj.K + 10; end
            obj.lower    = zeros(1, obj.D);
            obj.upper    = 2 : 2 : 2 * obj.D;
            obj.encoding = ones(1, obj.D);
        end
        %% Calculate objective values
        function PopObj = CalObj(obj, PopDec)
            [N, D] = size(PopDec);
            M = obj.M; K = obj.K; L = D - K;
            S = 2 : 2 : 2 * M;
            A = ones(1, M - 1);

            z01 = PopDec ./ repmat(2:2:2*D, N, 1);
            Y   = (fliplr(cumsum(fliplr(z01), 2)) - z01) ./ repmat(D-1:-1:0, N, 1);
            t1 = zeros(N, K+L);
            t1(:, 1:K+L-1) = z01(:,1:K+L-1).^(0.02 + (50-0.02)*(0.98/49.98 - ...
                (1-2*Y(:,1:K+L-1)) .* abs(floor(0.5 - Y(:,1:K+L-1)) + 0.98/49.98)));
            t1(:, end) = z01(:, end);

            t2 = zeros(N, K+L);
            t2(:, 1:K)     = s_decept(t1(:,1:K), 0.35, 0.001, 0.05);
            t2(:, K+1:end) = s_multi(t1(:,K+1:end), 30, 95, 0.35);

            t3 = zeros(N, M);
            for i = 1:M-1
                t3(:,i) = r_nonsep(t2(:, (i-1)*K/(M-1)+1 : i*K/(M-1)), K/(M-1));
            end
            SUM = zeros(N, 1);
            for i = K+1 : K+L-1
                for j = i+1 : K+L
                    SUM = SUM + abs(t2(:,i) - t2(:,j));
                end
            end
            t3(:, M) = (sum(t2(:,K+1:end), 2) + 2*SUM) / ceil(L/2) / (1 + 2*L - 2*ceil(L/2));

            x = zeros(N, M);
            for i = 1:M-1
                x(:,i) = max(t3(:,M), A(i)) .* (t3(:,i) - 0.5) + 0.5;
            end
            x(:, M) = t3(:, M);

            h = concave(x);
            PopObj = 1 * ones(1, M) + S .* h;
            PopObj = x(:,M) * ones(1,M) + S .* h;
        end
        %% Generate points on the Pareto front
        function R = GetOptimum(obj, N)
            R = UniformPoint(N, obj.M);
            R = R ./ repmat(sqrt(sum(R.^2, 2)), 1, obj.M);
            R = repmat(2:2:2*obj.M, size(R,1), 1) .* R;
        end
        %% Generate the image of Pareto front
        function R = GetPF(obj)
            if obj.M == 2
                R = obj.GetOptimum(100);
            elseif obj.M == 3
                a = linspace(0, pi/2, 10)';
                R = {sin(a)*cos(a')*2, sin(a)*sin(a')*4, cos(a)*ones(size(a'))*6};
            else
                R = [];
            end
        end
    end
end

function Output = s_decept(y, A, B, C)
    Output = 1 + (abs(y-A)-B) .* (floor(y-A+B)*(1-C+(A-B)/B)/(A-B) + ...
        floor(A+B-y)*(1-C+(1-A-B)/B)/(1-A-B) + 1/B);
end

function Output = s_multi(y, A, B, C)
    Output = (1 + cos((4*A+2)*pi*(0.5 - abs(y-C)/2 ./ (floor(C-y)+C))) + ...
        4*B*(abs(y-C)/2 ./ (floor(C-y)+C)).^2) / (B + 2);
end

function Output = r_nonsep(y, A)
    Output = zeros(size(y,1), 1);
    for j = 1 : size(y,2)
        Temp = zeros(size(y,1), 1);
        for k = 0 : A-2
            Temp = Temp + abs(y(:,j) - y(:,1+mod(j+k, size(y,2))));
        end
        Output = Output + y(:,j) + Temp;
    end
    Output = Output ./ (size(y,2)/A) / ceil(A/2) / (1 + 2*A - 2*ceil(A/2));
end

function Output = concave(x)
    Output = fliplr(cumprod([ones(size(x,1),1), sin(x(:,1:end-1)*pi/2)], 2)) ...
        .* [ones(size(x,1),1), cos(x(:,end-1:-1:1)*pi/2)];
end
