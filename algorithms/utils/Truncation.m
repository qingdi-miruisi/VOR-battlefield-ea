function Del = Truncation(PopObj,K)
% Truncation - SPEA2 密度截断（忠实移植自 PlatEMO SPEA2/EnvironmentalSelection.m）
% 删除 K 个最拥挤的个体
    Distance = pdist2(PopObj,PopObj);
    Distance(logical(eye(length(Distance)))) = inf;
    Del = false(1,size(PopObj,1));
    while sum(Del) < K
        Remain   = find(~Del);
        Temp     = sort(Distance(Remain,Remain),2);
        [~,Rank] = sortrows(Temp);
        Del(Remain(Rank(1))) = true;
    end
end
