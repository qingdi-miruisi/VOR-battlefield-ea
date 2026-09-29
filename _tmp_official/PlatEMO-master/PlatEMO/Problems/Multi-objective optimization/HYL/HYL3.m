classdef HYL3 < PROBLEM
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
        Points     = cell(2, 3);          % Points{i,j} = j-th vertex of i-th polygon
        numPolygon = 2;
        Centers    = {[-6, 6]; [6, -6]};
        radius     = 2;
        PFs        = [];                  
        POS;                   
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            obj.M        = 3;
            obj.D        = 3;
            obj.lower    = [-10, -10, -10];
            obj.upper    = [ 10,  10,  10];
            obj.encoding = ones(1, obj.D);
            
            % Build the two triangles
            Triangle = {[0, 1]; [sqrt(3)/2, -1/2]; [-sqrt(3)/2, -1/2]}; % Vertex positions when center = [0, 0] and radius = 1
            for i = 1 : size(obj.Centers, 1)
                for j = 1 : size(Triangle, 1)
                    obj.Points{i,j} = obj.Centers{i} + Triangle{j} * obj.radius;
                end
            end

            % Get PF
            xy = zeros(2, obj.M);
            for j = 1 : obj.M
                xy(:,j) = obj.Points{1,j};
            end
            center = obj.Centers{1};
            [X, Y] = ndgrid( ...
                linspace(center(1) - (2/sqrt(3))*obj.radius, center(1) + (2/sqrt(3))*obj.radius, 100), ...
                linspace(center(2) -            obj.radius, center(2) +            obj.radius, 100));
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
            % Generate points in Pareto optimal set (PS): two triangle poles
            Y = [];
            for i = 1 : obj.numPolygon
                xy = zeros(2, obj.M);
                for j = 1 : obj.M
                    xy(:,j) = obj.Points{i,j};
                end
                center = obj.Centers{i};
                [X, Yg, Zg] = ndgrid( ...
                    linspace(center(1) - (2/sqrt(3))*obj.radius, center(1) + (2/sqrt(3))*obj.radius, 100), ...
                    linspace(center(2) -            obj.radius, center(2) +            obj.radius, 100), ...
                    linspace(obj.lower(3), obj.upper(3), 100));
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
        %% Display a population in the objective space
        function DrawObj(obj, Population)
            ax = Draw([]);
            xv = linspace(min(obj.PFs(:,1)), max(obj.PFs(:,1)), 100);
            yv = linspace(min(obj.PFs(:,2)), max(obj.PFs(:,2)), 100);
            [X, Y] = meshgrid(xv, yv);
            Z = griddata(obj.PFs(:,1), obj.PFs(:,2), obj.PFs(:,3), X, Y);
            surf(ax, X, Y, Z, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.8 0.8 0.8], ...
                              'FaceAlpha', 0.5, 'EdgeAlpha', 0.5);
            Draw(Population.objs, {'\it f\rm_1', '\it f\rm_2', '\it f\rm_3'});
        end
        %% Display a population in the decision space
        function DrawDec(obj, Population)
            X  = Population.decs;
            ax = Draw(X, {'\it x\rm_1', '\it x\rm_2', '\it x\rm_3'});
            axis(ax, 'equal');
            axis(ax, 'vis3d');
            xlim(ax, [obj.lower(1), obj.upper(1)]);
            ylim(ax, [obj.lower(2), obj.upper(2)]);

            % Top and bottom triangle outlines
            for i = 1 : obj.numPolygon
                xy = zeros(2, obj.M);
                for j = 1 : obj.M
                    xy(:,j) = obj.Points{i,j};
                end
                poly = polyshape(xy(1,:), xy(2,:));
                for pos = [obj.lower(3), obj.upper(3)]
                    vertices3D       = poly.Vertices;
                    vertices3D(:,3)  = pos;
                    face3D           = 1 : size(vertices3D, 1);
                    h = patch(ax, 'Vertices', vertices3D, 'Faces', face3D, ...
                                  'FaceColor', 'none', 'LineWidth', 1.5);
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
                          '-black', 'LineWidth', 1.5);
                end
            end

            axis(ax, 'auto');
        end
    end
end