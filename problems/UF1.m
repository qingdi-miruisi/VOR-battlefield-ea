classdef UF1 < OfficialProblem
% UF1 - PlatEMO official formula (bridged via OfficialProblem)
% Core CalObj/GetOptimum/local functions copied VERBATIM from official source;
% official CalObj/GetOptimum/GetPF renamed to ...Direct to avoid bridge-layer collision.

    methods
        function obj = UF1()
            obj@OfficialProblem('UF1');
        end
        function Setting(obj)
        obj.M = 2;
        if isempty(obj.D); obj.D = 30; end
        obj.lower    = [0,zeros(1,obj.D-1)-1];
        obj.upper    = ones(1,obj.D);
        obj.encoding = ones(1,obj.D);
        end
        function PopObj = CalObj(obj,X)
        J1 = 3 : 2 : obj.D;
        J2 = 2 : 2 : obj.D;
        Y  = X - sin(6*pi*repmat(X(:,1),1,obj.D)+repmat(1:obj.D,size(X,1),1)*pi/obj.D);
        PopObj(:,1) = X(:,1)         + 2*mean(Y(:,J1).^2,2);
        PopObj(:,2) = 1-sqrt(X(:,1)) + 2*mean(Y(:,J2).^2,2);
        end
        function R = GetOptimum(obj,N)
        R(:,1) = linspace(0,1,N)';
        R(:,2) = 1 - R(:,1).^0.5;
        end
        function R = GetPF(obj)
        R = obj.GetOptimum(100);
        end
        end
        end
    end
end