classdef EMO1 < PROBLEM
% EMO1 - Fleming & Purshouse (2003) many-objective test problem 1
%   f_i(x) = 1 - exp(-x_i), i = 1..M
%   D = M, x_i in [0,1], unconstrained
%   PF: f_i = 1 - exp(-x_i), x_i in [0,1]

    methods
        function Setting(obj)
            obj.M = 3;
            if isempty(obj.D); obj.D = obj.M; end
            obj.lower  = zeros(1, obj.D);
            obj.upper  = ones(1, obj.D);
            obj.encoding = ones(1, obj.D);
        end
        function PopObj = CalObj(obj, X)
            M = obj.M;
            PopObj = zeros(size(X,1), M);
            for i = 1:M
                PopObj(:,i) = 1 - exp(-X(:,i));
            end
        end
        function R = GetOptimum(obj, N)
            M = obj.M;
            R = zeros(N, M);
            for i = 1:M
                R(:,i) = 1 - exp(-linspace(0,1,N)');
            end
        end
        function R = GetPF(obj)
            R = obj.GetOptimum(100);
        end
    end
end
