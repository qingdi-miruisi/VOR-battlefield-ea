function run_new_baselines_ls()
% run_new_baselines_ls — 批量运行 4 个 PlatEMO 官方新 baseline
%   FDSEA   (PlatEMO 4.16, SWEVO 2026)
%   GDVTSF  (PlatEMO 4.15, SWEVO 2025)
%   MOEA-IB (PlatEMO 4.15, IEEE TEVC 2026)
%   LDS-AF  (PlatEMO 4.8,  Evolutionary Computation 2025)
%
% 测试集：LSMOP1-9（OfficialProblem 包装，公式原样） + DTLZ2 D=300 M=3（官方 PlatEMO 类）
% 公平协议：N=100, G=200, maxFE=N*(G+1)=20100, seeds=1:30
% 输出：results/largescale_extended/<algDirName>/<dirName>_<prob>_s<seed>.mat
%
% 路径策略：
%   - 官方 ALGORITHM 基类放 algorithms/_platemo_official/（与本地 ALGORITHM 隔离）
%   - IGD/HV 用 problems/IGD.m + problems/HV.m（与旧实验一致）
%   - 不 addpath('algorithms')，避免本地 ALGORITHM 类与官方冲突
%   - 构造时传 save=-1 + outputFcn=noopOutput（SetAccess=protected，必须构造时传）
%     save=-1：官方 NotTerminated 里 num=max(1,abs(save))=1，result 只写 1 行
%     outputFcn=noop：抑制 DefaultOutput 的 clc/fprintf/figure/Draw GUI 调用
%     NotTerminated 里的 drawnow('limitrate') 在无 figure 的 headless 会话下是 no-op，不报错
%   - DTLZ2_300D_M3 用官方 PlatEMO DTLZ2 类（公式与本地 DTLZ2_300D_M3 完全一致：
%     g=sum((x_3:end-1)^2)，PF=单位球第一卦限），保证官方算法能跑通且与旧 EDD 数据同口径
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    N     = 100;
    G     = 200;
    maxFE = N*(G+1);

    % 4 个新 baseline（类名、输出目录名、算法专属 addpath 列表）
    bClass = {'FDSEA','GDVTSF','MOEAIB','LDSAF'};
    bDir   = {'FDSEA','GDVTSF','MOEA-IB','LDS-AF'};
    bEP    = { ...
        {'algorithms\FDSEA'}, ...
        {'algorithms\GDVTSF'}, ...
        {'algorithms\MOEA_IB\WOF','algorithms\MOEA_IB\ReMO','algorithms\MOEA_IB'}, ...
        {'algorithms\LDSAF'} };

    % ---- 基础路径：官方 ALGORITHM 类 + 官方问题 + 本项目 IGD/HV/OfficialProblem
    setupPaths();

    % 测试集（在 setupPaths 后构建，避免 OfficialProblem 类未加载）
    pNms = cell(0); pObjs = cell(0);
    pOff = cell(0);    % 官方 PROBLEM 对象（供官方算法直接跑）
    pPF  = cell(0);    % 参考前沿（本项目口径，与旧 EDD 数据一致）
    pRef = cell(0);    % HV 参考点
    for i = 1:9
        pn = ['LSMOP' num2str(i)];
        pNms{end+1}  = pn;
        wrap = OfficialProblem(pn, 3, 300);
        pObjs{end+1} = wrap;
        pOff{end+1}  = wrap.officialObj;   % 官方对象（公式原样）
        PF   = wrap.ParetoFront(500);      % 官方 GetOptimum 原样
        pPF{end+1}   = PF;
        pRef{end+1}  = wrap.setRefPoint(PF).refPoint;
    end
    % DTLZ2 D=300 M=3：官方 PlatEMO 类（本地 DTLZ2_300D_M3 的公式等价版：
    %   g=sum((x_3:end-1-0.5)^2)，PF=单位球第一卦限，范围 [0,1]^300）
    %   注意：官方 GetOptimum(500) 在 M=3 时实际返回 91 点，
    %   与本地 DTLZ2_300D_M3.ParetoFront(500)=500 点不同；所有新 baseline 用同一 91 点 PF，
    %   IGD 口径内部一致；Friedman 合并时 DTLZ2_300D_M3 需统一 PF（见阶段2说明）
    pNms{end+1}  = 'DTLZ2_300D_M3';
    dOff = DTLZ2_300();
    pObjs{end+1} = dOff;
    pOff{end+1}  = dOff;
    dPF = dOff.GetOptimum(500);
    pPF{end+1}   = dPF;
    pRef{end+1}  = 1.1 * max(dPF, [], 1);  % 与 Problem.setRefPoint 同口径
    nPrb = numel(pNms);
    fprintf('setup: %d problems ready\n', nPrb);

    for b = 1:numel(bClass)
        cls   = bClass{b};
        dname = bDir{b};
        ep    = bEP{b};
        fprintf('\n############  开始 %s (%s)  ############\n', dname, cls);

        outDir = ['results\largescale_extended\' dname];
        if ~isdir(outDir), mkdir(outDir); end

        % 追加该算法目录
        for k = 1:numel(ep)
            addpath(ep{k});
        end

        nDone = 0; nFail = 0; nSkip = 0; t0 = tic;

        for p = 1:nPrb
            pn   = pNms{p};
            offProb = pOff{p};
            PF   = pPF{p};
            ref  = pRef{p};
            curIgd = 0;

            for s = 1:30
                fn = fullfile(outDir, [dname '_' pn '_s' num2str(s) '.mat']);
                if isfile(fn), nSkip = nSkip + 1; continue; end
                try
                    [Res] = runPlatEMOAlgo(cls, offProb, N, G, maxFE, s);
                    out.IGD  = IGD(Res.F, PF);
                    out.HV   = HV(Res.F, ref);
                    out.nFE  = Res.nFE;
                    out.elap = Res.elap;
                    out.PPS  = size(Res.F, 1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1; curIgd = 0;
                    fprintf('  %-8s %-18s s%-2d  IGD=%.4g  HV=%.4g  PPS=%d\n', ...
                        dname, pn, s, out.IGD, out.HV, out.PPS);
                catch err
                    nFail = nFail + 1; curIgd = curIgd + 1;
                    fprintf('FAIL %s %s s%d: %s\n', dname, pn, s, err.message);
                    if curIgd > 3, error(sprintf('%s 连续失败 %d 次，中止', dname, curIgd)); end
                end
            end
            fprintf('=== %s %s: done=%d skip=%d fail=%d  累计耗时=%.0fs ===\n', ...
                dname, pn, nDone, nSkip, nFail, toc(t0));
        end
        fprintf('### %s 全部 10 题: done=%d skip=%d fail=%d  总耗时 %.1f min ###\n', ...
            dname, nDone, nSkip, nFail, toc(t0)/60);

        % 清理该算法专属路径
        for k = 1:numel(ep)
            rmpath(ep{k});
        end
    end

    fprintf('\n=== 全部 4 个新 baseline 完成 ===\n');
end

% ----------------------------------------------------------------
function [Result] = runPlatEMOAlgo(cls, offProb, N, G, maxFE, seed)
% 官方 PlatEMO 算法包装器（offProb 为官方 PROBLEM 对象，已 Setting()）
    rng(seed);

    offProb.N      = N;
    offProb.maxFE  = maxFE;
    offProb.FE     = 0;

    % save=-1 + noopOutput：构造时传入（SetAccess=protected，构造后不能赋值）
    alg = feval(cls, 'save', -1, 'outputFcn', @noopOutput);
    alg.Solve(offProb);

    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F      = PopSOL.objs;
        decs   = PopSOL.decs;
        cons   = PopSOL.cons;
    else
        error('runPlatEMOAlgo:emptyResult', '%s: alg.result 为空', cls);
    end

    [fn, ~] = NDSort(F, zeros(size(F,1), 0), 1);
    nd = find(fn == 1);
    if isempty(nd), nd = 1:size(F,1); end

    Result.F    = F(nd, :);
    Result.nFE  = offProb.FE;
    Result.elap = alg.metric.runtime;
end

function noopOutput(a, p)
    % no-op：抑制 PlatEMO DefaultOutput 的 GUI/Draw/clc 调用
end

% ----------------------------------------------------------------
function setupPaths()
    addpath('algorithms\_platemo_official');   % 官方 ALGORITHM + utilities
    addpath('problems_official');              % PROBLEM/SOLUTION/NDSort
    addpath('problems_official\LSMOP');
    addpath('problems_official\EMO');
    addpath('problems_official\UF');
    addpath('problems_official\CF');
    addpath('problems_official\DTLZ');         % 官方 DTLZ2（D=300 M=3 交叉验证题）
    addpath('problems');                       % IGD/HV/OfficialProblem/Problem
    addpath('problems\wfg_toolbox');
    addpath('problems_ext');
end
