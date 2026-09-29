function [FrontNo,MaxFNo] = NDSort(varargin)
% NDSort - 快速非支配排序（忠实移植自 PlatEMO NDSort.m，参考 Zhang et al. 2015）
%
%   [FrontNo,MaxFNo] = NDSort(PopObj, cons, nSort)  带约束
%   [FrontNo,MaxFNo] = NDSort(PopObj, nSort)         无约束（兼容官方 2 参调用）
%   PopObj: [N x M] 目标值矩阵（最小化）
%   cons  : [N x C] 约束违反度矩阵（可行=0）
%   nSort : 至少需要排序的个体数量
%   返回：FrontNo - 每个个体所属前沿编号（1,2,...），未排序的赋 inf
%         MaxFNo - 最大前沿编号
%
% 官方 GetOptimum（MW7/9/10/11/13/14）调 NDSort(R,1)（2 参，无约束），
% 本地 EDD/SOTA 调 NDSort(objs,cons,nSort)（3 参）。本实现两种都接受。

    PopObj = varargin{1};
    if nargin == 3
        cons  = varargin{2};
        nSort = varargin{3};
    else
        % 2 参调用（官方 GetOptimum 风格）：无约束
        cons  = [];
        nSort = varargin{2};
    end
    [Ntot, M] = size(PopObj);
    % 处理约束：不可行解的惩罚
    if ~isempty(cons) && size(cons,2) > 0
        Infeasible = any(cons > 0, 2);
        PopObj(Infeasible,:) = repmat(max(PopObj,[],1), sum(Infeasible),1) + ...
                              repmat(sum(max(0,cons(Infeasible,:)),2), 1, M);
    end

    [FrontNo,MaxFNo] = ENS_SS(PopObj, nSort);
end

function [FrontNo,MaxFNo] = ENS_SS(PopObj, nSort)
    % 高效非支配排序 ENS-SS（Zhang et al. 2015），顺序搜索实现
    [PopObj,~,Loc] = unique(PopObj,'rows');
    Table   = hist(Loc,1:max(Loc));
    [N,M]   = size(PopObj);
    FrontNo = inf(1,N);
    MaxFNo  = 0;
    while sum(Table(FrontNo<inf)) < min(nSort, length(Loc))
        MaxFNo = MaxFNo + 1;
        for i = 1 : N
            if FrontNo(i) == inf
                Dominated = false;
                for j = i-1 : -1 : 1
                    if FrontNo(j) == MaxFNo
                        m = 2;
                        while m <= M && PopObj(i,m) >= PopObj(j,m)
                            m = m + 1;
                        end
                        Dominated = m > M;
                        if Dominated || M == 2
                            break;
                        end
                    end
                end
                if ~Dominated
                    FrontNo(i) = MaxFNo;
                end
            end
        end
    end
    FrontNo = FrontNo(:,Loc);
end
