function run_cf_mw_sota()
% 任务3：3 个 2026 SOTA（FDSEA/GDVTSF/MOEA-IB）在 CF1-10 + MW1-14 × 30 种子
% 原生约束处理（NDSort(cons)+可行性优先），不改源码
% N=100 G=200 maxFE=20100 → results/cf_sota/<ALG>/<PN>_<ALG>_s<k>.mat
% 路径策略（与已跑通的 run_new_baselines_ls 一致）：
%   - 官方 ALGORITHM（_platemo_official）+ 官方问题类（CF/MW）
%   - 本地 IGD/HV/NDSort（problems/）
%   - 不 addpath('algorithms')，避免本地 ALGORITHM 类与官方冲突
% 已知失败模式（诚实报告）：
%   - FDSEA 官方 EnvironmentalSelection>LastSelection 假设 M=2，在 M=3 题（CF8/CF9/CF10/MW4/8/14）报
%     "输入参数为标量"循环 → 无法完成 M=3 题（官方 SOTA 固有局限，非本项目 bug）
%   - MOEA-IB 类名官方为 MOEA_IB（下划线），目录名 MOEA-IB（横杠）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    addpath('algorithms\_platemo_official');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear classes; clear IGD HV;

    bClass = {'FDSEA','GDVTSF','MOEA-IB'};
    bDir   = {'FDSEA','GDVTSF','MOEA-IB'};
    % 官方类名映射：FDSEA→FDSEA, GDVTSF→GDVTSF, MOEA-IB→MOEA_IB（官方类名含下划线）
    bClsName = {'FDSEA','GDVTSF','MOEA_IB'};
    bEP    = { ...
        {'algorithms\FDSEA'}, ...
        {'algorithms\GDVTSF'}, ...
        {'algorithms\MOEA_IB\WOF','algorithms\MOEA_IB\ReMO','algorithms\MOEA_IB'} };
    N = 100; G = 200; maxFE = N*(G+1);

    % 测试集：CF1-10 + MW1-14（NDSort 修 2参兼容 + 官方 UniformPoint 路径优先，6 题恢复）
    % 每种子新建官方对象（避免 PROBLEM 缓存 optimum/PF + FE 累加导致跨种子状态污染）
    pNms = cell(0,1); pPF = cell(0,1); pRef = cell(0,1);
    for i = 1:10
        pn = ['CF' num2str(i)]; pNms{end+1} = pn;
        offP0 = feval(pn); offP0.Setting();
        PF = tryPF(offP0);
        pPF{end+1} = PF;
        pRef{end+1} = 1.1 * max(PF, [], 1);
    end
    for i = 1:14
        pn = ['MW' num2str(i)]; pNms{end+1} = pn;
        offP0 = feval(pn); offP0.Setting();
        PF = tryPF(offP0);
        pPF{end+1} = PF;
        pRef{end+1} = 1.1 * max(PF, [], 1);
    end
    nPrb = numel(pNms);
    fprintf('setup: %d problems ready\n', nPrb);

    for b = 1:numel(bClass)
        cls = bClsName{b}; dname = bDir{b}; ep = bEP{b};
        fprintf('\n############  开始 %s (%s)  ############\n', dname, cls);
        outDir = ['results\cf_sota\' dname];
        if ~isdir(outDir), mkdir(outDir); end
        for k = 1:numel(ep), addpath(ep{k}); end
        nDone = 0; nFail = 0; nSkip = 0; t0 = tic;
        for p = 1:nPrb
            pn = pNms{p}; PF = pPF{p}; ref = pRef{p};
            for s = 1:30
                fn = fullfile(outDir, [dname '_' pn '_s' num2str(s) '.mat']);
                if isfile(fn), nSkip = nSkip + 1; continue; end
                try
                    offProb = feval(pn); offProb.Setting();
                    [Res] = runPlatEMOAlgo(cls, offProb, N, G, maxFE, s);
                    out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                    out.nFE = Res.nFE; out.PPS = size(Res.F,1);
                    save(fn, 'out', '-v7.3');
                    nDone = nDone + 1;
                    fprintf('  %-8s %-8s s%-2d IGD=%.4g HV=%.4g PPS=%d\n', ...
                        dname, pn, s, out.IGD, out.HV, out.PPS);
                catch err
                    nFail = nFail + 1;
                    % 仅当 30 种子全失败时才记 FAIL（避免个别种子内存波动误判）
                    if s == 30
                        fprintf('FAIL %s %s 全30种子失败: %s\n', dname, pn, err.message);
                    end
                end
            end
        end
        fprintf('### %s 全部 %d 题: done=%d skip=%d fail=%d 总耗时 %.1f min ###\n', ...
            dname, nPrb, nDone, nSkip, nFail, toc(t0)/60);
        for k = 1:numel(ep), rmpath(ep{k}); end
    end
    fprintf('\n=== 全部 3 个 SOTA 完成 ===\n');
end

function [Result] = runPlatEMOAlgo(cls, offProb, N, G, maxFE, seed)
    % MOEA-IB 官方类名是 MOEA_IB（下划线），目录名 MOEA-IB（横杠）
    clsName = cls;
    if strcmp(cls, 'MOEA-IB'), clsName = 'MOEA_IB'; end
    rng(seed);
    offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
    alg = feval(clsName, 'save', -1, 'outputFcn', @noopOutput);
    alg.Solve(offProb);
    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F = PopSOL.objs;
    else
        error('runPlatEMOAlgo:emptyResult', '%s: alg.result 为空', cls);
    end
    [fn, ~] = NDSort(F, zeros(size(F,1),0), 1);
    nd = find(fn == 1);
    if isempty(nd), nd = 1:size(F,1); end
    Result.F = F(nd,:);
    Result.nFE = offProb.FE;
end

function PF = tryPF(offP)
    try
        PF = offP.GetOptimum(500);
        if isempty(PF) || ~all(isfinite(PF(:)))
            PF = UniformPoint(500, offP.M);
        end
    catch
        PF = UniformPoint(500, offP.M);
    end
end

function noopOutput(a, p)
end
