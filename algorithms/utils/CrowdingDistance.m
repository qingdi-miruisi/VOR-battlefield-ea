function CrowdDis = CrowdingDistance(PopObj,FrontNo)
% CrowdingDistance - 计算每个前沿内个体的拥挤距离（忠实移植自 PlatEMO）
% 参考 Kukkonen & Deb 2006
%
%   CrowdDis = CrowdingDistance(PopObj,FrontNo)
%   PopObj:  [N x M] 目标值矩阵
%   FrontNo: [N]     前沿编号

    [N,M] = size(PopObj);
    if nargin < 2
        FrontNo = ones(1,N);
    end
    CrowdDis = zeros(1,N);
    Fronts   = setdiff(unique(FrontNo),inf);
    for f = 1 : length(Fronts)
        Front = find(FrontNo==Fronts(f));
        Fmax  = max(PopObj(Front,:),[],1);
        Fmin  = min(PopObj(Front,:),[],1);
        for i = 1 : M
            [~,Rank] = sortrows(PopObj(Front,i));
            CrowdDis(Front(Rank(1)))   = inf;
            CrowdDis(Front(Rank(end))) = inf;
            for j = 2 : length(Front)-1
                CrowdDis(Front(Rank(j))) = CrowdDis(Front(Rank(j)))+...
                    (PopObj(Front(Rank(j+1)),i)-PopObj(Front(Rank(j-1)),i))/(Fmax(i)-Fmin(i));
            end
        end
    end
end
