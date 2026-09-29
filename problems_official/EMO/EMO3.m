classdef EMO3 < PROBLEM
% EMO3 - f_i(x) = 1 - exp(-x_i + 2)
    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower = zeros(1,obj.D); obj.upper = ones(1,obj.D);
            obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M; PopObj = zeros(size(X,1),M);
            for i = 1:M, PopObj(:,i) = 1 - exp(-X(:,i) + 2); end
        end
        function R = GetOptimum(obj, N)
            % f_i(x_i) = 1 - exp(-x_i + 2)，钳位非负（官方公式符号 bug 修复）
            M = obj.M; R = zeros(N,M);
            x = linspace(0,1,N)';
            for i = 1:M, R(:,i) = max(1 - exp(-x + 2), 0); end
        end
        function R = GetPF(obj), R = obj.GetOptimum(100); end
    end
end
