classdef HYL5 < PROBLEM
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
        Points = { [-6, -2], [-2, -6];
                   [ 2,  6], [ 6,  2] };
        numPS  = 2;
        POS;                              % Pareto Set samples (used by IGDX)
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            obj.M        = 2;
            obj.D        = 2;
            obj.lower    = [-10, -10];
            obj.upper    = [ 10,  10];
            obj.encoding = ones(1, obj.D);
        end
        %% Calculate objective values (Manhattan distance)
        function PopObj = CalObj(obj, X)
            X      = X(:, 1:2);
            PopObj = Inf(size(X,1), obj.M);
            for m = 1 : obj.M
                for i = 1 : obj.numPS
                    D = pdist2(obj.Points{i,m}, X, 'cityblock')';
                    PopObj(:,m) = min(D, PopObj(:,m));
                end
            end
        end
        %% Generate Pareto optimal solutions
        function R = GetOptimum(obj, N)
            % Generate points in Pareto optimal set (PS): two squares
            n       = max(2, floor(sqrt(N/2)));
            [X, Y]  = ndgrid(linspace(-6, -2, n), linspace(-6, -2, n));
            Y1      = [X(:), Y(:)];
            [X, Y]  = ndgrid(linspace( 2,  6, n), linspace( 2,  6, n));
            Y2      = [X(:), Y(:)];
            obj.POS = [Y1; Y2];
            % Generate points in Pareto front (PF): line f1 + f2 = 8, f1 in [0,8]
            R(:,1) = linspace(0, 8, N)';
            R(:,2) = 8 - R(:,1);
        end
        %% Generate the image of Pareto front
        function R = GetPF(~)
            R(:,1) = linspace(0, 8, 100)';
            R(:,2) = 8 - R(:,1);
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
            ax = Draw([], {'\it x\rm_1', '\it x\rm_2', []});
            axis(ax, 'equal');
            hold(ax, 'on');

            rect1 = polyshape([-6, -2, -2, -6], [-2, -2, -6, -6]);
            rect2 = polyshape([ 2,  6,  6,  2], [ 6,  6,  2,  2]);

            h1 = plot(ax, rect1);
            h1.FaceColor = 'none';
            h1.LineWidth = 2;
            scatter(ax, [-6, -2], [-2, -6], 65, 'filled', 'LineWidth', 2, ...
                        'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'black');

            h2 = plot(ax, rect2);
            h2.FaceColor = 'none';
            h2.LineWidth = 2;
            scatter(ax, [2, 6], [6, 2], 65, 'filled', 'LineWidth', 2, ...
                        'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'black');

            Draw(Population.decs);
            xlim(ax, [obj.lower(1), obj.upper(1)]);
            ylim(ax, [obj.lower(2), obj.upper(2)]);
        end
    end
end