classdef HYL1 < PROBLEM
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
        A = 10;   
        POS;
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            obj.A        = obj.ParameterSet(10);
            obj.M        = 2;
            obj.D        = 2;
            obj.lower    = [-obj.A/2, -obj.A/2];
            obj.upper    = [obj.A/2, obj.A/2];
            obj.encoding = ones(1,obj.D);
        end
        %% Calculate objective values
        function PopObj = CalObj(obj,X)
            PopObj(:,1)  = (X(:, 1) + X(:, 2)).^2;
            PopObj(:, 2) = (X(:, 1) + X(:, 2) - 2).^2;
        end
        %% Generate Pareto optimal solutions 
        function R = GetOptimum(obj,N)
            % Generate points in Pareto optimal set
            X2  = linspace(-obj.A/2, obj.A/2, floor(N/20))';
            X1  = -X2;           
            Y   = [];
            for l = linspace(0, 2, 20)
                candidate = [X1 + l, X2];
                inBox     = all(candidate >= -obj.A/2 & candidate <= obj.A/2, 2);
                Y         = [Y; candidate(inBox, :)];
            end    
            obj.POS(:,1) = Y(:,1);
            obj.POS(:,2) = Y(:,2);
            % Generate points in Pareto front
            R(:,1) = linspace(0, 4, N)';
            R(:,2) = (sqrt(R(:,1)) - 2).^2;
        end
        %% Generate the image of Pareto front
        function R = GetPF(obj)
            R(:,1) = linspace(0,4,100)';
            R(:,2) = (sqrt(R(:,1)) - 2).^2;
        end
        %% Calculate the metric value
        function score = CalMetric(obj,metName,Population)
            switch metName
                case 'IGDX'
                    score = feval(metName,Population,obj.POS);
                otherwise
                    score = feval(metName,Population,obj.optimum);
            end
        end
        %% Dispaly a population in the decision space
        function DrawDec(obj, Population)
            ax = Draw(Population.decs, {'\it x\rm_1', '\it x\rm_2', []});
            X2 = linspace(-obj.A/2, obj.A/2, floor(1000/2))';
            Draw([-X2, X2], '-black', 'LineWidth', 2);
            Draw([2-X2, X2], '-black', 'LineWidth', 2);
            axis(ax, 'equal');
            xlim(ax, [obj.lower(1), obj.upper(1)]);
            ylim(ax, [obj.lower(2), obj.upper(2)]);
        end
    end
end