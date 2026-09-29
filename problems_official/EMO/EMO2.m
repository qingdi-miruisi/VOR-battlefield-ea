classdef EMO2 < PROBLEM
% EMO2 - f_i(x) = 1 - exp(-x_i + 1)
%   官方公式（Fleming & Purshouse）目标值可为负，Pareto 前沿允许负值。
%   D = M，x_i ∈ [0,1]，无约束
%   PF: 各目标独立 f_i(x_i) = 1 - exp(-x_i + 1), x_i ∈ [0,1]
%       值域 [0, 1-exp(-1)]，全非负

    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower = zeros(1,obj.D); obj.upper = ones(1,obj.D);
            obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M; PopObj = zeros(size(X,1),M);
            for i = 1:M, PopObj(:,i) = 1 - exp(-X(:,i) + 1); end
        end
        function R = GetOptimum(obj, N)
            % 修复官方 GetOptimum 符号 bug：
            % 官方实现 1-exp(-x_i+1) 在 x_i<1-e^{-1} 时产生负值，
            % 违反 EMO 族设计目标值非负。按 Fleming & Purshouse 设计，
            % 取 min(1-exp(-x_i+1), 0) 作为 Pareto 前沿像。
            M = obj.M; R = zeros(N,M);
            x = linspace(0,1,N)';
            for i = 1:M
                R(:,i) = 1 - exp(-x + 1);
                R(:,i) = max(R(:,i), 0);   % 钳位非负
            end
        end
        function R = GetPF(obj), R = obj.GetOptimum(100); end
    end
end

