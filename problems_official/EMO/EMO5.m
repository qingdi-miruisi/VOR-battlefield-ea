classdef EMO5 < PROBLEM
% EMO5 - g(x) = sum(x.^2)/M; f_i(x) = 1 - exp(-g(x) + i/M)
    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower = zeros(1,obj.D); obj.upper = ones(1,obj.D);
            obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M; PopObj = zeros(size(X,1),M);
            g = sum(X.^2,2) / M;
            for i = 1:M, PopObj(:,i) = 1 - exp(-g + i/M); end
        end
        function R = GetOptimum(obj, N)
            % g(x) = sum(x.^2)/M; f_i = 1 - exp(-g + i/M)，钳位非负
            M = obj.M; R = zeros(N,M);
            x = linspace(0,1,N)';
            g = x.^2;
            for i = 1:M, R(:,i) = max(1 - exp(-g + i/M), 0); end
        end
        function R = GetPF(obj), R = obj.GetOptimum(100); end
    end
end
