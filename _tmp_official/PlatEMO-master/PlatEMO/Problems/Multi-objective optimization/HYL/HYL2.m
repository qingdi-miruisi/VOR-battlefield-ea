classdef HYL2 < PROBLEM
% <2022> <multi> <real> <multimodal>
% Multi-modal multi-objective benchmark problem proposed by Hisao, Yiming, and Lie Meng

%------------------------------- Reference --------------------------------
% H. Ishibuchi, Y. Peng, and L. M. Pang. Multi-modal multi-objective
% test problems with an infinite number of equivalent Pareto sets.
% IEEE Congress on Evolutionary Computation, 2022.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

% This function is written by Yiming Peng (email: 11510035@mail.sustech.edu.cn)

    properties(Access = private) 
        POS;
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            obj.M        = 2;
            obj.D        = 2;
            obj.lower    = [-10, -10];
            obj.upper    = [10, 10];
            obj.encoding = ones(1,obj.D);
        end
        %% Calculate objective values
        function PopObj = CalObj(obj,X)
            PopObj(:,1)  = min(abs(X(:, 1) + 8), abs(X(:,1) - 4));
            PopObj(:, 2) = min(abs(X(:, 1) + 4), abs(X(:,1) - 8));
        end
 %% Generate Pareto optimal solutions
        function R = GetOptimum(obj, N)
            % Generate points in Pareto optimal set (PS)
            N          = floor(N / 2);
            X2         = linspace(-10, 10, floor(N/20))';
            Y          = [];
            for p = [linspace(-8, -4, 20), linspace(4, 8, 20)]
                X(:, 2) = X2;
                X(:, 1) = p;
                Y = [Y; X];
            end
            obj.POS = Y;
            % Generate points in Pareto front (PF): line f1 + f2 = 4, f1 in [0,4]
            R(:,1) = linspace(0, 4, N)';
            R(:,2) = 4 - R(:,1);
        end
        %% Generate the image of Pareto front
        function R = GetPF(~)
            R(:,1) = linspace(0, 4, 100)';
            R(:,2) = 4 - R(:,1);
        end
        %% Calculate the metric value
        function score = CalMetric(obj, metName, Population)
            switch metName
                case 'IGDX'
                    score = feval(metName, Population, obj.POS);
                otherwise
                    score = feval(metName, Population, obj.optimum);
            end
        end
        %% Display a population in the decision space
        function DrawDec(obj, Population)
            ax = Draw(Population.decs, {'\it x\rm_1', '\it x\rm_2', []});
            for p = [-8, -4, 4, 8]
                X      = zeros(1000, 2);
                X(:,1) = p;
                X(:,2) = linspace(-10, 10, 1000);
                Draw(X, '-black', 'LineWidth', 2);
            end
            axis(ax, 'equal');
            xlim(ax, [obj.lower(1), obj.upper(1)]);
            ylim(ax, [obj.lower(2), obj.upper(2)]);
        end
    end
end