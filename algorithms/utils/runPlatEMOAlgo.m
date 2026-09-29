function [Population, Result] = runPlatEMOAlgo(algName, problem, N, G, maxFE, seed)
% runPlatEMOAlgo — 通用 PlatEMO 官方算法包装器
% 把 PlatEMO 官方 classdef ALGORITHM 接口适配到本项目 struct 结果格式
%
% 调用：[Pop, Res] = runPlatEMOAlgo('FDSEA', OfficialProblemObj, N, G, maxFE, seed)
% 返回：
%   Pop.decs/objs/cons : 非支配前沿（struct）
%   Res.F / Res.nFE / Res.elap
%
% 注意：PlatEMO 官方 ALGORITHM 类使用 result{end,2} 保存 SOLUTION 对象数组；
%       若 result 为空则退回问题对象的当前种群。
    rng(seed);

    alg = feval(algName);

    % 取官方问题对象（OfficialProblem 包装器 → 官方 PROBLEM 对象）
    if isa(problem, 'OfficialProblem')
        offProb = problem.officialObj;
    else
        offProb = problem;
    end
    offProb.N      = N;
    offProb.maxFE  = maxFE;
    offProb.FE     = 0;

    % 官方 main(Algorithm, Problem) 签名；内部用 NotTerminated 终止
    alg.main(offProb);

    % 取最终种群（result 是 cell: {FE, Pop} 列表）
    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F      = PopSOL.objs;
        decs   = PopSOL.decs;
        cons   = PopSOL.cons;
    else
        F    = offProb.objs;
        decs = offProb.decs;
        cons = offProb.cons;
    end

    % 非支配前沿
    [fn, ~] = NDSort(F, zeros(size(F,1), 0), 1);
    nd = find(fn == 1);
    if isempty(nd), nd = 1:size(F,1); end

    Result.F    = F(nd, :);
    Result.nFE  = offProb.FE;
    Result.elap = alg.metric.runtime;

    Population.decs = decs(nd, :);
    Population.objs = F(nd, :);
    Population.cons = cons(nd, :);
end
