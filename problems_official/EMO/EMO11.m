classdef EMO11 < PROBLEM
% EMO11 - g(x)=sum(x.^3); f_i=1-exp(-g+i/M); G = M - sum(x.^3) - M
    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower = zeros(1,obj.D); obj.upper = ones(1,obj.D);
            obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M; PopObj = zeros(size(X,1),M);
            g = sum(X.^3,2);
            for i = 1:M, PopObj(:,i) = 1 - exp(-g + i/M); end
        end
        function PopCon = CalCon(obj, X)
            PopCon = obj.M - sum(X.^3,2) - obj.M;
        end
        function R = GetOptimum(obj, N)
            % 官方 GetOptimum：g=x_i^3, f_i=1-exp(-g+i/M)，目标值允许为负
            M = obj.M; R = zeros(N,M);
            x = linspace(0,1,N)';
            g = x.^3;
            for i = 1:M, R(:,i) = 1 - exp(-g + i/M); end
        end
        function R = GetPF(obj), R = obj.GetOptimum(100); end
    end
end
