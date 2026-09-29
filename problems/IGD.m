function value = IGD(A, PF)
% IGD - Inverted Generational Distance（PlatEMO 官方 IGD.m 向量化实现）
%
%   A:  算法获得的解集 [n x M]（目标值矩阵）
%   PF: 真实 Pareto 前沿 [m x M]
%   IGD = (1/|PF|) * sum( min_{a in A} ||a - p|| )
%
% PlatEMO 官方公式（BIMK/PlatEMO master，Metrics/IGD.m）：
%   score = mean(min(pdist2(optimum, PopObj), [], 2));
%   其中 optimum 对应本函数的 PF，PopObj 对应 A
%
% 参考：C. A. Coello Coello, N. C. Cortes. Solving multiobjective
%       optimization problems using an artificial immune system.
%       Genetic Programming and Evolvable Machines, 2005, 6(2): 163-190.

    m = size(PF, 1);
    if size(A, 2) ~= size(PF, 2)
        value = nan;
        return;
    end
    % 忠实 PlatEMO 官方向量化：pdist2(PF, A) → [m x n]，逐行取 min，再求 mean
    value = mean(min(pdist2(PF, A), [], 2));
end
