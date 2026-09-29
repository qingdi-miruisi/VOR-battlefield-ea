classdef DTLZ2_300D_M3 < Problem
    % DTLZ2 M=3 D=300 - 大规模交叉验证基准（DTLZ2 官方公式，D 放大至 300）
    % 官方 DTLZ2 公式（PlatEMO / Deb 2002）：
    %   g(x_D) = sum_{i=M}^{D-1} (x_i - 0.5)^2
    %   f_1 = (1+g) * cos(x_1*pi/2) * cos(x_2*pi/2)
    %   f_2 = (1+g) * cos(x_1*pi/2) * sin(x_2*pi/2)
    %   f_3 = (1+g) * sin(x_1*pi/2)
    % PF: 单位球第一卦限（orthant），D 不影响 PF 形状
    % 决策范围 [0,1]^300

    methods
        function obj = DTLZ2_300D_M3()
            D = 300; M = 3;
            obj@Problem('DTLZ2_300D_M3', D, M);
            obj.lower = zeros(1, D);
            obj.upper = ones(1, D);
        end

        function F = CalObj(obj, X)
            M = 3;
            g = sum((X(:, M:end) - 0.5).^2, 2);   % N x 1 column
            F = zeros(size(X,1), M);
            F(:,1) = (1+g) .* (cos(X(:,1)*pi/2) .* cos(X(:,2)*pi/2));
            F(:,2) = (1+g) .* (cos(X(:,1)*pi/2) .* sin(X(:,2)*pi/2));
            F(:,3) = (1+g) .* sin(X(:,1)*pi/2);
        end

        function PF = ParetoFront(obj, nPoints)
            if nargin < 2, nPoints = 500; end
            M = 3;
            U = UniformPoint(nPoints, M);
            PF = U ./ sqrt(sum(U.^2, 2));
        end

        function cons = CalCon(obj, X)
            cons = zeros(size(X,1), 0);
        end

        function Pop = Initialization(obj, N)
            if nargin < 2, N = 100; end
            Pop.decs = rand(N, obj.D);
            Pop.objs = obj.CalObj(Pop.decs);
            Pop.cons = obj.CalCon(Pop.decs);
        end
    end
end
