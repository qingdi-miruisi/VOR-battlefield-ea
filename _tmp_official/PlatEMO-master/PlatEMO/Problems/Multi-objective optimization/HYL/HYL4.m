classdef HYL4 < PROBLEM
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
        Points     = cell(2, 4);          % Points{i,j} = j-th vertex of i-th polygon
        numPolygon = 4;
        Centers    = {[-7, 7]; [7, 7]; [7, -7]; [-7, -7]};
        radius     = 2;
        PFs        = [];                  % Cached PF samples
        POS;                              % Pareto Set samples (used by IGDX)
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            % Build the four squares
            d           = sqrt(2)/2;
            Rectangular = {[-d, d]; [d, d]; [d, -d]; [-d, -d]};
            for i = 1 : obj.numPolygon
                for j = 1 : size(Rectangular, 1)
                    obj.Points{i,j} = obj.Centers{i} + Rectangular{j} * obj.radius;
                end
            end

            obj.M        = 4;
            obj.D        = 3;
            obj.lower    = [-10, -10, -10];
            obj.upper    = [ 10,  10,  10];
            obj.encoding = ones(1, obj.D);

            % Cache PF samples (used as the reference set)
            xy = zeros(2, obj.M);
            for j = 1 : obj.M
                xy(:,j) = obj.Points{1,j};
            end
            center = obj.Centers{1};
            [X, Y] = ndgrid( ...
                linspace(center(1) - obj.radius, center(1) + obj.radius, 50), ...
                linspace(center(2) - obj.radius, center(2) + obj.radius, 50));
            ND       = inpolygon(X(:), Y(:), xy(1,:), xy(2,:));
            Dec      = [X(ND), Y(ND)];
            Dec(:,3) = 0;
            obj.PFs  = obj.CalObj(Dec);
        end
        %% Calculate objective values
        function PopObj = CalObj(obj, X)
            X      = X(:, 1:2);
            PopObj = Inf(size(X,1), obj.M);
            for m = 1 : obj.M
                for i = 1 : obj.numPolygon
                    D = pdist2(obj.Points{i,m}, X)';
                    PopObj(:,m) = min(D, PopObj(:,m));
                end
            end
        end
        %% Generate Pareto optimal solutions
        function R = GetOptimum(obj, ~)
            % Generate points in Pareto optimal set (PS): four square poles
            Y = [];
            for i = 1 : obj.numPolygon
                xy = zeros(2, obj.M);
                for j = 1 : obj.M
                    xy(:,j) = obj.Points{i,j};
                end
                center = obj.Centers{i};
                [X, Yg, Zg] = ndgrid( ...
                    linspace(center(1) - obj.radius, center(1) + obj.radius, 20), ...
                    linspace(center(2) - obj.radius, center(2) + obj.radius, 20), ...
                    linspace(obj.lower(3), obj.upper(3), 50));
                ND = inpolygon(X(:), Yg(:), xy(1,:), xy(2,:));
                Y  = [Y; [X(ND), Yg(ND), Zg(ND)]];
            end
            obj.POS = Y;
            % Generate points in Pareto front (PF)
            R = obj.PFs;
        end
        %% Generate the image of Pareto front
        function R = GetPF(obj)
            R = obj.PFs;
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
            X  = Population.decs;
            ax = Draw(X, {'\it x\rm_1', '\it x\rm_2', '\it x\rm_3'});
            axis(ax, 'equal');
            axis(ax, 'vis3d');
            xlim(ax, [obj.lower(1), obj.upper(1)]);
            ylim(ax, [obj.lower(2), obj.upper(2)]);
            view(ax, [116.915566954724, 16.2817315254442]);

            % Top and bottom square outlines
            for i = 1 : obj.numPolygon
                xy = zeros(2, obj.M);
                for j = 1 : obj.M
                    xy(:,j) = obj.Points{i,j};
                end
                poly = polyshape(xy(1,:), xy(2,:));
                for pos = [obj.lower(3), obj.upper(3)]
                    vertices3D      = poly.Vertices;
                    vertices3D(:,3) = pos;
                    face3D          = 1 : size(vertices3D, 1);
                    h = patch(ax, 'Vertices', vertices3D, 'Faces', face3D, ...
                                  'FaceColor', 'none', 'LineWidth', 1);
                    h.FaceVertexAlphaData = 0;
                    h.FaceAlpha           = 'flat';
                end
            end

            % Vertical edges of each pole
            for i = 1 : obj.numPolygon
                for j = 1 : obj.M
                    x = obj.Points{i,j}(1);
                    y = obj.Points{i,j}(2);
                    plot3(ax, [x, x], [y, y], [obj.lower(3), obj.upper(3)], ...
                          '-black', 'LineWidth', 1);
                end
            end
        end
    end
end