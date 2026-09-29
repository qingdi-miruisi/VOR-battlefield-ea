classdef EMO7 < PROBLEM
% EMO7 - f_i=1-exp(-sum(x.^2)/M+i/M); G = M - sum(x.^2)
    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower = zeros(1,obj.D); obj.upper = ones(1,obj.D);
            obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M; PopObj = zeros(size(X,1),M);
            g = sum(X.^2,2)/M;
            for i = 1:M, PopObj(:,i) = 1 - exp(-g + i/M); end
        end
        function PopCon = CalCon(obj, X)
            PopCon = obj.M - sum(X.^2,2);
        end
        function R = GetOptimum(obj, N)
            M = obj.M; R = zeros(N,M);
            x = linspace(0,1,N)';
            g = x.^2;
            for i = 1:M, R(:,i) = 1 - exp(-g + i/M); end
        end
        function R = GetPF(obj), R = obj.GetOptimum(100); end
    end
end
