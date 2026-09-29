classdef ALGORITHM < handle
% ALGORITHM - 多目标进化算法统一基类（可复现版）
% 统一接口：
%   obj = AlgorithmName(popSize, maxGen, seed);
%   [Population, Result] = obj.optimize(Problem);
%
%   Population : struct, 字段 decs [NxD] / objs [NxM] / cons [NxC]
%   Result     : struct, 字段 F（最终非支配前沿目标值 [KxM]）,
%                nFE（实际函数评估次数）, elap（墙钟秒数）
%
% 公平性约定：所有算法使用相同 popSize / maxGen / seed 集合，
% 每代评估 popSize 个新解，总评估次数 ≈ N*(maxGen+1)。
% 路径约定：本基类不写任何绝对路径；实验脚本通过
%   projectRoot = fileparts(mfilename('fullpath')) 解析相对路径。

    properties
        popSize double = 100;
        maxGen  double = 200;
        seed    double = 42;
    end

    methods
        function obj = ALGORITHM(popSize, maxGen, seed)
            if nargin >= 1, obj.popSize = popSize; end
            if nargin >= 2, obj.maxGen  = maxGen;  end
            if nargin >= 3, obj.seed    = seed;    end
        end

        function [Population, Result] = optimize(obj, Problem)
            % 统一调用入口：计时 + 固定种子 + 委托 run
            rng(obj.seed);
            t0 = tic;
            [Population, Result] = obj.run(Problem);
            Result.elap = toc(t0);
            if ~isstruct(Result) || ~isfield(Result, 'nFE')
                Result.nFE = obj.popSize * (obj.maxGen + 1);
            end
        end

        function [Population, Result] = run(obj, Problem)
            error('ALGORITHM:notImplemented', '子类必须实现 run(Problem)');
        end
    end
end
