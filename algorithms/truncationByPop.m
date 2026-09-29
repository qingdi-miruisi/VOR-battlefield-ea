function Del = truncationByPop(PopObj, K)
% 删除 PopObj 中 K 个最拥挤个体（忠实 PlatEMO SPEA2 Truncation）
    Distance = pdist2(PopObj, PopObj);
    Distance(logical(eye(size(Distance, 1)))) = inf;
    Del = false(1, size(PopObj, 1));
    while sum(Del) < K
        Remain = find(~Del);
        Temp   = sort(Distance(Remain, Remain), 2);
        [~, Rank] = sortrows(Temp);
        Del(Remain(Rank(1))) = true;
    end
end
